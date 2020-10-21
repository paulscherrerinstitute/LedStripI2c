library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

use     work.MpcI2cSequencerPkg.all;

entity MpcI2cSequencer is
  generic (
    MEM_DEPTH_G   : positive;
    I2C_FDRVAL_G  : std_logic_vector(7 downto 0)
  );
  port (
    clk           : in  std_logic;
    rst           : in  std_logic;

    memory        : in  MpcI2cSequenceArray(0 to MEM_DEPTH_G - 1);
    memPtr        : in  natural  range 0 to MEM_DEPTH_G - 1;
    memPtrValid   : in  std_logic;
    memPtrReady   : out std_logic;

    sdaDir        : out std_logic;
    sdaOut        : out std_logic;
    sdaInp        : in  std_logic;
    sclOut        : out std_logic;
    sclInp        : in  std_logic;

    dbgState      : out std_logic_vector(15 downto 0)
  );
end entity MpcI2cSequencer;

architecture rtl of MpcI2cSequencer is

  subtype PtrType is natural range 0 to MEM_DEPTH_G - 1;

  constant CR_MEN   : std_logic_vector( 7 downto  0) := x"80";
  constant CR_MIEN  : std_logic_vector( 7 downto  0) := x"40";
  constant CR_MSTA  : std_logic_vector( 7 downto  0) := x"20";
  constant CR_MTX   : std_logic_vector( 7 downto  0) := x"10";
  constant CR_TXAK  : std_logic_vector( 7 downto  0) := x"08";
  constant CR_RSTA  : std_logic_vector( 7 downto  0) := x"04";

  constant CR_INI   : std_logic_vector( 7 downto  0) := CR_MEN or CR_MIEN;

  type StateType is (INIT, IDLE, RCMD, SNDW, WIRQ, WICL, GSTP, WSTP);

  constant STACK_DEPTH_C : natural := 2;

  subtype StackPtrType is natural range 0 to STACK_DEPTH_C - 1;

  type StateStackType is array(StackPtrType) of StateType;

  type WEArray   is array(natural range 0 to 2) of std_logic_vector(3 downto 0);

  type RegType is record
    cr         : std_logic_vector(7 downto 0);
    memPtr     : PtrType;
    state      : StateStackType;
    stateSP    : StackPtrType;
    ctlWE      : WEArray;
    ctlWStrb   : std_logic;
    ctlWData   : std_logic_vector(7 downto 0);
  end record RegType;

  constant REG_INIT_C : RegType := (
    cr         => CR_INI,
    memPtr     =>  0,
    state      => (others => INIT),
    stateSP    =>  0,
    ctlWE      => (others => (others => '0')),
    ctlWStrb   => '0',
    ctlWData   => (others => '0')
  );

  signal r   : RegType := REG_INIT_C;
  signal rin : RegType;

  signal irq : std_logic;
  signal bsy : std_logic;

  -- readout port
  signal memData : MpcI2cSequenceDataType := (others => '0');

  function getState(constant rg : RegType) return StateType is
  begin
    return rg.state(rg.stateSP);
  end function getState;

  procedure setState(variable rg : inout RegType; constant s: StateType) is
  begin
    rg.state(rg.stateSP) := s;
  end procedure setState;

  procedure pushState(variable rg : inout RegType; constant rs,s: StateType) is
  begin
    rg.state(rg.stateSP) := rs;
    rg.stateSP           := rg.stateSP + 1;
    setState( rg, s );
  end procedure pushState;

  procedure popState(variable rg : inout RegType) is
  begin
    rg.stateSP := rg.stateSP - 1;
  end procedure popState;

  constant CR_REG        : natural := 3;
  constant ST_REG        : natural := 4;
  constant DATA_REG      : natural := 8;

  constant ST_MIF        : std_logic_vector(7 downto 0) := x"02";

  procedure writeByte(
    variable rg    : inout RegType;
    constant baddr : natural range 0 to 11;
    constant data : std_logic_vector(7 downto 0)
  ) is
  begin
    rg.ctlWE                       := (others => (others => '0'));
    rg.ctlWE(baddr/4)(baddr mod 4) := '1';
    rg.ctlWStrb                    := '1';
    rg.ctlWData                    := data;      
  end procedure writeByte;

  signal currentState : StateType;

