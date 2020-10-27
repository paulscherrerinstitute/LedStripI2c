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
    progError     : out std_logic;

    readData      : out std_logic_vector( 7 downto 0);
    readValid     : out std_logic;

    fdrRegValid   : in  std_logic                     := '0';
    fdrRegData    : in  std_logic_vector( 7 downto 0) := I2C_FDRVAL_G;

    malErrors     : out std_logic_vector(31 downto 0);
    nakErrors     : out std_logic_vector(31 downto 0);

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

  constant CR_MEN_I  : natural                        := 7;
  constant CR_MIEN_I : natural                        := 6;
  constant CR_MSTA_I : natural                        := 5;
  constant CR_MTX_I  : natural                        := 4;
  constant CR_TXAK_I : natural                        := 3;
  constant CR_RSTA_I : natural                        := 2;

  constant CR_MEN   : std_logic_vector( 7 downto  0) := (CR_MEN_I  => '1', others => '0');
  constant CR_MIEN  : std_logic_vector( 7 downto  0) := (CR_MIEN_I => '1', others => '0');
  constant CR_MSTA  : std_logic_vector( 7 downto  0) := (CR_MSTA_I => '1', others => '0');
  constant CR_MTX   : std_logic_vector( 7 downto  0) := (CR_MTX_I  => '1', others => '0');
  constant CR_TXAK  : std_logic_vector( 7 downto  0) := (CR_TXAK_I => '1', others => '0');
  constant CR_RSTA  : std_logic_vector( 7 downto  0) := (CR_RSTA_I => '1', others => '0');

  constant CR_INI   : std_logic_vector( 7 downto  0) := CR_MEN or CR_MIEN;

  type StateType is (INIT, IDLE, RCMD, SNDW, RCVW, READ, WIRQ, WICL, GSTP, WSTP);

  constant STACK_DEPTH_C : natural := 2;

  subtype StackPtrType is natural range 0 to STACK_DEPTH_C - 1;

  type StateStackType is array(StackPtrType) of StateType;

  type WEArray   is array(natural range 0 to 2) of std_logic_vector(3 downto 0);

  type RegType is record
    cr         : std_logic_vector(7 downto 0);
    fdr        : std_logic_vector(7 downto 0);
    fdrDes     : std_logic_vector(7 downto 0);
    sendAddr   : boolean;
    rcvCnt     : unsigned(7 downto 0);
    memPtr     : PtrType;
    progError  : std_logic;
    state      : StateStackType;
    stateSP    : StackPtrType;
    ctlWE      : WEArray;
    ctlWStrb   : std_logic;
    ctlWData   : std_logic_vector(7 downto 0);
    ctlRSel    : std_logic_vector(1 downto 0);
    ctlRStrb   : std_logic;
    readData   : std_logic_vector(7 downto 0);
    readValid  : std_logic;
    mal        : std_logic;
    malErrors  : unsigned(31 downto 0);
    nakErrors  : unsigned(31 downto 0);
    sending    : boolean;
  end record RegType;

  constant REG_INIT_C : RegType := (
    cr         => CR_INI,
    fdr        => I2C_FDRVAL_G,
    fdrDes     => I2C_FDRVAL_G,
    sendAddr   => false,
    rcvCnt     => (others => '0'),
    memPtr     =>  0,
    progError  =>  '0',
    state      => (others => INIT),
    stateSP    =>  0,
    ctlWE      => (others => (others => '0')),
    ctlWStrb   => '0',
    ctlWData   => (others => '0'),
    ctlRSel    => (others => '0'),
    ctlRStrb   => '0',
    readData   => (others => '0'),
    readValid  => '0',
    mal        => '0',
    malErrors  => (others => '0'),
    nakErrors  => (others => '0'),
    sending    => false
  );

  signal r   : RegType := REG_INIT_C;
  signal rin : RegType;

  signal irq : std_logic;
  signal bsy : std_logic;
  signal mal : std_logic;
  signal nak : std_logic;

  -- readout port
  signal memData : MpcI2cSequenceDataType := (others => '0');
  signal i2cDATR : std_logic_vector(31 downto 0);

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

  constant FDR_REG       : natural := 1;
  constant CR_REG        : natural := 3;
  constant ST_REG        : natural := 4;
  constant DATA_REG      : natural := 8;

  constant ST_NAK_I      : natural := 0;
  constant ST_MIF_I      : natural := 1;
  constant ST_MAL_I      : natural := 4;

  constant ST_MIF        : std_logic_vector(7 downto 0) := (ST_MIF_I => '1', others => '0');
  constant ST_MAL        : std_logic_vector(7 downto 0) := (ST_MAL_I => '1', others => '0');

  procedure writeByte(
    variable rg    : inout RegType;
    constant baddr : natural range 0 to 11;
    constant data  : std_logic_vector(7 downto 0)
  ) is
  begin
    rg.ctlWE                       := (others => (others => '0'));
    rg.ctlWE(baddr/4)(baddr mod 4) := '1';
    rg.ctlWStrb                    := '1';
    rg.ctlWData                    := data;      
  end procedure writeByte;

  procedure readWord(
    variable rg     : inout RegType;
    constant baddr  : natural range 0 to 11;
    constant strobe : std_logic
  ) is
  begin
    rg.ctlRSel  := std_logic_vector( to_unsigned( baddr/4, rg.ctlRSel'length ) );
    rg.ctlRStrb := strobe;
  end procedure readWord;

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

  P_COMB : process( r, memPtr, memPtrValid, memData, irq, bsy, mal, fdrRegData, fdrRegValid, i2cDATR, nak ) is
    variable v     : RegType;
  begin
    v           := r;
    v.ctlWStrb  := '0';
    v.ctlRStrb  := '0';
    v.readValid := '0';

    if ( fdrRegValid = '1' ) then
      v.fdrDes := fdrRegData;
    end if;

    case ( getState(r) ) is

      when INIT   =>
        writeByte( v, CR_REG, r.cr );
        setState( v, IDLE );

      when IDLE   =>
        if ( memPtrValid = '1' ) then
          v.memPtr    := memPtr;
          pushState(v, SNDW, RCMD);
          v.progError := '0';
        end if;

      when RCMD   =>
        v.sendAddr  := true;
        popState(v);

      when SNDW   =>
        v.cr      := (r.cr or CR_MSTA or CR_MTX);
        v.sending := true;
        if ( (memData(MPCI2C_LAST_C) = '0') and (memData(MPCI2C_CTRL_C) = '1') ) then
            -- RESTART
            v.cr       := v.cr or CR_RSTA;
            v.sendAddr := true;
        end if;
        if ( v.sendAddr ) then
            v.cr(CR_MTX_I) := not memData(MPCI2C_RDNW_C);
        end if;
        if ( v.cr /= r.cr ) then
          writeByte( v, CR_REG, v.cr );
          -- during the next cycle v.cr matches oldCR
        else
          v.cr       := r.cr and not CR_RSTA; -- self-clearing;
          v.sendAddr := false;
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
            if ( r.sendAddr and (memData(MPCI2C_RDNW_C) = '1') ) then
              pushState( v, RCVW, WIRQ );
            else
              pushState( v, SNDW, WIRQ );
            end if;
          end if; 
        end if;

      when RCVW   =>
        v.sending := false;
        -- is this the last transfer and we shouldnt ACK
        if ( r.rcvCnt = unsigned(memData(7 downto 0)) ) then
          -- don't ACK last byte UNLESS 'LAST' flag is clear and CTRL flag is set
          v.cr(CR_TXAK_I) := memData(MPCI2C_LAST_C) or not memData(MPCI2C_CTRL_C);
        else
          v.cr(CR_TXAK_I) := '0';
        end if;
        if ( v.cr /= r.cr ) then
          writeByte( v, CR_REG, v.cr );
          -- during the next cycle v.cr matches oldCR
        else
          readWord ( v, DATA_REG, '1' );
          -- don't change RDSEL after this -- we read back in READ state
          pushState( v, READ, WIRQ );
        end if;

      when READ   =>
        v.readData  := i2cDATR(7 downto 0);
        v.readValid := '1';
        if ( r.rcvCnt = unsigned(memData(7 downto 0)) ) then
          if ( (memData(MPCI2C_LAST_C) = '1') and (memData(MPCI2C_CTRL_C) = '1') ) then
            setState(v, GSTP);
          else
            setState(v, IDLE);
          end if;
        else
          v.rcvCnt := r.rcvCnt + 1;
          setState(v, RCVW);
        end if;

      when WIRQ   =>
        if ( irq = '1' ) then
          -- clear interrupt condition
          v.mal := mal;
          writeByte( v, ST_REG, (x"FF" and not (ST_MIF or ST_MAL)) );
          setState( v, WICL );
        end if;

      -- takes a few cycle to clear an interrupt, apparently
      when WICL  =>
        if ( irq = '0' ) then
          popState( v );
          if ( r.mal = '1' ) then
            -- arbitration was lost; must clear CR_MSTA before
            -- the mpc controller can proceed; We skip to GSTP
            -- which will do exactly that...
            v.malErrors := r.malErrors + 1;
            v.progError := '1';
            v.mal       := '0';
            setState( v, GSTP );
          end if;
          if ( r.sending and (nak ='1') ) then
            v.nakErrors := r.nakErrors + 1;
            v.progError := '1';
            setState( v, GSTP );
          end if;
          v.sending := false;
        end if;

      when GSTP   =>
        v.cr := CR_INI;
        writeByte( v, CR_REG, v.cr );
        setState( v, WSTP );

      when WSTP   =>
        if ( bsy = '0' ) then
          if ( r.fdrDes /= r.fdr ) then
            v.fdr := r.fdrDes;
            writeByte( v, FDR_REG, r.fdrDes );
          end if;
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
      i2creg_RDSTRB    => r.ctlRStrb,
      i2creg_RDSEL     => r.ctlRSel,
      i2creg_DATR      => i2cDATR,

      i2cctl_IRQOK     => irq,
      i2cctl_BUSY      => bsy,
      i2cctl_ERROR     => mal,
      i2cctl_RXNAK     => nak,

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

  malErrors              <= std_logic_vector(r.malErrors);
  nakErrors              <= std_logic_vector(r.nakErrors);

  readData               <= r.readData;
  readValid              <= r.readValid;
  progError              <= r.progError;

end architecture rtl;
