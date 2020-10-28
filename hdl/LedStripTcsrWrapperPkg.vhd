library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package LedStripTcsrWrapperPkg is

  type EvrStreamType is record
    data       : std_logic_vector( 7 downto 0);
    addr       : std_logic_vector(10 downto 0);
    valid      : std_logic;
  end record EvrStreamType;

  constant EVR_STREAM_INIT_C : EvrStreamType := (
    data       => (others => '0'),
    addr       => (others => '0'),
    valid      => '0'
  );

end package LedStripTcsrWrapperPkg;
