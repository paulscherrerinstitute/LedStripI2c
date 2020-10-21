library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity i2ctb is
end entity i2ctb;

use work.TextUtilPkg.all;

architecture sim of i2ctb is
  component i2cRamSlave is
    generic (
      I2C_ADDR_G  : integer range 0 to 1023;
      ADDR_SIZE_G : positive; -- in bytes
      DATA_SIZE_G : positive  -- in bytes
    );
    port (
      clk    : in    std_logic;
      rst    : in    std_logic;
      i2cSda : inout std_logic;
      i2cScl : inout std_logic
    );
  end component i2cRamSlave;

  constant I2C_ADDR_C : std_logic_vector(6 downto 0) := "1010000";

  signal SDA, SCL : std_logic;

  signal SDAo     : std_logic := '1';
  signal SDAt     : std_logic := '0';
  signal SDAi     : std_logic;
  signal SCLo     : std_logic := '1';
  signal SCLt     : std_logic := '0';
  signal SCLi     : std_logic;

  signal clk      : std_logic := '0';
  signal rst      : std_logic := '1';
  signal irq      : std_logic;
  signal bsy      : std_logic;

  signal wrstrb   : std_logic := '0';
  signal we0      : std_logic_vector( 3 downto  0) := (others => '0');
  signal we1      : std_logic_vector( 3 downto  0) := (others => '0');
  signal we2      : std_logic_vector( 3 downto  0) := (others => '0');
  signal datw     : std_logic_vector( 7 downto  0) := (others => '0');

  signal rdstrb   : std_logic := '0';
  signal rdsel    : std_logic_vector( 1 downto  0) := (others => '0');
  signal datr     : std_logic_vector(31 downto  0);
  signal datr_r   : std_logic_vector(31 downto  0);
  signal datb_r   : std_logic_vector( 7 downto  0);

  signal run      : boolean := true;

  signal cnt      : natural := 0;

