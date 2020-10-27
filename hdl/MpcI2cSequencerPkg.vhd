library ieee;

use ieee.std_logic_1164.all;

package MpcI2cSequencerPkg is 

  -- if CTRL is '1' and last is '0'  then a restart is generated
  -- if CTRL and LAST are both set then a STOP is generated

  constant MPCI2C_CTRL_C : natural := 8;
  constant MPCI2C_LAST_C : natural := 9;
  constant MPCI2C_RDNW_C : natural := 0;

  -- prepend any of these to a data byte;
  -- If the bus is not currently held, the first item (even if SEQ_NORM) generates a start condition
  -- and therefore the associated data must be a bus address + R/W bit.
  constant SEQ_NORM        : std_logic_vector(1 downto 0) := "00"; -- data byte to send
  constant SEQ_RSRT        : std_logic_vector(1 downto 0) := "01"; -- restart; data is bus address + R/W
  constant SEQ_LAST        : std_logic_vector(1 downto 0) := "10"; -- last byte to send; no STOP
  constant SEQ_STOP        : std_logic_vector(1 downto 0) := "11"; -- last byte to send; STOP

  subtype  MpcI2cSequenceDataType is std_logic_vector(MPCI2C_LAST_C downto 0);

  type     MpcI2cSequenceArray    is array(natural range<>) of MpcI2cSequenceDataType;

end package MpcI2cSequencerPkg;