begin

  P_READ : process( clk ) is
  begin
    if ( rising_edge( clk ) ) then
      if ( rst = '1' ) then
        memData <= (others => '0');
      else
        memData <= memory(r.memPtr);
      end if;
    end if;
  end process P_READ;

  P_COMB : process( r, memPtr, memPtrValid, memData, irq, bsy ) is
    variable v     : RegType;
  begin
    v          := r;
    v.ctlWStrb := '0';
    case ( getState(r) ) is

      when INIT   =>
        writeByte( v, CR_REG, r.cr );
        setState( v, IDLE );

      when IDLE   =>
        if ( memPtrValid = '1' ) then
          v.memPtr := memPtr;
          pushState(v, SNDW, RCMD);
        end if;

      when RCMD   =>
        popState(v);

      when SNDW   =>
        v.cr  := r.cr or CR_MSTA or CR_MTX;
        if ( (memData(MPCI2C_LAST_C) = '0') and (memData(MPCI2C_CTRL_C) = '1') ) then
            -- RESTART
            v.cr := v.cr or CR_RSTA;
        end if;
        if ( v.cr /= r.cr ) then
          writeByte( v, CR_REG, v.cr );
          -- during the next cycle v.cr matches oldCR
        else
          v.cr := r.cr and not CR_RSTA; -- self-clearing;
          writeByte( v, DATA_REG, memData(7 downto 0) );
          if ( memData(MPCI2C_LAST_C) = '1' ) then
            if ( memData(MPCI2C_CTRL_C) = '1' ) then
               -- generate STOP
              pushState( v, GSTP, WIRQ );
            else
              pushState( v, IDLE, WIRQ );
            end if;
          else
            v.memPtr := r.memPtr + 1;
            pushState( v, SNDW, WIRQ );
          end if; 
        end if;

      when WIRQ   =>
        if ( irq = '1' ) then
          -- clear interrupt condition
          writeByte( v, ST_REG, (x"FF" and not ST_MIF) );
          setState( v, WICL );
        end if;

      -- takes a few cycle to clear an interrupt, apparently
      when WICL  =>
        if ( irq = '0' ) then
          popState( v );
        end if;

      when GSTP   =>
        v.cr := CR_INI;
        writeByte( v, CR_REG, v.cr );
        setState( v, WSTP );

      when WSTP   =>
        if ( bsy = '0' ) then
          setState(v, IDLE);
        end if;


      when others => setState(v, INIT);
    end case;

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

  U_CTL : entity work.ioxos_mpc_master_i2c_ctl
   generic map (
      enable_ila       => 0,
      INITIAL_FDR_G    => I2C_FDRVAL_G
    )
    port map (
      elb_RESET        => rst,
      elb_CLK          => clk,

      i2creg_WRSTRB    => r.ctlWStrb,
      i2creg_WE0       => r.ctlWE(0),
      i2creg_WE1       => r.ctlWE(1),
      i2creg_WE2       => r.ctlWE(2),
      i2creg_DATW      => r.ctlWData,
      i2creg_RDSTRB    => '0',
      i2creg_RDSEL     => "00",
      i2creg_DATR      => open,

      i2cctl_IRQOK     => irq,
      i2cctl_BUSY      => bsy,

      int_I2C_DIR      => sdaDir,
      int_I2C_SDAO     => sdaOut,
      int_I2C_SDC      => sclOut,
      int_I2C_SDCI     => sclInp,
      int_I2C_SDAI     => sdaInp,

      dbg_STATE        => dbgState(8 downto 0)
    );

  dbgState(11)           <= sdaInp;
  dbgState(10)           <= sclInp;
  dbgState( 9)           <= '0';
  dbgState(15 downto 12) <= std_logic_vector( to_unsigned( StateType'pos(getState(r)), 4 ) );

  currentState           <= getState(r);

  memPtrReady            <= '1' when currentState = IDLE else '0';


end architecture rtl;
