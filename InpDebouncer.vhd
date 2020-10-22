library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity InpDebouncer is
  generic (
    -- How many synchronizer stages
    SYNC_STAGES_G : natural range 0 to 3 := 3;
    -- For how many clock cycles to debounce a rising edge
    -- a high must be at least LOHI_STABLE_G + 1 cycles wide
    -- to be seen at the output (with a delay of LOHI_STABLE_G cycles).
    LOHI_STABLE_G : natural              := 10;
    -- For how many clock cycles to debounce a falling edge
    -- a low must be at least HILO_STABLE_G + 1 cycles wide
    -- to be seen at the output (with a delay of HILO_STABLE_G cycles).
    HILO_STABLE_G : natural              := 10;
    -- State when reset
    RESET_STATE_G : std_logic            := '0'
  );
  port (
    clk           : in  std_logic;
    rst           : in  std_logic;

    dataIn        : in  std_logic;
    dataOut       : out std_logic
  );
end entity InpDebouncer;

architecture rtl of InpDebouncer is

  function max(a,b: integer) return integer is
  begin
    if ( a > b ) then return a; else return b; end if;
  end function max;

  function ite(c: boolean; a,b: integer) return integer is
  begin
    if ( c     ) then return a; else return b; end if;
  end function ite;

  signal dataInSynced : std_logic;

begin

  GEN_SYNC : if ( SYNC_STAGES_G > 0 ) generate
    attribute ASYNC_REG : string;
    signal    sync      : std_logic_vector(SYNC_STAGES_G - 1 downto 0) := ( others => RESET_STATE_G );
    attribute ASYNC_REG of sync : signal is "TRUE";
  begin
    P_SYNC : process ( clk ) is
    begin
      if ( rising_edge( clk ) ) then
        if ( rst = '1' ) then
          sync <= ( others => RESET_STATE_G );
        else
          sync <= sync(sync'left - 1 downto 0) & dataIn;
        end if;
      end if;
    end process P_SYNC;

    dataInSynced <= sync(sync'left);

  end generate GEN_SYNC;

  NO_GEN_SYNC : if ( SYNC_STAGES_G = 0 ) generate
    dataInSynced <= dataIn;
  end generate NO_GEN_SYNC;

  NO_GEN_DEBOUNCER : if ( (HILO_STABLE_G <= 0) and (LOHI_STABLE_G <= 0) ) generate
    dataOut      <= dataInSynced;
  end generate NO_GEN_DEBOUNCER;

  GEN_DEBOUNCER : if ( (HILO_STABLE_G > 0) or (LOHI_STABLE_G > 0) ) generate

    subtype CountType is natural range 0 to max(HILO_STABLE_G, LOHI_STABLE_G);

    constant HILO_INI_C : CountType := HILO_STABLE_G;
    constant LOHI_INI_C : CountType := LOHI_STABLE_G;

    type RegType is record
      wai     : CountType;
      dataIn  : std_logic;
    end record RegType;

    constant REG_INIT_C : RegType := (
      wai     => ite( RESET_STATE_G = '1', HILO_INI_C, LOHI_INI_C ),
      dataIn  => RESET_STATE_G
    );

    signal r            : RegType := REG_INIT_C;
    signal rin          : RegType;

  begin

    P_OUT  : process ( r, dataInSynced ) is
    begin
      if ( r.wai = 0 ) then
        dataOut <= dataInSynced;
      else
        dataOut <= r.dataIn;
      end if;
    end process P_OUT;

    P_COMB : process ( r, dataInSynced ) is
      variable v : RegType;
    begin
      v := r;

      if ( dataInSynced /= r.dataIn ) then
        -- new input value seen; don't register it yet but see for
        -- how long it remains different from the registered value
        if ( r.wai /= 0 ) then
          v.wai := r.wai - 1;
        else
          -- the value has remained stable for long enough; register it
          v.dataIn := dataInSynced;
          -- if the value is currently '1' then it will be '0' next
          -- and we'll be debouncing a rising edge;
          v.wai    := ite( r.dataIn = '1', LOHI_INI_C, HILO_INI_C );
        end if;
      else
        -- input value fell back to the old value (glitch) or
        -- it is already stable; reset timer.
        v.wai := ite( r.dataIn = '0', LOHI_INI_C, HILO_INI_C );
      end if;

      rin <= v;
    end process P_COMB;

    P_SEQ : process ( clk ) is
    begin
      if ( rising_edge( clk ) ) then
        if ( rst = '1' ) then
          r <= REG_INIT_C;
        else
          r <= rin;
        end if;
      end if;
    end process P_SEQ;

  end generate GEN_DEBOUNCER;

end architecture rtl;
