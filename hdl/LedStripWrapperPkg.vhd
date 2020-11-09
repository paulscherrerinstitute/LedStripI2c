library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.MpcI2cSequencerPkg.all;

package LedStripWrapperPkg is

  -- register map version
  constant REG_VERSION_C : std_logic_vector( 3 downto 0) := x"0";

  function getWdogCount(busFreqHz : real; timeoutMs : real) return natural;

  constant SHFT_DFLT_C       : std_logic                     := '1';
  constant PWM_DFLT_C        : std_logic_vector( 7 downto 0) := x"FF";
  constant IREF_DFLT_C       : std_logic_vector( 7 downto 0) := x"80";

  function setMark(constant numLeds: natural range 1 to 32) return std_logic_vector;

  constant CR_RESET_I_C      : natural                       := 0;
  constant CR_BIN_ENC_I_C    : natural                       := 1;
  constant CR_SHFT_EN_I_C    : natural                       := 2;

  type LedWrapperRegType is record
    mark  : std_logic_vector(31 downto 0);
    fdr   : std_logic_vector( 7 downto 0);
    pwm   : std_logic_vector( 7 downto 0);
    iref  : std_logic_vector( 7 downto 0);
    trgMux: std_logic_vector( 3 downto 0);
    cr    : std_logic_vector( 3 downto 0);
  end record LedWrapperRegType;

  constant TCSR_REGVER_IDX_C : natural := 0;
  constant TCSR_CR_IDX_C     : natural := 1;
  constant TCSR_MARK_IDX_C   : natural := 2;
  constant TCSR_MALERR_IDX_C : natural := 3;
  constant TCSR_NAKERR_IDX_C : natural := 4;
  constant TCSR_RBKERR_IDX_C : natural := 5;
  constant TCSR_SEQERR_IDX_C : natural := 6;
  constant TCSR_WDGERR_IDX_C : natural := 7;
  constant TCSR_PIDCNT_IDX_C : natural := 8;
  constant TCSR_SYNERR_IDX_C : natural := 9;
  constant TCSR_DBG_IDX_C    : natural :=10;

  constant TCSR_NUM_REGS_C   : natural :=11;
  constant TCSR_LD_NUM_REGS_C: natural := 4;

end package LedStripWrapperPkg;

package body LedStripWrapperPkg is

  function setMark(constant numLeds: natural range 1 to 32) return std_logic_vector is
    variable v : std_logic_vector(31 downto 0);
  begin
    v := (others => '0');
    v(             0) := '1';
    v(numLeds    - 1) := '1';
    return v;
  end function setMark;

  function getWdogCount(busFreqHz : real; timeoutMs : real) return natural is
    variable v   : real;
    variable min : real;
  begin
    if ( timeoutMs = 0.0 ) then
      return 0;
    else
      v := timeoutMs / 1000.0;
      -- enforce a reasonable minimum:
      --   i2c bytes: 2 controllers * ( 6 bytes for display + 7 for readback + 3 for brightness update )
      min := 2.0 * ( 6.0 + 7.0 + 3.0 );
      --   1 i2c byte: 9 bits
      min := min * 9.0;
      -- include some slack for start/stop overhead
      min := min*1.2;
      -- fastest i2c speed
      min := min / 1.0E6;
      if ( v < min ) then
        v := min;
      end if;
      return natural( busFreqHz * v );
    end if;
  end function getWdogCount;


end package body LedStripWrapperPkg;
