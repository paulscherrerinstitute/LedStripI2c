library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

use     work.MpcI2cSequencerPkg.all;

entity LedStripController is
  generic (
    I2C_FDRVAL_G : std_logic_vector(7 downto 0);
    I2C_ADDR_R_G : std_logic_vector(6 downto 0) := "0000101";
    I2C_ADDR_L_G : std_logic_vector(6 downto 0) := "1101001"
  );
  port (
    clk          : in  std_logic;
    rst          : in  std_logic;

    strobe       : in  std_logic;
    pulseid      : in  std_logic_vector(63 downto 0);
    pwm          : in  std_logic_vector( 7 downto 0) := x"ff"; -- pwm brightness control
    iref         : in  std_logic_vector( 7 downto 0) := x"80"; -- analog brightness control

    sdaDir       : out std_logic;
    sdaOut       : out std_logic;
    sdaInp       : in  std_logic;
    sclOut       : out std_logic;
    sclInp       : in  std_logic
  );
end entity LedStripController;

architecture rtl of LedStripController is

  constant NUM_CTRL_C                : natural := 2;
  constant NUM_LEDS_PER_CONTROLLER_C : natural := 16;
  constant NUM_LEDS_C                : natural := NUM_CTRL_C * NUM_LEDS_PER_CONTROLLER_C;

  subtype  Slv8           is std_logic_vector(7 downto 0);
  subtype  U8             is unsigned        (7 downto 0);
  subtype  PidType        is std_logic_vector(NUM_LEDS_C - 1 downto 0);

  subtype  I2cAddrType    is std_logic_vector(6 downto 0);

  -- addresses in the pca9955B
  -- bit 7 lets address auto-increment
  constant LED_MODE_ADDR_C : U8 := x"82";
  constant LED_IREF_ADDR_C : U8 := x"88";
  constant LED_IPWM_ADDR_C : U8 := x"98";

  constant SHOW_PID_PROG_C : MpcI2cSequenceArray := (
    SEQ_NORM & I2C_ADDR_R_G & "0", -- first item generates a start condition if bus is not owned
    SEQ_NORM & Slv8(LED_MODE_ADDR_C),
    SEQ_NORM & x"00",              -- Four bytes with control data
    SEQ_NORM & x"00",              -- 
    SEQ_NORM & x"00",              -- 
    SEQ_NORM & x"00",              -- 
    SEQ_RSRT & I2C_ADDR_L_G & "0", -- RESTART with second controller
    SEQ_NORM & Slv8(LED_MODE_ADDR_C),
    SEQ_NORM & x"00",              -- Four bytes with control data
    SEQ_NORM & x"00",              -- 
    SEQ_NORM & x"00",              -- 
    SEQ_STOP & x"00"               -- STOP updates BOTH controllers' displays
  );

  constant SEND_BYTE_PROG_C : MpcI2cSequenceArray := (
    SEQ_NORM & I2C_ADDR_R_G & "0", -- i2c address
    SEQ_NORM & Slv8(LED_IREF_ADDR_C),
    SEQ_STOP & x"00"               -- data
  );

  constant PROGS_INIT_C       : MpcI2cSequenceArray := (
    SHOW_PID_PROG_C &
    SEND_BYTE_PROG_C
  );

  constant PROGS_LENGTH_C     : natural := PROGS_INIT_C'length;

  signal   programs           : MpcI2cSequenceArray(PROGS_INIT_C'range) := PROGS_INIT_C;

  subtype  PCType            is natural range 0 to PROGS_LENGTH_C - 1;

  constant SHOW_PID_ADDR_C    : natural := 0;
  constant SEND_BYTE_ADDR_C   : natural := SHOW_PID_PROG_C'length;

  constant CTL_OFF_C          : natural := 2; -- offset of first control byte (LHS controller)
  constant CTL_NBYTES_C       : natural := 4; -- 4 control bytes control 16 LEDs

  constant BRI_I2C_OFF_C      : natural := 0;
  constant BRI_ADR_OFF_C      : natural := 1;
  constant BRI_VAL_OFF_C      : natural := 2;

  constant PWM_INI_C          : Slv8 := x"FF";
  constant IREF_INI_C         : Slv8 := x"80";

  type StateType is (IDLE, SHOW_PID, SET_BRIGHTNESS);

  type RegType is record
    progPtr     :  PCType;
    progValid   :  std_logic;
    state       :  StateType;
    briRight    :  boolean;
    briI2c      :  I2cAddrType;
    pwm         :  Slv8;
    iref        :  Slv8;
    briAddr     :  U8;
    briData     :  Slv8;
  end record RegType;

  constant REG_INIT_C : RegType := (
    progPtr     => SHOW_PID_ADDR_C,
    progValid   => '0',
    state       => IDLE,
    briRight    => true,
    briI2c      => I2C_ADDR_R_G,
    pwm         => PWM_INI_C,
    iref        => IREF_INI_C,
    briAddr     => LED_IREF_ADDR_C,
    briData     => IREF_INI_C
  );

  procedure setPID(
    signal   prg  : inout MpcI2cSequenceArray;
    constant off  : natural;
    constant pid  : PidType;
    constant gray : boolean
  ) is
    variable v : PidType;
  begin
    v := pid;
    if ( gray ) then
      v := (pid xor ('0' & pid(pid'left downto pid'right + 1) ));
    end if;
    -- each bit in the PID vector is represented by two bits in the control words: '0' => "00", '1' => "10"
    for i in 0 to NUM_CTRL_C - 1 loop
      for j in 0 to CTL_NBYTES_C - 1 loop
        for k in 0 to 3 loop
          prg( off + (CTL_OFF_C + CTL_NBYTES_C) * i + j )(2*k + 1) <= v( i * NUM_LEDS_C/NUM_CTRL_C + j*4 + i );
        end loop;
      end loop;
    end loop;
  end procedure setPID;

  procedure nextBriMux(variable rg : inout RegType) is
  begin
    rg.briAddr := rg.briAddr + 1;
    if ( rg.briAddr = LED_IPWM_ADDR_C ) then
      rg.briData := rg.pwm; 
    elsif ( rg.briAddr = LED_IPWM_ADDR_C + NUM_LEDS_PER_CONTROLLER_C ) then
      rg.briAddr := LED_IREF_ADDR_C;
      rg.briData := rg.iref;
      if ( rg.briRight ) then
        rg.briI2c := I2C_ADDR_L_G;
      else
        rg.briI2c := I2C_ADDR_R_G;
      end if;
      rg.briI2c :=  not rg.briI2c;
    end if;
  end procedure nextBriMux;

  procedure setSendByte(
    signal   prg     : inout MpcI2cSequenceArray;
    constant off     : natural;
    constant i2caddr : I2cAddrType;
    constant waddr   : U8;
    constant wdata   : Slv8
  ) is
  begin
    prg( off + BRI_I2C_OFF_C )(7 downto 1) <= i2caddr;
    prg( off + BRI_ADR_OFF_C )(7 downto 0) <= Slv8(waddr);
    prg( off + BRI_VAL_OFF_C )(7 downto 0) <= wdata;
  end procedure setSendByte;

  signal progReady : std_logic;

  signal r         : RegType := REG_INIT_C;
  signal rin       : RegType;

begin

  P_MEM  : process( clk ) is
  begin
    if ( rising_edge( clk ) ) then
      if ( rst = '1' ) then
        programs <= PROGS_INIT_C;
      else
        if ( strobe = '1' and (r.state = IDLE) ) then
          setPID(programs, SHOW_PID_ADDR_C, pulseid(PidType'range), gray => true);
          setSendByte(programs, SEND_BYTE_ADDR_C, r.briI2c, r.briAddr, r.briData);
        end if;
      end if;
    end if;
  end process P_MEM;

  P_COMB : process(r, strobe, pulseid, pwm, iref, progReady) is
    variable v     : RegType;
  begin
    v          := r;
    case ( r.state ) is
      when IDLE =>
        if ( strobe = '1' ) then
          v.state     := SHOW_PID;
          v.progValid := '1';
        end if;

      when SHOW_PID =>
        if ( (r.progValid and progReady) = '1' ) then
          v.state   := SET_BRIGHTNESS;
          v.progPtr := SEND_BYTE_ADDR_C;
        end if;

      when SET_BRIGHTNESS =>
        if ( (r.progValid and progReady) = '1' ) then
          v.state     := IDLE;
          v.progPtr   := SHOW_PID_ADDR_C;
          v.progValid := '0';
          nextBriMux( v );
        end if;

    end case;
    rin        <= v;
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

  U_Controller : entity work.MpcI2cSequencer
    generic map (
      MEM_DEPTH_G   => PROGS_LENGTH_C,
      I2C_FDRVAL_G  => I2C_FDRVAL_G
    )
    port map (
      clk           => clk,
      rst           => rst,

      memory        => programs,
      memPtr        => r.progPtr,
      memPtrValid   => r.progValid,
      memPtrReady   => progReady,

      sdaDir        => sdaDir,
      sdaOut        => sdaOut,
      sdaInp        => sdaInp,
      sclOut        => sclOut,
      sclInp        => sclInp
    );
 
end architecture rtl;
