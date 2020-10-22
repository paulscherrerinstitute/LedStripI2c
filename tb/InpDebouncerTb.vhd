library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.TextUtilPkg.all;

entity InpDebouncerTb is
end entity InpDebouncerTb;

architecture sim of InpDebouncerTb is

  constant HILO_C : natural   :=  2;
  constant LOHI_C : natural   :=  1;

  signal clk      : std_logic := '0';
  signal rst      : std_logic := '1';
  signal run      : boolean   := true;
  signal cnt      : natural   := 0;

  signal dataIn   : std_logic := '0';
  signal dataOut  : std_logic;

begin

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
        when 5      => rst <= '0';
        when others =>
      end case;
      
      cnt <= ncnt;
    end if;
  end process P_CNT;

  P_TST : process is
    procedure dly(constant v: natural) is
    begin
      for i in 1 to v loop
        wait until rising_edge( clk );
      end loop;
    end procedure dly;
  begin

    while ( rst = '1' ) loop
      wait until rising_edge( clk );
    end loop;

    dly(4);
    dataIn <= '1';
    dly(1);
    dataIn <= '0';
    dly(1);
    dataIn <= '1';
    dly(2);
    dataIn <= '0';
    dly(2);


    run <= false;

    wait;

  end process P_TST;

  U_DUT : entity work.InpDebouncer
    generic map (
      SYNC_STAGES_G    => 0,
      LOHI_STABLE_G    => LOHI_C,
      HILO_STABLE_G    => HILO_C
    )
    port map (
      clk              => clk,
      rst              => rst,

      dataIn           => dataIn,
      dataOut          => dataOut
    );

end architecture sim;
