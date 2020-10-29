library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

use     work.MpcI2cSequencerPkg.all;
use     work.LedStripTcsrWrapperPkg.all;

entity LedStripMmioWrapper is
  generic (
    BUS_FREQ_G   : natural                            := 100000000;
    UPDATE_MS_G  : positive                           := 10;
    ADDR_W_G     : positive                           := 6;
    NUM_LEDS_G   : positive range 1 to 32             := 30
  );
  port (
    clk          : in  std_logic;
    rstn         : in  std_logic;

    rs           : in  std_logic; 
    raddr        : in  std_logic_vector(ADDR_W_G - 1 downto 0);
    rdata        : out std_logic_vector(31 downto 0);
    rerr         : out std_logic := '0';
    rvalid       : out std_logic := '1';

    ws           : in  std_logic; 
    waddr        : in  std_logic_vector(ADDR_W_G - 1 downto 0);
    wdata        : in  std_logic_vector(31 downto 0);
    wstrb        : in  std_logic_vector( 3 downto 0);
    werr         : out std_logic := '0';
    wready       : out std_logic := '1';

    scl_t        : out std_logic;
    scl_o        : out std_logic := '0';
    scl_i        : in  std_logic;
    sda_t        : out std_logic;
    sda_o        : out std_logic := '0';
    sda_i        : in  std_logic
  );
end entity LedStripMmioWrapper;

architecture rtl of LedStripMmioWrapper is
  constant BUS_FREQ_C : real                          := real(BUS_FREQ_G); -- vivado packager doesn't support real
  constant PID_FREQ_C : real                          := 1000.0/real(UPDATE_MS_G);

  constant DIV_C      : natural                       := natural(BUS_FREQ_C/PID_FREQ_C) - 1;

  signal pulseid      : std_logic_vector(63 downto 0) := (others => '0');

  signal rst          : std_logic;

  signal div          : unsigned(31 downto 0)         := to_unsigned(DIV_C, 32);
  signal div_init     : unsigned(31 downto 0)         := to_unsigned(DIV_C, 32);

  signal tcsrADD      : std_logic_vector(ADDR_W_G - 1 downto 0);
  signal tcsrDATR     : std_logic_vector(31       downto 0);
  signal tcsrWR       : std_logic;
  signal tcsrRD       : std_logic;

  signal raddr_w      : unsigned(ADDR_W_G - 1 downto 2);
  signal waddr_w      : unsigned(ADDR_W_G - 1 downto 2);

  signal evrStream    : evrStreamType;

  signal streamPtr    : unsigned( 2 downto 0 ) := (others => '0');

  constant PULSEID_REG_IDX_C : natural := 15;
  constant DIVISOR_REG_IDX_C : natural := 14;

begin

  raddr_w   <= unsigned(raddr(raddr_w'range));
  waddr_w   <= unsigned(waddr(waddr_w'range));

  tcsrRD    <= rs and not raddr(ADDR_W_G - 1);
  tcsrWR    <= ws and not waddr(ADDR_W_G - 1);

  rdata     <= pulseid(31 downto 0)       when (raddr_w = PULSEID_REG_IDX_C) else
               std_logic_vector(div_init) when (raddr_w = DIVISOR_REG_IDX_C) else
               tcsrDATR;

  rst       <= (not rstn);
  tcsrADD   <= waddr when ws = '1' else raddr;

  evrStream.data <= pulseid(7*8 + 7 downto 7*8) when streamPtr = 7 else
                    pulseid(6*8 + 7 downto 6*8) when streamPtr = 6 else
                    pulseid(5*8 + 7 downto 5*8) when streamPtr = 5 else
                    pulseid(4*8 + 7 downto 4*8) when streamPtr = 4 else
                    pulseid(3*8 + 7 downto 3*8) when streamPtr = 3 else
                    pulseid(2*8 + 7 downto 2*8) when streamPtr = 2 else
                    pulseid(1*8 + 7 downto 1*8) when streamPtr = 1 else
                    pulseid(0*8 + 7 downto 0*8);

  P_STREAM_ADDR : process ( streamPtr ) is
    variable v : std_logic_vector( evrStream.addr'range );
  begin
    v := (others => '0');
    v( streamPtr'range ) := std_logic_vector(streamPtr);
    evrStream.addr <= v;
  end process P_STREAM_ADDR;

  P_SEQ  : process( clk ) is
  begin
    if ( rising_edge( clk ) ) then
      if ( rstn = '0' ) then
        div       <= div_init;
        streamPtr <= (others => '0');
      else
        if ( evrStream.valid = '1' ) then
          if ( streamPtr = pulseid'length/8 - 1 ) then
            evrStream.valid <= '0';
          end if;
          streamPtr <= streamPtr + 1;
        end if;
        if ( div = 0 ) then
          div             <= div_init;
          pulseid         <= std_logic_vector(unsigned(pulseid) + 1);
          streamPtr       <= (others => '0');
          evrStream.valid <= '1';
        else
          div <= div - 1;
        end if;
        if ( (ws = '1') ) then
          if    ( waddr_w = PULSEID_REG_IDX_C ) then
            if ( wstrb = x"f" ) then
              pulseid <= x"0000_0000" & wdata;
            end if;
          elsif ( waddr_w = DIVISOR_REG_IDX_C ) then
            if ( wstrb = x"f" ) then
              div_init <= unsigned(wdata) - 1;
            end if;
          end if;
        end if;
      end if;
    end if;
  end process P_SEQ;

  U_LED : entity work.LedStripTcsrWrapper
    generic map (
      TCSR_CLOCK_FRQ_G => BUS_FREQ_C,
      PULSEID_OFFSET_G => 0
    )
    port map (
      tcsrCLK          => clk,
      tcsrRST          => rst,

      tcsrADD          => tcsrADD(5 downto 2),
      tcsrDATW         => wdata,
      tcsrWE           => wstrb,
      tcsrDATR         => tcsrDATR,
      tcsrWR           => tcsrWR,
      tcsrRD           => tcsrRD,
      tcsrACK          => open,
      tcsrERR          => open,

      sdaOut           => sda_t,
      sclOut           => scl_t,
      sclInp           => scl_i,
      sdaInp           => sda_i,

      evrClk           => clk,
      evrStream        => evrStream
    );

end architecture rtl;

