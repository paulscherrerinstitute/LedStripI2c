library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.MpcI2cSequencerPkg.all;

use work.TextUtilPkg.all;

entity MpcI2cSequencerTb is
end entity MpcI2cSequencerTb;

architecture sim of MpcI2cSequencerTb is

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

  constant I2C_ADDR_C       : std_logic_vector(6 downto 0) := "1010000";
  constant I2C_ADDR_BOGUS_C : std_logic_vector(6 downto 0) := "1011000";

  signal SDA, SCL : std_logic;

  signal SDAo     : std_logic := '1';
  signal SDAt     : std_logic := '0';
  signal SDAi     : std_logic;
  signal SCLo     : std_logic := '1';
  signal SCLt     : std_logic := '0';
  signal SCLi     : std_logic;

  signal clk      : std_logic := '0';
  signal rst      : std_logic := '1';

  signal run      : boolean := true;
  signal cnt      : natural := 0;
  signal rbaddr   : natural := 0;
  signal readData : std_logic_vector( 7 downto  0);
  signal readValid: std_logic;
  signal progError: std_logic;
  signal nakErrors: std_logic_vector(31 downto  0);

  constant memory : MpcI2cSequenceArray := (
    "00" & I2C_ADDR_C & "0",
    "00" & x"00",
    "10" & x"a5",
    "01" & I2C_ADDR_C & "0",
    "00" & x"04",
    "00" & x"a4",
    "00" & x"a5",
    "01" & I2C_ADDR_C & "0",
    "00" & x"08",
    "00" & x"88",
    "11" & x"89",
    "00" & I2C_ADDR_C & '0',
    "00" & x"00",
    "01" & I2C_ADDR_C & '1',
    "11" & x"0F",
    "00" & I2C_ADDR_BOGUS_C & '1',
    "11" & x"03"
  );
  constant MEM_DEPTH_C     : natural := memory'length;

  subtype  MemPtrType     is natural range 0 to MEM_DEPTH_C - 1;


  signal   memPtr          : MemPtrType;
  signal   memPtrValid     : std_logic := '0';
  signal   memPtrReady     : std_logic;

  type     ProgTblArray   is array (natural range <>) of MemPtrType;
  constant PROGS_C         : ProgTblArray := (
    0, 3, 11, 15
  );
  signal   progPtr         : natural range 0 to PROGS_C'length - 1 := 0;

  

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

  memPtr <= PROGS_C(progPtr);

  P_DRV : process ( clk ) is
  begin
    if ( rising_edge( clk ) ) then
       if ( rst = '1' ) then
          memPtrValid <= '1';
          progPtr     <= 0;
      else
          if ( memPtrValid = '1' and memPtrReady = '1' ) then
            if ( progPtr = PROGS_C'length - 1 ) then
              memPtrValid <= '0';
            else
              progPtr     <= progPtr + 1;
            end if;
          end if;
      end if;
    end if;
  end process P_DRV;

  P_TST : process is
    variable rbExpected : std_logic_vector(7 downto 0);
  begin

    while ( ((rst = '1') or (memPtrValid = '1') or (memPtrReady = '0')) ) loop
      wait until rising_edge( clk );
      if ( readValid = '1' ) then
        case ( rbaddr ) is
          when 0      => rbExpected := x"A5";
          when 4      => rbExpected := x"A4";
          when 5      => rbExpected := x"A5";
          when 8      => rbExpected := x"88";
          when 9      => rbExpected := x"89";
          when others => rbExpected := x"FF";
        end case;

        if ( readData /= rbExpected ) then
          report "Data readback mismatch @" & integer'image(rbaddr) & ": expected " & hstr(rbExpected) & " got " & hstr( readData ) severity failure;
        end if;

        rbaddr <= rbaddr + 1;
      end if;
    end loop;

    if ( progError /= '1' ) then
      report "Expected 'progError' to be asserted (bogus address)" severity failure;
    end if;

    if ( unsigned(nakErrors) /= 1 ) then
      report "Expected 1 NAK Errors but got " & hstr(nakErrors) severity failure;
    end if;

    if ( rbaddr /= 16 ) then
      report "Expected 16 readback values but got " & integer'image(rbaddr) severity failure;
    end if;

    report "Test PASSED";

    run <= false;

    wait;

  end process P_TST;

  U_DUT : entity work.MpcI2cSequencer
    generic map (
      MEM_DEPTH_G      => MEM_DEPTH_C,
      I2C_FDRVAL_G     => x"3F"
    )
    port map (
      rst              => rst,
      clk              => clk,

      memory           => memory,
      memPtr           => memPtr,
      memPtrValid      => memPtrValid,
      memPtrReady      => memPtrReady,

      readData         => readData,
      readValid        => readValid,

      progError        => progError,
      nakErrors        => nakErrors,

      sdaDir           => SDAt,
      sdaOut           => SDAo,
      sclOut           => SCLo,
      sclInp           => SCLi,
      sdaInp           => SDAi
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
