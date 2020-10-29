library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.LedStripTcsrWrapperPkg.all;
use work.MpcI2cSequencerPkg.all;

entity LedStripTcsrWrapper is
  generic (
    -- tcsrl clock frequence [Hz]
    TCSR_CLOCK_FRQ_G      : real;
    -- default SCL frequency [Hz]; may change at run-time
    DFLT_I2C_SCL_FRQ_G    : real                         := 400.0E3;
    -- offset in evr stream
    PULSEID_OFFSET_G      : natural                      := 52;
    -- length in octets
    PULSEID_LENGTH_G      : positive                     :=  8;
    PULSEID_BIGEND_G      : boolean                      := false;
    -- tcsr and evr clocks are asynchronous
    ASYNC_CLOCKS_G        : boolean                      := true;
    -- I2C Address of RHS PCA9955B
    I2C_ADDR_R_G          : std_logic_vector(6 downto 0) := "0000101";
    -- I2C Address of LHS PCA9955B
    I2C_ADDR_L_G          : std_logic_vector(6 downto 0) := "1101001";
    -- Synchronizer stages for reading scalInp/sdaInp
    I2C_SYNC_STAGES_G     : natural range 0 to 3         := 3;
    -- For how many (tcsr) cycles to debounce sclInp, sdaInp
    I2C_DEBOUNCE_CYCLES_G : natural                      := 10;
    -- V1 has 
    NUM_LEDS_G            : natural range 1 to 32        := 30;
    -- Enable default marker
    DFLT_MARKER_ENABLE_G  : std_logic                    := '1';
    -- Pulse ID watchdog timeout (in ms); if no new pulse ID is
    -- received from the EVR stream within this timeout period
    -- then the 'missing pulseID' counter is incremented.
    -- Setting this to 0.0 disables the watchdog.
    PULSEID_WDOG_PER_MS_G : real                         := 12.0
  );
  port (
    -- TCSR clock domain
    tcsrCLK      : in  std_logic;
    tcsrRST      : in  std_logic;

    tcsrADD      : in  std_logic_vector( 5 downto 2);
    tcsrDATW     : in  std_logic_vector(31 downto 0);
    tcsrWE       : in  std_logic_vector( 3 downto 0);
    tcsrDATR     : out std_logic_vector(31 downto 0);
    tcsrWR       : in  std_logic;
    tcsrRD       : in  std_logic;
    tcsrACK      : out std_logic;
    tcsrERR      : out std_logic;

    sclInp       : in  std_logic;
    sclOut       : out std_logic;
    sdaInp       : in  std_logic;
    sdaOut       : out std_logic;

    -- EVR clock domain
    evrClk       : in  std_logic;
    evrStream    : in  EvrStreamType;
     -- allows for lower update rates
    ledTrig      : in  std_logic_vector(15 downto 0) := x"0001"
  );
end entity LedStripTcsrWrapper;

