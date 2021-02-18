library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.Evr320StreamPkg.all;
use work.MpcI2cSequencerPkg.all;
use work.LedStripWrapperPkg.all;

entity LedStripTmemWrapper is
  generic (
    -- tmem clock frequence [Hz]
    TMEM_CLOCK_FRQ_G      : real;
    -- default SCL frequency [Hz]; may change at run-time
    DFLT_I2C_SCL_FRQ_G    : real                          := 400.0E3;
    -- offset in evr stream
    PULSEID_OFFSET_G      : natural                       := 52;
    -- length in octets
    PULSEID_LENGTH_G      : positive                      :=  8;
    PULSEID_BIGEND_G      : boolean                       := false;
    -- tmem and evr clocks are asynchronous
    ASYNC_CLOCKS_G        : boolean                       := true;
    -- I2C Address of RHS PCA9955B
    I2C_ADDR_R_G          : std_logic_vector(6 downto 0)  := "0000101";
    -- I2C Address of LHS PCA9955B
    I2C_ADDR_L_G          : std_logic_vector(6 downto 0)  := "1101001";
    -- Synchronizer stages for reading scalInp/sdaInp
    I2C_SYNC_STAGES_G     : natural range 0 to 3          := 3;
    -- For how many (tmem) cycles to debounce sclInp, sdaInp
    I2C_DEBOUNCE_CYCLES_G : natural                       := 10;
    -- V1 has 
    NUM_LEDS_G            : natural range 1 to 32         := 30;
    -- Enable default marker
    DFLT_MARKER_ENABLE_G  : std_logic                     := '1';
    -- Pulse ID watchdog timeout (in ms); if no new pulse ID is
    -- received from the EVR stream within this timeout period
    -- then the 'missing pulseID' counter is incremented.
    -- Setting this to 0.0 disables the watchdog.
    PULSEID_WDOG_PER_MS_G : real                          := 12.0;
    -- Version (optional git hash)
    VERSION_G             : std_logic_vector(27 downto 0) := (others => '0');
    -- left-most bit of TMEM address
    TMEM_ADDR_MSBIT_G     : natural                       := 23
  );
  port (
    -- TMEM clock domain
    tmemCLK      : in  std_logic;
    tmemRST      : in  std_logic;

    tmem_IF_ENA  : in  std_logic;
    tmem_IF_ADD  : in  std_logic_vector(TMEM_ADDR_MSBIT_G downto 3);
    tmem_IF_DATW : in  std_logic_vector(63 downto 0);
    tmem_IF_WE   : in  std_logic_vector( 7 downto 0);
    tmem_IF_DATR : out std_logic_vector(63 downto 0);
    tmem_IF_BUSY : out std_logic;
    tmem_IF_PIPE : out std_logic_vector( 1 downto 0);

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
end entity LedStripTmemWrapper;

architecture rtl of LedStripTmemWrapper is

  constant VERSION_C         : std_logic_vector(31 downto 0) := (VERSION_G & REG_VERSION_C);
  constant PULSEID_WDOG_P_C  : natural                       := getWdogCount(TMEM_CLOCK_FRQ_G, PULSEID_WDOG_PER_MS_G);
  constant FDRVAL_C          : std_logic_vector(7 downto 0)  := getFDRVal(TMEM_CLOCK_FRQ_G, DFLT_I2C_SCL_FRQ_G);

  constant MARK_DFLT_C       : std_logic_vector(31 downto 0) := setMark(NUM_LEDS_G);

  constant CR_DFLT_C         : std_logic_vector( 3 downto 0) := (
    CR_RESET_I_C   => '0',
    CR_BIN_ENC_I_C => '0',
    CR_SHFT_EN_I_C => DFLT_MARKER_ENABLE_G,
    others         => '0'
  );

  constant REG_INIT_C : LedWrapperRegType := (
    mark                     => MARK_DFLT_C,
    fdr                      => FDRVAL_C,
    pwm                      => PWM_DFLT_C,
    iref                     => IREF_DFLT_C,
    trgMux                   => (others => '0'),
    cr                       => CR_DFLT_C
  );

  signal r                   : LedWrapperRegType := REG_INIT_C;

  signal pulseid             : std_logic_vector(63 downto 0);
  signal pulseidValid        : std_logic;
  signal pulseid_o           : std_logic_vector(63 downto 0);

  signal cr32Rbk             : std_logic_vector(31 downto 0);

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

  signal wordAddr            : unsigned(3 + TCSR_LD_NUM_REGS_C - 1 - 1 downto 3);

  signal ledCtrlRst          : std_logic;

begin

  wordAddr   <= unsigned(tmem_IF_ADD(wordAddr'range));

  ledCtrlRst <= (   r.cr( CR_RESET_I_C   ) or tmemRST );

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

  P_TMEM_RW : process ( tmemCLK ) is
  begin
    if ( rising_edge( tmemCLK ) ) then
      if ( tmemRST = '1' ) then
        r            <= REG_INIT_C;
        tmem_IF_DATR <= (others => '0');
      else

        -- READOUT
        if    (wordAddr = TCSR_REGVER_IDX_C/2) then
          tmem_IF_DATR <= cr32Rbk   & VERSION_C;
        elsif (wordAddr = TCSR_MARK_IDX_C/2  ) then
          tmem_IF_DATR <= malErrors & r.mark;
        elsif (wordAddr = TCSR_NAKERR_IDX_C/2) then
          tmem_IF_DATR <= rbkErrors & nakErrors;
        elsif (wordAddr = TCSR_SEQERR_IDX_C/2) then
          tmem_IF_DATR <= wdgErrors & seqErrors;
        elsif (wordAddr = TCSR_PIDCNT_IDX_C/2) then
          tmem_IF_DATR <= synErrors & pulseidCnt;
        else
          tmem_IF_DATR <= x"0000_0000" & dbg;
        end if;

        -- WRITE
        if ( tmem_IF_ENA = '1' ) then
          if ( wordAddr = TCSR_REGVER_IDX_C/2 ) then
            if ( tmem_IF_WE(7) = '1' ) then
              r.fdr    <= tmem_IF_DATW(63 downto 56);
            end if;
            if ( tmem_IF_WE(6) = '1' ) then
              r.trgMux <= tmem_IF_DATW(55 downto 52);
              r.cr     <= tmem_IF_DATW(51 downto 48);
            end if;
            if ( tmem_IF_WE(5) = '1' ) then
              r.pwm    <= tmem_IF_DATW(47 downto 40);
            end if;
            if ( tmem_IF_WE(4) = '1' ) then
              r.iref   <= tmem_IF_DATW(39 downto 32);
            end if;
          elsif ( wordAddr = TCSR_MARK_IDX_C/2 ) then
            for i in 0 to 3 loop
              if ( tmem_IF_WE(i) = '1' ) then
                r.mark(8*i + 7 downto 8*i) <= tmem_IF_DATW(8*i + 7 downto 8*i);
              end if;
            end loop;
          end if;
        end if;
      end if;
    end if;
  end process P_TMEM_RW;

  U_LedStrip : entity work.LedStripController
    generic map (
      I2C_FDRVAL_G          => FDRVAL_C,
      I2C_ADDR_R_G          => I2C_ADDR_R_G,
      I2C_ADDR_L_G          => I2C_ADDR_L_G,
      DBNCE_SYNC_G          => I2C_SYNC_STAGES_G,
      DBNCE_CYCL_G          => I2C_DEBOUNCE_CYCLES_G
    )
    port map (
      clk                   => tmemCLK,
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

           oclk               => tmemCLK,
           orst               => tmemRST,
           pulseid            => pulseid,
           pulseidStrobe      => pulseidValid,
           synErrors          => synErrors,
           seqErrors          => seqErrors,
           wdgErrors          => wdgErrors,
           pulseidCnt         => pulseidCnt
      );

  end block B_PulseIdExtractor;

  sdaOut       <= '0' when (sdaDirLoc = '1' and sdaOutLoc = '0') else '1';
  tmem_IF_BUSY <= '0';
  tmem_IF_PIPE <= "00";
end architecture rtl;
