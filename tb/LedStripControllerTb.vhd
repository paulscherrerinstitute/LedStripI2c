library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.TextUtilPkg.all;

entity LedStripControllerTb is
end entity LedStripControllerTb;

architecture sim of LedStripControllerTb is

  component i2cRegSlaveWrap is
    generic (
      I2C_ADDR_G  : integer range 0 to 1023;
      ADDR_SIZE_G : positive; -- in bytes
      DATA_SIZE_G : positive  -- in bytes
    );
    port (
      clk    : in    std_logic;
      rst    : in    std_logic;

      addr   : out   std_logic_vector(8*ADDR_SIZE_G-1 downto 0);
      wrEn   : out   std_logic;
      wrData : out   std_logic_vector(8*DATA_SIZE_G-1 downto 0);
      rdEn   : out   std_logic;
      rdData : in    std_logic_vector(8*DATA_SIZE_G-1 downto 0);

      i2cSda : inout std_logic;
      i2cScl : inout std_logic
    );
  end component i2cRegSlaveWrap;

  subtype I2cAddrType is std_logic_vector(6 downto 0);

  type    I2cAddrArray is array (natural range <>) of I2cAddrType;

  constant I2C_ADDR_C : I2cAddrArray := (
     "0000101",
     "1101001"
  );

  constant ADDR_SIZE_C : natural := 1;
  constant DATA_SIZE_C : natural := 1;

  constant NLOOPS_C    : natural := 256;

  signal SDA, SCL : std_logic;

  signal SDAo     : std_logic := '1';
  signal SDAt     : std_logic := '0';
  signal SDAi     : std_logic;
  signal SCLo     : std_logic := '1';
  signal SCLt     : std_logic := '0';
  signal SCLi     : std_logic;

  signal clk      : std_logic := '0';
  signal rst      : std_logic := '1';
  signal bsy      : std_logic;

  signal run      : boolean := true;
  signal cnt      : natural := 0;
  signal nloops   : natural := 0;

  signal strobe   : std_logic := '0';
  signal pulseid  : std_logic_vector(63 downto 0) := (others => 'X');
  signal pulseid_r: unsigned        (63 downto 0) := (others => '0');
  constant PIDI_C : unsigned        (63 downto 0) := x"00000000_01010101";
  signal pwm      : std_logic_vector( 7 downto 0) := x"F0";
  signal iref     : std_logic_vector( 7 downto 0) := x"0A";


begin

  SDA  <= 'H' when SDAt = '0' else 'H' when SDAo = '1' else '0';
  SDAi <= to_X01(SDA);

  SCL  <= 'Z' when SCLt = '0' else 'H' when SCLo = '1' else '0';
  SCLi <= to_X01(SCL);

  SCLt <= '1';

  P_CLK : process is
  begin
    if run then
      wait for 100 ns;
      clk <= not clk;
    else
      wait;
    end if;
  end process P_CLK;

  P_CNT : process ( clk ) is
    variable ncnt : natural;
  begin
    if ( rising_edge( clk ) ) then
      ncnt := cnt + 1;

      case ( cnt ) is
        when 20     => rst <= '0';
        when others =>
      end case;
      
      cnt <= ncnt;
    end if;
  end process P_CNT;

  P_DRV : process ( clk ) is
  begin
    if ( rising_edge( clk ) ) then
      if ( rst = '1' ) then
        strobe <= '0';
      else
        strobe <= '0';
        pulseid <= (others => 'X');
        if ( bsy = '0' ) then
          strobe    <= '1';
          pulseid   <= std_logic_vector(pulseid_r);
          pulseid_r <= pulseid_r + PIDI_C;
          nloops    <= nloops + 1;
        end if;
      end if;
    end if;
  end process P_DRV;

  P_TST : process is
  begin

    while ( nloops <= NLOOPS_C ) loop
      wait until rising_edge( clk );
    end loop;

    run <= false;

    wait;

  end process P_TST;

  U_DUT : entity work.LedStripController
    generic map (
      I2C_FDRVAL_G     => x"3F"
    )
    port map (
      rst              => rst,
      clk              => clk,

      strobe           => strobe,
      pulseid          => pulseid,
      pwm              => pwm,
      iref             => iref,
      busy             => bsy,
      grayCode         => '0',

      sdaDir           => SDAt,
      sdaOut           => SDAo,
      sclOut           => SCLo,
      sclInp           => SCLi,
      sdaInp           => SDAi
    );

  G_MON : for device in I2C_ADDR_C'range generate

  signal addr     : std_logic_vector(8*ADDR_SIZE_C-1 downto 0);
  signal wrEn     : std_logic;
  signal wrData   : std_logic_vector(8*DATA_SIZE_C-1 downto 0);
  signal rdEn     : std_logic;
  signal rdData   : std_logic_vector(8*DATA_SIZE_C-1 downto 0) := (others => 'X');

  begin


  U_RAM : i2cRegSlaveWrap
    generic map (
      I2C_ADDR_G       => to_integer(unsigned(I2C_ADDR_C(device))),
      ADDR_SIZE_G      => ADDR_SIZE_C,
      DATA_SIZE_G      => DATA_SIZE_C
    )
    port map (
      clk              => clk,
      rst              => rst,

      addr             => addr,
      wrEn             => wrEn,
      wrData           => wrData,
      rdEn             => rdEn,
      rdData           => rdData,

      i2cSda           => SDA,
      i2cScl           => SCL
    );

  P_MON : process ( clk ) is
  begin
    if ( rising_edge( clk ) ) then
      if ( wrEn = '1' ) then
        report "@" & integer'image(device) & "[" & hstr(addr) & "]:= " & hstr(wrData);
      end if;
    end if;
  end process P_MON;

  end generate;

  
end architecture sim;
