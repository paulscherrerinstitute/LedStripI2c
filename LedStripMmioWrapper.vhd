library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

entity LedStripMmioWrapper is
  generic (
    -- SCL freq. is frequency of 'clk' divided by 4*FDR_RATIO (selected by FDRVAL)
    I2C_FDRVAL_G : std_logic_vector(7 downto 0);
    GRAYENCODE_G : boolean                      := true;
    DIV_G        : natural                      := 100000000/100;
    ADDR_W_G     : positive                     := 4
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

  signal strobe       : std_logic                     := '0';
  signal pulseid      : std_logic_vector(63 downto 0) := (others => '0');
  signal pwm          : std_logic_vector( 7 downto 0) := x"ff"; -- pwm brightness control
  signal iref         : std_logic_vector( 7 downto 0) := x"80"; -- analog brightness control

  signal rst          : std_logic;
  signal bsy          : std_logic;

  signal cr           : std_logic_vector( 7 downto 0) := (others => '0');

  signal div          : unsigned(31 downto 0) := to_unsigned(DIV_G - 1, 32);
  signal div_init     : unsigned(31 downto 0) := to_unsigned(DIV_G - 1, 32);

  signal dbg          : std_logic_vector(31 downto 0);
  signal malErrors    : std_logic_vector(31 downto 0);
  signal locRst       : std_logic;
begin

  locRst <= cr(0);

  rst    <= (not rstn) or locRst;

  rdata <= pulseid(31 downto 0)                              when raddr(3 downto 2) = "00" else 
           x"00" & cr & pwm & iref                             when raddr(3 downto 2) = "01" else
           std_logic_vector(div_init + 1)                    when raddr(3 downto 2) = "10" else
           dbg;

  P_SEQ  : process( clk ) is
  begin
    if ( rising_edge( clk ) ) then
      if ( rstn = '0' ) then
        div    <= div_init;
        strobe <= '0';
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
          if ( waddr(3 downto 2) = "00" ) then
            if ( wstrb = x"f" ) then
              pulseid <= x"0000_0000" & wdata;
            end if;
          elsif ( waddr(3 downto 2) = "01" ) then
            if ( wstrb(0) = '1' ) then
              iref <= wdata(7 downto 0);
            end if;
            if ( wstrb(1) = '1' ) then
              pwm  <= wdata(15 downto 8);
            end if;
            if ( wstrb(2) = '1' ) then
              cr   <= wdata(23 downto 16);
            end if;
          elsif ( waddr(3 downto 2) = "10" ) then
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
      I2C_FDRVAL_G     => "1" & std_logic_vector(to_unsigned(80, 7)),
      GRAYENCODE_G     => false
    )
    port map (
      rst              => rst,
      clk              => clk,

      strobe           => strobe,
      pulseid          => pulseid,
      pwm              => pwm,
      iref             => iref,
      busy             => bsy,
      malErrors        => malErrors,

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

