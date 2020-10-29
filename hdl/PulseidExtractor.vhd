library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.LedStripTcsrWrapperPkg.all;

-- assumes addresses are presented in ascending order
entity PulseidExtractor is
  generic (
    PULSEID_OFFSET_G  : natural := 0;    -- byte-offset in data memory
    PULSEID_BIGEND_G  : boolean := true; -- endian-ness
    PULSEID_LENGTH_G  : natural := 8;    -- in bytes
    USE_ASYNC_OUTP_G  : boolean := true;
    PULSEID_WDOG_P_G  : natural := 0     -- watchdog for missing pulse IDs; disabled when 0
  );
  port (
    clk               : in  std_logic;
    rst               : in  std_logic;
    evrStream         : in  EvrStreamType;
    trg               : in  std_logic := '1'; -- register last pulseid to output
    oclk              : in  std_logic := '0';
    orst              : in  std_logic := '0';
    pulseid           : out std_logic_vector(8*PULSEID_LENGTH_G - 1 downto 0);
    pulseidStrobe     : out std_logic; -- asserted for 1 cycle when a new ID is registered on 'pulseid'
    wdgErrors         : out std_logic_vector(31 downto 0);
    synErrors         : out std_logic_vector(31 downto 0)
  );
end entity PulseidExtractor;

architecture rtl of PulseidExtractor is

  type DemuxType is array (natural range 0 to PULSEID_LENGTH_G - 2) of std_logic_vector(7 downto 0);

  type RegType is record
    demux        : DemuxType;
    updated      : std_logic;
    pulseidReg   : std_logic_vector(8*PULSEID_LENGTH_G     - 1 downto 0);
    pulseid      : std_logic_vector(8*PULSEID_LENGTH_G     - 1 downto 0);
    strobe       : std_logic;
    got          : std_logic_vector(PULSEID_LENGTH_G - 1 downto 0);
    synErrors    : unsigned(31 downto 0);
    wdgErrors    : unsigned(31 downto 0);
    wdgStrobe    : natural range 0 to PULSEID_WDOG_P_G;
    lastAddr     : std_logic_vector(evrStream.addr'range);
  end record RegType;

  constant REG_INIT_C : RegType := (
    demux        => (others => (others => '0')),
    updated      => '0',
    pulseidReg   => (others => '0'),
    pulseid      => (others => '0'),
    strobe       => '0',
    got          => (others => '0'),
    synErrors    => (others => '0'),
    wdgErrors    => (others => '0'),
    wdgStrobe    => PULSEID_WDOG_P_G,
    lastAddr     => (others => '1') -- pulse-id cannot overlap this address
  );

  constant   STAGES_C  : natural := 2;

  attribute  KEEP      : string;
  attribute  ASYNC_REG : string;

  signal pulseid_o     : std_logic_vector(8*PULSEID_LENGTH_G - 1 downto 0);
  signal strobe_o      : std_logic_vector(STAGES_C           - 1 downto 0) := (others => '0');

  attribute ASYNC_REG of strobe_o  : signal is "TRUE";
  attribute KEEP      of strobe_o  : signal is "TRUE";
  attribute KEEP      of pulseid_o : signal is "TRUE";

  signal r   : RegType := REG_INIT_C;
  signal rin : RegType;

  function SYNC_OK_F return std_logic_vector is
    variable v : std_logic_vector(PULSEID_LENGTH_G - 1 downto 0);
  begin
    v         := (others => '1');
    v(v'left) := '0';
    return v;
  end function SYNC_OK_F;

begin

  G_Async : if ( USE_ASYNC_OUTP_G ) generate
    P_SYNC : process ( oclk ) is
    begin
      if ( rising_edge( oclk ) ) then
        if ( orst = '1' ) then
          strobe_o <= (others => '0');
        else
          strobe_o <= strobe_o( strobe_o'left - 1 downto strobe_o'right) & r.strobe;
        end if;
      end if;
    end process P_SYNC;

    pulseIdStrobe <= strobe_o( strobe_o'left );
  end generate G_Async;

  G_Sync : if ( not USE_ASYNC_OUTP_G ) generate
    pulseIdStrobe <= r.strobe;
  end generate G_Sync;

  P_COMB : process( r, evrStream, trg ) is
    variable v        : RegType;
    variable offset   : signed(evrStream.addr'left + 1 downto evrStream.addr'right);
    constant END_OFF  : natural := PULSEID_LENGTH_G - 1;
    variable demuxVec : std_logic_vector( 8*v.demux'length - 1 downto 0 );
  begin

    v := r;

    v.strobe      := '0';

    -- watchdog
    if ( PULSEID_WDOG_P_G > 0 ) then
      if ( r.wdgStrobe = 0 ) then
        v.wdgStrobe := PULSEID_WDOG_P_G;
        v.wdgErrors := r.wdgErrors + 1;
      else
        v.wdgStrobe := r.wdgStrobe - 1;
      end if;
    end if;

	if ( evrStream.valid = '1' ) then
      v.lastAddr := evrStream.addr;
      if ( evrStream.addr /= r.lastAddr ) then
        offset := signed(resize(unsigned(evrStream.addr),offset'length)) - PULSEID_OFFSET_G;
        if ( offset >= 0 ) then
          if ( offset < END_OFF ) then
            if ( v.got( to_integer(offset) ) = '1' ) then
              v.got := (others => '0');
            else
              v.got( to_integer(offset) ) := '1';
            end if;

            if ( PULSEID_BIGEND_G ) then
              v.demux(v.demux'right - to_integer(offset)) := evrStream.data;
            else
              v.demux(to_integer(offset))                 := evrStream.data;
            end if;
          elsif ( offset = END_OFF ) then

            v.got := (others => '0');

            if ( r.got /= SYNC_OK_F ) then
              v.synErrors := r.synErrors + 1;
            else
              for i in v.demux'range loop
                demuxVec( 8*i + 7 downto 8* i) := r.demux(i);
              end loop;

              if ( PULSEID_BIGEND_G ) then
                v.pulseidReg := demuxVec & evrStream.data;
              else
                v.pulseidReg := evrStream.data & demuxVec;
              end if;

              v.updated   := '1';
              -- strobe the watchdog; a new pulse-ID was recorded
              v.wdgStrobe := PULSEID_WDOG_P_G;
            end if;

          end if; -- offset <= END_OFF
        end if; -- offset >= 0
      end if; -- evrStream.addr /= r.lastAddr
    end if; -- evrStream.valid = '1'

    if ( (trg and r.updated) = '1' ) then
      v.updated  := '0';
      v.strobe   := '1';
      v.pulseid  := r.pulseidReg;
    end if;

    rin <= v;
  end process P_COMB;

  P_SEQ : process ( clk ) is 
  begin
    if ( rising_edge( clk ) ) then
      if ( rst = '1' ) then
        r <= REG_INIT_C;
      else
        r <= rin;
      end if;
    end if;
  end process P_SEQ;

  pulseid_o <= r.pulseid;
  pulseid   <= pulseid_o;
  synErrors <= std_logic_vector(r.synErrors);
  wdgErrors <= std_logic_vector(r.wdgErrors);

end architecture rtl;
