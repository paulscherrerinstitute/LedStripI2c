library ieee;
use ieee.std_logic_1164.all;

entity ifc1210_pon_ila_32 is
  port (
    ila_CLK  : in  std_logic;
    ila_TRIG : in  std_logic_vector(15 downto 0);
    ila_DATA : in  std_logic_vector(31 downto 0)
  );
end entity ifc1210_pon_ila_32;

architecture dummy of ifc1210_pon_ila_32 is
begin
end architecture dummy;
