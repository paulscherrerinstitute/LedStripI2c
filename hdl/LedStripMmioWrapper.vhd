library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

use     work.MpcI2cSequencerPkg.all;

entity LedStripMmioWrapper is
  generic (
    BUS_FREQ_G   : natural                            := 100000000;
    UPDATE_MS_G  : positive                           := 10;
    ADDR_W_G     : positive                           := 5;
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
  constant SCL_FREQ_C : real                          := 4.0E5;
  constant FDRVAL_C   : std_logic_vector( 7 downto 0) := getFDRVal(BUS_FREQ_C, SCL_FREQ_C);

  signal strobe       : std_logic                     := '0';
  signal pulseid      : std_logic_vector(63 downto 0) := (others => '0');
  signal pulseid_o    : std_logic_vector(63 downto 0) := (others => '0');
  signal pwm          : std_logic_vector( 7 downto 0) := x"ff"; -- pwm brightness control
  signal iref         : std_logic_vector( 7 downto 0) := x"80"; -- analog brightness control

  signal rst          : std_logic;
  signal bsy          : std_logic;

  constant CR_INI_C   : std_logic_vector( 7 downto 0) := (others => '0');
  signal cr           : std_logic_vector( 7 downto 0) := (others => '0');

  signal fdr          : std_logic_vector( 7 downto 0) := FDRVAL_C;

  signal div          : unsigned(31 downto 0)         := to_unsigned(DIV_C, 32);
  signal div_init     : unsigned(31 downto 0)         := to_unsigned(DIV_C, 32);

  signal dbg          : std_logic_vector(31 downto 0);
  signal malErrors    : std_logic_vector(31 downto 0);
  signal nakErrors    : std_logic_vector(31 downto 0);
  signal rbkErrors    : std_logic_vector(31 downto 0);
  signal locRst       : std_logic;

  signal grayEnc      : std_logic;
  signal markerEn     : std_logic;

  signal raddr_w      : unsigned(raddr'left downto 2);
  signal waddr_w      : unsigned(waddr'left downto 2);
begin

  raddr_w   <= unsigned(raddr(raddr_w'range));
  waddr_w   <= unsigned(waddr(waddr_w'range));

  locRst    <= cr(0);
  grayEnc   <= not cr(1);
  markerEn  <= cr(2);
  rst       <= (not rstn) or locRst;

  rdata <= pulseid(31 downto 0)                              when raddr_w = 0 else
           fdr & cr & pwm & iref                             when raddr_w = 1 else
           std_logic_vector(div_init + 1)                    when raddr_w = 2 else
           dbg                                               when raddr_w = 3 else
           malErrors                                         when raddr_w = 4 else
           nakErrors                                         when raddr_w = 5 else
           rbkErrors                                         when raddr_w = 6 else
           (others => '0');

  P_MARK : process ( markerEn, pulseid ) is
    variable v : std_logic_vector(pulseid'range);
  begin
    if ( markerEn = '1' ) then
      v := pulseid(pulseid'left - 1 downto 0) & '1';
      v( NUM_LEDS_G - 1 ) := '1';
    else
      v := pulseid;
    end if;
    pulseid_o <= v;
  end process P_MARK;

  P_SEQ  : process( clk ) is
  begin
    if ( rising_edge( clk ) ) then
      if ( rstn = '0' ) then
        div      <= div_init;
        strobe   <= '0';
      else
        strobe <= '0';
        if ( div = 0 ) then
          div     <= div_init;
          strobe  <= '1';
          pulseid <= std_logic_vector(unsigned(pulseid) + 1);
        else
          div <= div - 1;
        end if;
        if ( ws = '1' ) then
          if    ( waddr_w = 0 ) then
            if ( wstrb = x"f" ) then
              pulseid <= x"0000_0000" & wdata;
            end if;
          elsif ( waddr_w = 1 ) then
            if ( wstrb(0) = '1' ) then
              iref <= wdata(7 downto 0);
            end if;
            if ( wstrb(1) = '1' ) then
              pwm  <= wdata(15 downto 8);
            end if;
            if ( wstrb(2) = '1' ) then
              cr   <= wdata(23 downto 16);
            end if;
            if ( wstrb(3) = '1' ) then
              fdr  <= wdata(31 downto 24);
            end if;
          elsif ( waddr_w = 2 ) then
            if ( wstrb = x"f" ) then
              div_init <= unsigned(wdata) - 1;
            end if;
          end if;
        end if;
      end if;
    end if;
  end process P_SEQ;

  U_LED : entity work.LedStripController
    generic map (
      I2C_FDRVAL_G     => FDRVAL_C
    )
    port map (
      rst              => rst,
      clk              => clk,

      strobe           => strobe,
      pulseid          => pulseid_o,
      pwm              => pwm,
      iref             => iref,
      busy             => bsy,
      grayCode         => grayEnc,

      malErrors        => malErrors,
      nakErrors        => nakErrors,
      rbkErrors        => rbkErrors,

      fdrRegValid      => '1',
      fdrRegData       => fdr,

      sdaDir           => open,
      sdaOut           => sda_t,
      sclOut           => scl_t,
      sclInp           => scl_i,
      sdaInp           => sda_i,

      dbgState         => dbg(19 downto 0)
    );

    dbg(31 downto 24) <= malErrors(7 downto 0);
    dbg(23 downto 20) <= (others => '0');
 
end architecture rtl;