begin

  SDA  <= 'Z' when SDAt = '0' else 'H' when SDAo = '1' else '0';
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

  P_TST : process is
    constant FDR_REG  : natural := 1;
    constant CR_REG   : natural := 3;
    constant ST_REG   : natural := 4;
    constant DATA_REG : natural := 8;

    constant CR_MEN   : std_logic_vector( 7 downto  0) := x"80";
    constant CR_MIEN  : std_logic_vector( 7 downto  0) := x"40";
    constant CR_MSTA  : std_logic_vector( 7 downto  0) := x"20";
    constant CR_MTX   : std_logic_vector( 7 downto  0) := x"10";
    constant CR_TXAK  : std_logic_vector( 7 downto  0) := x"08";
    constant CR_RSTA  : std_logic_vector( 7 downto  0) := x"04";

    constant CR_INI   : std_logic_vector( 7 downto  0) := CR_MEN or CR_MIEN;

    constant ST_MCF_I : natural                        :=     7; -- data transferring
    constant ST_MAAS_I: natural                        :=     6; -- addressed as a slave
    constant ST_MBB_I : natural                        :=     5; -- busy busy
    constant ST_MAL_I : natural                        :=     4; -- arbitration lost
    constant ST_SRW_I : natural                        :=     2; -- slave r/w
    constant ST_MIF_I : natural                        :=     1; -- interrupt pending
    constant ST_RXAK_I: natural                        :=     0; -- received ACK


    constant ST_MCF   : std_logic_vector( 7 downto  0) := (ST_MCF_I  => '1', others => '0');
    constant ST_MAAS  : std_logic_vector( 7 downto  0) := (ST_MAAS_I => '1', others => '0');
    constant ST_MBB   : std_logic_vector( 7 downto  0) := (ST_MBB_I  => '1', others => '0');
    constant ST_MAL   : std_logic_vector( 7 downto  0) := (ST_MAL_I  => '1', others => '0');
    constant ST_SRW   : std_logic_vector( 7 downto  0) := (ST_SRW_I  => '1', others => '0');
    constant ST_MIF   : std_logic_vector( 7 downto  0) := (ST_MIF_I  => '1', others => '0');
    constant ST_RXAK  : std_logic_vector( 7 downto  0) := (ST_RXAK_I => '1', others => '0');

    procedure wrb(constant baddr : natural range 0 to 11; constant data : std_logic_vector(7 downto 0)) is
      variable b : natural range 0 to 3;
    begin
      b := baddr mod 4;
      we0 <= (others => '0');
      we1 <= (others => '0');
      we2 <= (others => '0');
      case (baddr/4) is
        when 0 => we0(b) <= '1';
        when 1 => we1(b) <= '1';
        when 2 => we2(b) <= '1';
        when others =>
      end case;
      wrstrb <= '1';
      datw   <=  data;
      wait until rising_edge( clk );
      wrstrb <= '0';
      wait until rising_edge( clk );
    end procedure wrb;

    procedure rd(constant baddr : natural range 0 to 11; constant strobe : boolean) is
      variable b : natural range 0 to 3;
    begin
      b := baddr mod 4;
      rdsel <= std_logic_vector( to_unsigned( baddr/4, rdsel'length ) );
      if ( strobe ) then
        -- hack: this triggers a read-shift operation
        -- if we don't strobe then we can read the result of the previous shift
        -- without initiating a new one...
        rdstrb <= '1';
      end if;
      wait until rising_edge( clk );
      rdstrb <= '0';
      wait until rising_edge( clk );
      datr_r <= datr;
      datb_r <= datr(8*(b+1)-1 downto 8*b);
      wait until rising_edge( clk );
    end procedure rd;

    procedure pend is
    begin
      while ( irq = '0' ) loop
        wait until rising_edge( clk );
      end loop;
      wrb( ST_REG, x"FF" and not ST_MIF );
    end procedure pend;

    procedure send_data(constant data : std_logic_vector(7 downto 0)) is
    begin
      wrb( DATA_REG, data );
      pend;
    end procedure send_data;

    procedure send_start(constant addr : std_logic_vector(6 downto 0); constant restart, read: boolean) is
      variable v : std_logic_vector(7 downto 0);
    begin
      v := CR_INI or CR_MSTA;
      if ( not read ) then
        v := v or CR_MTX;
      end if;
      if ( restart ) then
        v := v or CR_RSTA;
      end if;
      wrb( CR_REG, v );
      v := addr & '0';
      if ( read ) then
        v(0) := '1';
      end if;
      send_data( v );
    end procedure send_start;

    procedure send_start_write(constant addr : std_logic_vector(6 downto 0)) is
    begin
      send_start( addr, restart => false, read => false );
    end procedure send_start_write;

    procedure send_restart_write(constant addr : std_logic_vector(6 downto 0)) is
    begin
      send_start( addr, restart => true , read => false );
    end procedure send_restart_write;

    procedure send_start_read (constant addr : std_logic_vector(6 downto 0)) is
    begin
      send_start( addr, restart => false, read => true  );
    end procedure send_start_read;

    procedure send_restart_read (constant addr : std_logic_vector(6 downto 0)) is
    begin
      send_start( addr, restart => true , read => true  );
    end procedure send_restart_read ;


    procedure send_stop is
    begin
      wrb( CR_REG  , CR_INI);
      -- wait until bus is not busy anymore
      while ( bsy = '1' ) loop
        wait until rising_edge( clk );
      end loop;
    end procedure send_stop;

    procedure read_data is
    begin
      rd( DATA_REG, strobe => true  );
      pend;
      rd( DATA_REG, strobe => false );
    end procedure read_data;

    procedure read_data_nak is
    begin
      wrb( CR_REG  , CR_INI or CR_MSTA or CR_TXAK );
      read_data;
    end procedure read_data_nak;

  begin
    while ( rst = '1' ) loop
      wait until rising_edge( clk );
    end loop;

    wrb( FDR_REG , x"3F" ); -- 64
    wrb( CR_REG  , CR_INI);
    send_start_write( I2C_ADDR_C );
    send_data( x"00" ); -- RAM addr
    send_data( x"5A" );
    send_data( x"5B" );
    send_data( x"5C" );

    -- restart
    send_restart_write( I2C_ADDR_C );
    send_data( x"00" ); -- RAM addr
    -- restart; change direction
    send_restart_read( I2C_ADDR_C );

    -- starts first read
    read_data;
    report hstr( datb_r );
    read_data;
    report hstr( datb_r );
    read_data_nak;
    report hstr( datb_r );

    send_stop;

    run <= false;
    wait until rising_edge( clk );
  end process P_TST;

  U_DUT : entity work.ioxos_mpc_master_i2c_ctl
    generic map (
      enable_ila       => 0
    )
    port map (
      elb_RESET        => rst,
      elb_CLK          => clk,

      i2creg_WRSTRB    => wrstrb,
      i2creg_WE0       => we0,
      i2creg_WE1       => we1,
      i2creg_WE2       => we2,
      i2creg_DATW      => datw,
      i2creg_RDSTRB    => rdstrb,
      i2creg_RDSEL     => rdsel,
      i2creg_DATR      => datr,

      i2cctl_IRQOK     => irq,
      i2cctl_BUSY      => bsy,

      int_I2C_DIR      => SDAt,
      int_I2C_SDAO     => SDAo,
      int_I2C_SDC      => SCLo,
      int_I2C_SDCI     => SCLi,
      int_I2C_SDAI     => SDAi
    );

  U_RAM : i2cRamSlave
    generic map (
      I2C_ADDR_G       => to_integer(unsigned(I2C_ADDR_C)),
      ADDR_SIZE_G      => 1,
      DATA_SIZE_G      => 1
    )
    port map (
      clk              => clk,
      rst              => rst,
      i2cSda           => SDA,
      i2cScl           => SCL
    );
  
end architecture sim;