architecture rtl of LedStripTcsrWrapper is

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

  constant PULSEID_WDOG_P_C  : natural                      := getWdogCount(TCSR_CLOCK_FRQ_G, PULSEID_WDOG_PER_MS_G);
  constant FDRVAL_C          : std_logic_vector(7 downto 0) := getFDRVal(TCSR_CLOCK_FRQ_G, DFLT_I2C_SCL_FRQ_G);

  signal pulseid             : std_logic_vector(63 downto 0);
  signal pulseidValid        : std_logic;
  signal pulseid_o           : std_logic_vector(63 downto 0);

  constant SHFT_DFLT_C       : std_logic                     := '1';
  constant PWM_DFLT_C        : std_logic_vector( 7 downto 0) := x"FF";
  constant IREF_DFLT_C       : std_logic_vector( 7 downto 0) := x"80";

  function setMark return std_logic_vector is
    variable v : std_logic_vector(31 downto 0);
  begin
    v := (others => '0');
    v(             0) := '1';
    v(NUM_LEDS_G - 1) := '1';
    return v;
  end function setMark;

  constant MARK_DFLT_C       : std_logic_vector(31 downto 0) := setMark;

  constant CR_RESET_I_C      : natural                       := 0;
  constant CR_BIN_ENC_I_C    : natural                       := 1;
  constant CR_SHFT_EN_I_C    : natural                       := 2;

  constant CR_DFLT_C         : std_logic_vector( 3 downto 0) := (
    CR_RESET_I_C   => '0',
    CR_BIN_ENC_I_C => '0',
    CR_SHFT_EN_I_C => DFLT_MARKER_ENABLE_G,
    others         => '0'
  );

  type RegType is record
    mark  : std_logic_vector(31 downto 0);
    fdr   : std_logic_vector( 7 downto 0);
    pwm   : std_logic_vector( 7 downto 0);
    iref  : std_logic_vector( 7 downto 0);
    trgMux: std_logic_vector( 3 downto 0);
    cr    : std_logic_vector( 3 downto 0);
  end record RegType;

  constant REG_INIT_C : RegType := (
    mark                     => MARK_DFLT_C,
    fdr                      => FDRVAL_C,
    pwm                      => PWM_DFLT_C,
    iref                     => IREF_DFLT_C,
    trgMux                   => (others => '0'),
    cr                       => CR_DFLT_C
  );

  signal r                   : RegType := REG_INIT_C;

  signal cr32Rbk             : std_logic_vector(31 downto 0);

  constant TCSR_CR_IDX_C     : natural := 0;
  constant TCSR_MARK_IDX_C   : natural := 1;
  constant TCSR_MALERR_IDX_C : natural := 2;
  constant TCSR_NAKERR_IDX_C : natural := 3;
  constant TCSR_RBKERR_IDX_C : natural := 4;
  constant TCSR_SEQERR_IDX_C : natural := 5;
  constant TCSR_WDGERR_IDX_C : natural := 6;
  constant TCSR_PIDCNT_IDX_C : natural := 7;
  constant TCSR_SYNERR_IDX_C : natural := 8;
  constant TCSR_DBG_IDX_C    : natural := 9;

  signal malErrors           : std_logic_vector(31 downto 0);
  signal nakErrors           : std_logic_vector(31 downto 0);
  signal rbkErrors           : std_logic_vector(31 downto 0);
  signal synErrors           : std_logic_vector(31 downto 0);
  signal seqErrors           : std_logic_vector(31 downto 0);
  signal wdgErrors           : std_logic_vector(31 downto 0);
  signal pulseidCnt          : std_logic_vector(31 downto 0);
  signal dbg                 : std_logic_vector(31 downto 0);

  signal sdaDirLoc           : std_logic;
  signal sdaOutLoc           : std_logic;

  signal wordAddr            : unsigned(tcsrADD'range);

  signal ledCtrlRst          : std_logic;

begin

  ledCtrlRst <= (   r.cr( CR_RESET_I_C   ) or tcsrRST );

  cr32Rbk    <= r.fdr & r.trgMux & r.cr & r.pwm & r.iref;

  -- If we OR some marker LEDs we must do so after gray-code conversion,
  -- i.e., we cannot use the built-in gray-encoder or LedStripController
  P_MARK : process ( r, pulseid ) is
    variable v : std_logic_vector(pulseid'range);
  begin
    v := pulseid;
    if ( r.cr( CR_BIN_ENC_I_C ) = '0' ) then
      v := v xor ( '0' & v(v'left downto v'right + 1) );
    end if;
    if ( r.cr( CR_SHFT_EN_I_C ) = '1' ) then
      v := v(v'left - 1 downto 0) & '0';
      v(r.mark'range) := (v(r.mark'range) or r.mark);
    end if;
    pulseid_o <= v;
  end process P_MARK;

  wordAddr <= unsigned(tcsrADD);
  tcsrDATR <= cr32Rbk      when (wordAddr = TCSR_CR_IDX_C    ) else
              r.mark       when (wordAddr = TCSR_MARK_IDX_C  ) else
              malErrors    when (wordAddr = TCSR_MALERR_IDX_C) else
              nakErrors    when (wordAddr = TCSR_NAKERR_IDX_C) else
              rbkErrors    when (wordAddr = TCSR_RBKERR_IDX_C) else
              seqErrors    when (wordAddr = TCSR_SEQERR_IDX_C) else
              wdgErrors    when (wordAddr = TCSR_WDGERR_IDX_C) else
              pulseidCnt   when (wordAddr = TCSR_PIDCNT_IDX_C) else
              synErrors    when (wordAddr = TCSR_SYNERR_IDX_C) else
              dbg;

  P_TCSR_WRITE : process ( tcsrCLK ) is
  begin
    if ( rising_edge( tcsrCLK ) ) then
      if ( tcsrRST = '1' ) then
        r <= REG_INIT_C;
      elsif ( tcsrWR = '1' ) then
        if ( wordAddr = TCSR_CR_IDX_C ) then
          if ( tcsrWE(3) = '1' ) then
            r.fdr    <= tcsrDATW(31 downto 24);
          end if;
          if ( tcsrWE(2) = '1' ) then
            r.trgMux <= tcsrDATW(23 downto 20);
            r.cr     <= tcsrDATW(19 downto 16);
          end if;
          if ( tcsrWE(1) = '1' ) then
            r.pwm    <= tcsrDATW(15 downto  8);
          end if;
          if ( tcsrWE(0) = '1' ) then
            r.iref   <= tcsrDATW( 7 downto  0);
          end if;
        elsif ( wordAddr = TCSR_MARK_IDX_C ) then
          for i in tcsrWE'range loop
            if ( tcsrWE(i) = '1' ) then
              r.mark(8*i + 7 downto 8*i) <= tcsrDATW(8*i + 7 downto 8*i);
            end if;
          end loop;
        end if;
      end if;
    end if;
  end process P_TCSR_WRITE;

  U_LedStrip : entity work.LedStripController
    generic map (
      I2C_FDRVAL_G          => FDRVAL_C,
      I2C_ADDR_R_G          => I2C_ADDR_R_G,
      I2C_ADDR_L_G          => I2C_ADDR_L_G,
      DBNCE_SYNC_G          => I2C_SYNC_STAGES_G,
      DBNCE_CYCL_G          => I2C_DEBOUNCE_CYCLES_G
    )
    port map (
      clk                   => tcsrCLK,
      rst                   => ledCtrlRst,

      strobe                => pulseidValid,
      pulseid               => pulseid_o,
      pwm                   => r.pwm,
      iref                  => r.iref,
      grayCode              => '0',
      busy                  => dbg(20),

      fdrRegValid           => '1',
      fdrRegData            => r.fdr,

      malErrors             => malErrors,
      nakErrors             => nakErrors,
      rbkErrors             => rbkErrors,

      sdaDir                => sdaDirLoc,
      sdaOut                => sdaOutLoc,
      sdaInp                => sdaInp,
      sclOut                => sclOut,
      sclInp                => sclInp,

      dbgState              => dbg(19 downto 0)
    );

  dbg(31 downto 21) <= (others => '0');

  -- create a block; helps naming constraints...

  B_PulseIdExtractor : block is
    signal ledTrigLoc          : std_logic;
    signal trgMuxEvr           : unsigned(3 downto 0) := (others => '0');
  begin

    -- synchronize trgMux into EVR clock domain; don't care about
    -- glitches as this happens rarely
    P_SYNC : process ( evrClk ) is
    begin
      if ( rising_edge( evrClk ) ) then
        trgMuxEvr <= unsigned( r.trgMux );
      end if;
    end process P_SYNC;

    ledTrigLoc <= ledTrig( to_integer( trgMuxEvr ) );


    U_GetPid   : entity work.PulseidExtractor
      generic map (
        PULSEID_OFFSET_G      => PULSEID_OFFSET_G,
        PULSEID_BIGEND_G      => PULSEID_BIGEND_G,
        PULSEID_LENGTH_G      => PULSEID_LENGTH_G,
        USE_ASYNC_OUTP_G      => ASYNC_CLOCKS_G,
        PULSEID_WDOG_P_G      => PULSEID_WDOG_P_C
      )
      port map (
           clk                => evrClk,
           rst                => '0',
           trg                => ledTrigLoc,

           evrStream          => evrStream,

           oclk               => tcsrCLK,
           orst               => tcsrRST,
           pulseid            => pulseid,
           pulseidStrobe      => pulseidValid,
           synErrors          => synErrors,
           seqErrors          => seqErrors,
           wdgErrors          => wdgErrors,
           pulseidCnt         => pulseidCnt
      );

  end block B_PulseIdExtractor;

  sdaOut  <= '0' when (sdaDirLoc = '1' and sdaOutLoc = '0') else '1';

  tcsrACK <= '1';
  tcsrERR <= '0';
end architecture rtl;
