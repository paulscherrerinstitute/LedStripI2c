library ieee;

use ieee.std_logic_1164.all;

package MpcI2cSequencerPkg is 

  -- if CTRL is '1' and last is '0'  then a restart is generated
  -- if CTRL and LAST are both set then a STOP is generated

  constant MPCI2C_CTRL_C : natural := 8;
  constant MPCI2C_LAST_C : natural := 9;
  subtype  MpcI2cSequenceDataType is std_logic_vector(MPCI2C_LAST_C downto 0);

  type     MpcI2cSequenceArray    is array(natural range<>) of MpcI2cSequenceDataType;

end package MpcI2cSequencerPkg;
