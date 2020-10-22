-------------------------------------------------------------------------
--
-- Project      :   IFC_XXXX (IFC_1210, IFC_1211, IFC_1410)
-- File name    :   ioxos_mpc_master_i2c_ctl.vhd
-- Title        :   MPC-compatible master I2C controller
--
-- Author       :   Ralph Hoffmann
--
-- ----------------------------------------------------------------------
-- >>>>>>>>>>>>>>>>>>>>>>> COPYRIGHT NOTICE <<<<<<<<<<<<<<<<<<<<<<<<<<<<
-- ----------------------------------------------------------------------
-- This file is owned and controlled by IOxOS Technologies SA and must be
-- used solely for design, simulation, implementation and creation of
-- design files limited to IOxOS Technologies SA.
-- Use with non-IOxOS Technologies SA design or technologies is expres-
-- sly prohibited.
-------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.ioxos_mpc_master_i2c_ctl_pkg.all;

entity ioxos_mpc_master_i2c_ctl is
  generic (
    enable_ila    : in integer;
    INITIAL_FDR_G : std_logic_vector(7 downto 0) := x"00";
    FIXED_FDR_G   : boolean := false);
  port (
    elb_RESET     : in  std_logic;
    elb_CLK       : in  std_logic;
    -----------------------------------------------------------------------------
    -- IO Bus Register Interface
    -----------------------------------------------------------------------------
    i2creg_WRSTRB : in  std_logic;
    i2creg_WE0    : in  std_logic_vector(3 downto 0);
    i2creg_WE1    : in  std_logic_vector(3 downto 0);
    i2creg_WE2    : in  std_logic_vector(3 downto 0);
    i2creg_DATW   : in  std_logic_vector(7 downto 0);
    i2creg_RDSTRB : in  std_logic;
    i2creg_RDSEL  : in  std_logic_vector(1 downto 0);
    i2creg_DATR   : out std_logic_vector(31 downto 0);
    -----------------------------------------------------------------------------
    -- Status & Debugging
    -----------------------------------------------------------------------------
    i2cctl_ERROR  : out std_logic := '0';
    i2cctl_BUSY   : out std_logic := '0';
    i2cctl_IRQOK  : out std_logic := '0';
    i2cctl_IRQERR : out std_logic := '0';
    -----------------------------------------------------------------------------
    -- I2C Unified Master Port Interface
    -----------------------------------------------------------------------------
    int_I2C_DIR   : out std_logic;
    int_I2C_SDAO  : out std_logic;
    int_I2C_SDC   : out std_logic;
    int_I2C_SDCI  : in  std_logic;
    int_I2C_SDAI  : in  std_logic;

    dbg_STATE     : out std_logic_vector(8 downto 0));
end entity ioxos_mpc_master_i2c_ctl;


architecture rtl of ioxos_mpc_master_i2c_ctl is

  -----------------------------------------------------------------------------
  -- references
  -----------------------------------------------------------------------------
  -----------------------------------------------------------------------------

  -----------------------------------------------------------------------------
  -- MPC-like I2C registers
  -----------------------------------------------------------------------------
  --
  -- mapping into legacy registers
  --
  --    byte                _3        _2        _1         _0
  --    bits               [31:24]   [23:16]   [15:8]    [7:0]
  --
  --                      ---------------------------------------
  -- legacy register 0   |     cr  |  dfsrr  |    fdr  |    adr  |
  -- (control)            ---------------------------------------
  --
  --                      ---------------------------------------
  -- legacy register 1   |    N/U  |    N/U  |    esr  |     sr  |
  -- (status)             ---------------------------------------
  --
  --                      ---------------------------------------
  -- legacy register 2   |    N/U  |    N/U  |    N/U  |     dr  |
  -- (data)               ---------------------------------------
  --
  --                      ---------------------------------------
  -- legacy register 3   |    day  |  month  |   year  |  index  |
  -- (revision)           ---------------------------------------
  --
  -- adr   = slave address (not used)
  -- fdr   = frequency divider rate
  -- dfsrr = digital filter sampling rate register (not used)
  -- cr    = control register
  -- sr    = status register
  -- esr   = extended status register (IOxOS-specific)
  -- dr    = data register
  -- N/U   = Not Used
  --
  -----------------------------------------------------------------------------

  -- initial registers values
  constant INITIAL_MPC_REG_I2CADR       : std_logic_vector(7 downto 0) := "00000000";
  constant INITIAL_MPC_REG_I2CFDR       : std_logic_vector(7 downto 0) := INITIAL_FDR_G;
  constant INITIAL_MPC_REG_I2CCR        : std_logic_vector(7 downto 0) := "00000000";
  constant INITIAL_MPC_REG_I2CSR        : std_logic_vector(7 downto 0) := "00000000";
  constant INITIAL_MPC_REG_I2CDR        : std_logic_vector(7 downto 0) := "00000000";
  constant INITIAL_MPC_REG_I2CDFSRR     : std_logic_vector(7 downto 0) := "00000000";

  -- write access
  signal mpc_reg_i2cadr_w               : std_logic_vector(7 downto 0);
  signal mpc_reg_i2cfdr_w               : std_logic_vector(7 downto 0) := INITIAL_MPC_REG_I2CFDR;
  signal mpc_reg_i2ccr_w                : std_logic_vector(7 downto 0);
  signal mpc_reg_i2cesr_w               : std_logic_vector(23 downto 0);
  signal mpc_reg_i2csr_w                : std_logic_vector(7 downto 0);
  signal mpc_reg_i2cdr_w                : std_logic_vector(7 downto 0);
  signal mpc_reg_i2cdfsrr_w             : std_logic_vector(7 downto 0);

  -- read access
  signal mpc_reg_i2cadr_r               : std_logic_vector(7 downto 0);
  signal mpc_reg_i2cfdr_r               : std_logic_vector(7 downto 0);
  signal mpc_reg_i2ccr_r                : std_logic_vector(7 downto 0);
  signal mpc_reg_i2cesr_r               : std_logic_vector(23 downto 0);
  signal mpc_reg_i2csr_r                : std_logic_vector(7 downto 0);
  signal mpc_reg_i2cdr_r                : std_logic_vector(7 downto 0);
  signal mpc_reg_i2cdfsrr_r             : std_logic_vector(7 downto 0);

  signal local_i2creg_DATR              : std_logic_vector(31 downto 0) := (others => '0');

  -----------------------------------------------------------------------------
  -- frequency divider register
  -----------------------------------------------------------------------------

  alias  i2c_fdr                        : std_logic_vector(7 downto 0) is mpc_reg_i2cfdr_w(7 downto 0);

  -----------------------------------------------------------------------------
  -- control register
  -----------------------------------------------------------------------------

  alias  i2c_cr_men_w                   : std_logic is mpc_reg_i2ccr_w(7);
  alias  i2c_cr_mien_w                  : std_logic is mpc_reg_i2ccr_w(6);
  alias  i2c_cr_msta_w                  : std_logic is mpc_reg_i2ccr_w(5);
  alias  i2c_cr_mtx_w                   : std_logic is mpc_reg_i2ccr_w(4);
  alias  i2c_cr_txak_w                  : std_logic is mpc_reg_i2ccr_w(3);
  alias  i2c_cr_rsta_w                  : std_logic is mpc_reg_i2ccr_w(2);
  alias  i2c_cr_rsvd_w                  : std_logic is mpc_reg_i2ccr_w(1);
  alias  i2c_cr_bcst_w                  : std_logic is mpc_reg_i2ccr_w(0);

  signal clear_i2c_cr_rsta_w            : std_logic := '0';

  alias  i2c_cr_men_r                   : std_logic is mpc_reg_i2ccr_r(7);
  alias  i2c_cr_mien_r                  : std_logic is mpc_reg_i2ccr_r(6);
  alias  i2c_cr_msta_r                  : std_logic is mpc_reg_i2ccr_r(5);
  alias  i2c_cr_mtx_r                   : std_logic is mpc_reg_i2ccr_r(4);
  alias  i2c_cr_txak_r                  : std_logic is mpc_reg_i2ccr_r(3);
  alias  i2c_cr_rsta_r                  : std_logic is mpc_reg_i2ccr_r(2);
  alias  i2c_cr_rsvd_r                  : std_logic is mpc_reg_i2ccr_r(1);
  alias  i2c_cr_bcst_r                  : std_logic is mpc_reg_i2ccr_r(0);

  -----------------------------------------------------------------------------
  -- status register
  -----------------------------------------------------------------------------

  alias  i2c_sr_mcf_r                   : std_logic is mpc_reg_i2csr_r(7);
  alias  i2c_sr_maas_r                  : std_logic is mpc_reg_i2csr_r(6);
  alias  i2c_sr_mbb_r                   : std_logic is mpc_reg_i2csr_r(5);
  alias  i2c_sr_mal_r                   : std_logic is mpc_reg_i2csr_r(4);
  alias  i2c_sr_bcstm_r                 : std_logic is mpc_reg_i2csr_r(3);
  alias  i2c_sr_srw_r                   : std_logic is mpc_reg_i2csr_r(2);
  alias  i2c_sr_mif_r                   : std_logic is mpc_reg_i2csr_r(1);
  alias  i2c_sr_rxak_r                  : std_logic is mpc_reg_i2csr_r(0);

  alias  i2c_sr_mal_w                   : std_logic is mpc_reg_i2csr_w(4);
  signal i2c_sr_mal_w_event             : std_logic := '0';
  signal clear_i2c_sr_mal_w_event       : std_logic := '0';

  alias  i2c_sr_mif_w                   : std_logic is mpc_reg_i2csr_w(1);
  signal i2c_sr_mif_w_event             : std_logic := '0';
  signal clear_i2c_sr_mif_w_event       : std_logic := '0';

  signal current_i2c_sr_mbb             : std_logic := '0';
  signal next_i2c_sr_mbb                : std_logic;

  signal current_i2c_sr_mal_r           : std_logic := '0';
  signal next_i2c_sr_mal_r              : std_logic;

  signal current_i2c_sr_mif_r           : std_logic := '0';
  signal next_i2c_sr_mif_r              : std_logic;

  signal current_i2c_sr_rxak_r          : std_logic := '1';
  signal next_i2c_sr_rxak_r             : std_logic;

  -----------------------------------------------------------------------------
  -- extended status register (IOxOS-specific)
  -----------------------------------------------------------------------------

  alias  i2c_esr_rsvd_r                 : std_logic_vector(15 downto 0) is mpc_reg_i2cesr_r(23 downto 8);
  alias  i2c_esr_mcs_r                  : std_logic_vector(3 downto 0) is mpc_reg_i2cesr_r(7 downto 4);
  alias  i2c_esr_sclo_r                 : std_logic is mpc_reg_i2cesr_r(3);
  alias  i2c_esr_sdao_r                 : std_logic is mpc_reg_i2cesr_r(2);
  alias  i2c_esr_scli_r                 : std_logic is mpc_reg_i2cesr_r(1);
  alias  i2c_esr_sdai_r                 : std_logic is mpc_reg_i2cesr_r(0);

  -----------------------------------------------------------------------------
  -- data register
  -----------------------------------------------------------------------------

  signal current_mpc_reg_i2cdr_r        : std_logic_vector(7 downto 0) := (others => '0');
  signal next_mpc_reg_i2cdr_r           : std_logic_vector(7 downto 0);

  signal mpc_reg_i2cdr_w_event          : std_logic := '0';
  signal mpc_reg_i2cdr_r_event          : std_logic := '0';
  signal clear_mpc_reg_i2cdr_w_event    : std_logic := '0';
  signal clear_mpc_reg_i2cdr_r_event    : std_logic := '0';

  -----------------------------------------------------------------------------
  -- digital filter sampling rate register
  -----------------------------------------------------------------------------

  alias  i2c_dfsr                       : std_logic_vector(5 downto 0) is mpc_reg_i2cdfsrr_w(5 downto 0);

  -----------------------------------------------------------------------------
  -- prescaler
  -----------------------------------------------------------------------------

  --
  -- Conversion table for FDR register value to prescaler initialization
  -- value. As the prescaler counts from N down to -1, the values in the
  -- conversion table take into account this -2 difference.
  --
  -- NOTE: values taken from Freescale reference manual, see table on page 818
  -- in [1]
  --
  -- NOTE: TS: feature addition: if bit 7 is set in the register then 6:0 are
  --           taken as a literal value (the table does not supply small dividers).

  type fdr_reg_to_value_rom_type is array (0 to 63) of unsigned(16 downto 0);

  constant fdr_value_rom                : fdr_reg_to_value_rom_type := (
    to_unsigned(IOXOS_MPC_MASTER_I2C_CTL_FDR_0x00 - 2, 17),
    to_unsigned(IOXOS_MPC_MASTER_I2C_CTL_FDR_0x01 - 2, 17),
    to_unsigned(IOXOS_MPC_MASTER_I2C_CTL_FDR_0x02 - 2, 17),
    to_unsigned(IOXOS_MPC_MASTER_I2C_CTL_FDR_0x03 - 2, 17),
    to_unsigned(IOXOS_MPC_MASTER_I2C_CTL_FDR_0x04 - 2, 17),
    to_unsigned(IOXOS_MPC_MASTER_I2C_CTL_FDR_0x05 - 2, 17),
    to_unsigned(IOXOS_MPC_MASTER_I2C_CTL_FDR_0x06 - 2, 17),
    to_unsigned(IOXOS_MPC_MASTER_I2C_CTL_FDR_0x07 - 2, 17),
    to_unsigned(IOXOS_MPC_MASTER_I2C_CTL_FDR_0x08 - 2, 17),
    to_unsigned(IOXOS_MPC_MASTER_I2C_CTL_FDR_0x09 - 2, 17),
    to_unsigned(IOXOS_MPC_MASTER_I2C_CTL_FDR_0x0A - 2, 17),
    to_unsigned(IOXOS_MPC_MASTER_I2C_CTL_FDR_0x0B - 2, 17),
    to_unsigned(IOXOS_MPC_MASTER_I2C_CTL_FDR_0x0C - 2, 17),
    to_unsigned(IOXOS_MPC_MASTER_I2C_CTL_FDR_0x0D - 2, 17),
    to_unsigned(IOXOS_MPC_MASTER_I2C_CTL_FDR_0x0E - 2, 17),
    to_unsigned(IOXOS_MPC_MASTER_I2C_CTL_FDR_0x0F - 2, 17),
    to_unsigned(IOXOS_MPC_MASTER_I2C_CTL_FDR_0x10 - 2, 17),
    to_unsigned(IOXOS_MPC_MASTER_I2C_CTL_FDR_0x11 - 2, 17),
    to_unsigned(IOXOS_MPC_MASTER_I2C_CTL_FDR_0x12 - 2, 17),
    to_unsigned(IOXOS_MPC_MASTER_I2C_CTL_FDR_0x13 - 2, 17),
    to_unsigned(IOXOS_MPC_MASTER_I2C_CTL_FDR_0x14 - 2, 17),
    to_unsigned(IOXOS_MPC_MASTER_I2C_CTL_FDR_0x15 - 2, 17),
    to_unsigned(IOXOS_MPC_MASTER_I2C_CTL_FDR_0x16 - 2, 17),
    to_unsigned(IOXOS_MPC_MASTER_I2C_CTL_FDR_0x17 - 2, 17),
    to_unsigned(IOXOS_MPC_MASTER_I2C_CTL_FDR_0x18 - 2, 17),
    to_unsigned(IOXOS_MPC_MASTER_I2C_CTL_FDR_0x19 - 2, 17),
    to_unsigned(IOXOS_MPC_MASTER_I2C_CTL_FDR_0x1A - 2, 17),
    to_unsigned(IOXOS_MPC_MASTER_I2C_CTL_FDR_0x1B - 2, 17),
    to_unsigned(IOXOS_MPC_MASTER_I2C_CTL_FDR_0x1C - 2, 17),
    to_unsigned(IOXOS_MPC_MASTER_I2C_CTL_FDR_0x1D - 2, 17),
    to_unsigned(IOXOS_MPC_MASTER_I2C_CTL_FDR_0x1E - 2, 17),
    to_unsigned(IOXOS_MPC_MASTER_I2C_CTL_FDR_0x1F - 2, 17),
    to_unsigned(IOXOS_MPC_MASTER_I2C_CTL_FDR_0x20 - 2, 17),
    to_unsigned(IOXOS_MPC_MASTER_I2C_CTL_FDR_0x21 - 2, 17),
    to_unsigned(IOXOS_MPC_MASTER_I2C_CTL_FDR_0x22 - 2, 17),
    to_unsigned(IOXOS_MPC_MASTER_I2C_CTL_FDR_0x23 - 2, 17),
    to_unsigned(IOXOS_MPC_MASTER_I2C_CTL_FDR_0x24 - 2, 17),
    to_unsigned(IOXOS_MPC_MASTER_I2C_CTL_FDR_0x25 - 2, 17),
    to_unsigned(IOXOS_MPC_MASTER_I2C_CTL_FDR_0x26 - 2, 17),
    to_unsigned(IOXOS_MPC_MASTER_I2C_CTL_FDR_0x27 - 2, 17),
    to_unsigned(IOXOS_MPC_MASTER_I2C_CTL_FDR_0x28 - 2, 17),
    to_unsigned(IOXOS_MPC_MASTER_I2C_CTL_FDR_0x29 - 2, 17),
    to_unsigned(IOXOS_MPC_MASTER_I2C_CTL_FDR_0x2A - 2, 17),
    to_unsigned(IOXOS_MPC_MASTER_I2C_CTL_FDR_0x2B - 2, 17),
    to_unsigned(IOXOS_MPC_MASTER_I2C_CTL_FDR_0x2C - 2, 17),
    to_unsigned(IOXOS_MPC_MASTER_I2C_CTL_FDR_0x2D - 2, 17),
    to_unsigned(IOXOS_MPC_MASTER_I2C_CTL_FDR_0x2E - 2, 17),
    to_unsigned(IOXOS_MPC_MASTER_I2C_CTL_FDR_0x2F - 2, 17),
    to_unsigned(IOXOS_MPC_MASTER_I2C_CTL_FDR_0x30 - 2, 17),
    to_unsigned(IOXOS_MPC_MASTER_I2C_CTL_FDR_0x31 - 2, 17),
    to_unsigned(IOXOS_MPC_MASTER_I2C_CTL_FDR_0x32 - 2, 17),
    to_unsigned(IOXOS_MPC_MASTER_I2C_CTL_FDR_0x33 - 2, 17),
    to_unsigned(IOXOS_MPC_MASTER_I2C_CTL_FDR_0x34 - 2, 17),
    to_unsigned(IOXOS_MPC_MASTER_I2C_CTL_FDR_0x35 - 2, 17),
    to_unsigned(IOXOS_MPC_MASTER_I2C_CTL_FDR_0x36 - 2, 17),
    to_unsigned(IOXOS_MPC_MASTER_I2C_CTL_FDR_0x37 - 2, 17),
    to_unsigned(IOXOS_MPC_MASTER_I2C_CTL_FDR_0x38 - 2, 17),
    to_unsigned(IOXOS_MPC_MASTER_I2C_CTL_FDR_0x39 - 2, 17),
    to_unsigned(IOXOS_MPC_MASTER_I2C_CTL_FDR_0x3A - 2, 17),
    to_unsigned(IOXOS_MPC_MASTER_I2C_CTL_FDR_0x3B - 2, 17),
    to_unsigned(IOXOS_MPC_MASTER_I2C_CTL_FDR_0x3C - 2, 17),
    to_unsigned(IOXOS_MPC_MASTER_I2C_CTL_FDR_0x3D - 2, 17),
    to_unsigned(IOXOS_MPC_MASTER_I2C_CTL_FDR_0x3E - 2, 17),
    to_unsigned(IOXOS_MPC_MASTER_I2C_CTL_FDR_0x3F - 2, 17));

  function fdr_reg_to_value (regval : unsigned(7 downto 0)) return unsigned is
    variable v : unsigned(16 downto 0);
  begin
    if ( regval(7) = '1' ) then
      v := resize( regval(6 downto 0), v'length );
      if ( v < 2 ) then -- enforce minimum
        v := to_unsigned( 0, v'length );
      else
        v := v - 2;
      end if;
      return  v;
    else
      return fdr_value_rom( to_integer( regval(5 downto 0) ) );
    end if;
  end function fdr_reg_to_value;
  
  -- prescaler down counter and tick signal
  signal current_prescaler_value        : unsigned(16 downto 0) := (others => '0');
  signal next_prescaler_value           : unsigned(16 downto 0);
  signal prescaler_init_value           : unsigned(16 downto 0);
  alias  prescaler_tick                 : std_logic is current_prescaler_value(16);

  -----------------------------------------------------------------------------
  -- protocol controller
  -----------------------------------------------------------------------------

  type controller_states_type is (
    bus_lost,                           -- 0
    gen_start,                          -- 1
    gen_restart,                        -- 2
    gen_stop,                           -- 3
    bus_hold,                           -- 4
    send_address,                       -- 5
    send_address_update_status,         -- 6
    device_selected,                    -- 7
    send_data,                          -- 8
    send_data_update_status,            -- 9
    read_data,                          -- 10
    read_data_update_status,            -- 11
    wait_msta_low);                     -- 12

  signal current_controller_state       : controller_states_type := bus_lost;
  signal next_controller_state          : controller_states_type;

  signal current_controller_active      : std_logic := '0';
  signal next_controller_active         : std_logic;

  -----------------------------------------------------------------------------
  -- bit sender
  -----------------------------------------------------------------------------

  -- command interface
  signal bit_sender_clock_in            : std_logic_vector(19 downto 0) := (others => '0');
  signal bit_sender_data_in             : std_logic_vector(19 downto 0) := (others => '0');
  signal bit_sender_length_in           : std_logic_vector(19 downto 0) := (others => '0');
  signal bit_sender_run                 : std_logic := '0';
  signal bit_sender_ack                 : std_logic := '0';

  -- internal state
  type bit_sender_states_type is (
    bit_sender_idle,                          -- 0
    bit_sender_set_scl,                       -- 1
    bit_sender_monitor_scl,                   -- 2
    bit_sender_wait_end_of_clock_stretching,  -- 3
    bit_sender_set_sda,                       -- 4
    bit_sender_done);                         -- 5

  signal current_bit_sender_state       : bit_sender_states_type := bit_sender_idle;
  signal next_bit_sender_state          : bit_sender_states_type;

  signal current_bit_sender_clock       : std_logic_vector(19 downto 0) := (others => '0');
  signal next_bit_sender_clock          : std_logic_vector(19 downto 0);

  signal current_bit_sender_data        : std_logic_vector(19 downto 0) := (others => '0');
  signal next_bit_sender_data           : std_logic_vector(19 downto 0);

  signal current_bit_sender_length      : std_logic_vector(19 downto 0) := (others => '0');
  signal next_bit_sender_length         : std_logic_vector(19 downto 0);

  signal current_bit_sender_scl         : std_logic := '1';
  signal next_bit_sender_scl            : std_logic;

  signal current_bit_sender_sda         : std_logic := '1';
  signal next_bit_sender_sda            : std_logic;

  -----------------------------------------------------------------------------
  -- bit receiver
  -----------------------------------------------------------------------------

  -- command interface
  signal bit_receiver_run               : std_logic := '0';

  -- internal state
  type bit_receiver_states_type is (
    bit_receiver_idle,                    -- 0
    bit_receiver_wait_scl_rising_edge,    -- 1
    bit_receiver_capture,                 -- 2
    bit_receiver_wait_scl_falling_edge);  -- 3

  signal current_bit_receiver_state     : bit_receiver_states_type := bit_receiver_idle;
  signal next_bit_receiver_state        : bit_receiver_states_type;

  signal current_bit_receiver_data      : std_logic_vector(9 downto 0) := (others => '0');
  signal next_bit_receiver_data         : std_logic_vector(9 downto 0);

  signal current_bit_receiver_length    : unsigned(3 downto 0)         := (others => '0');
  signal next_bit_receiver_length       : unsigned(3 downto 0);

  -----------------------------------------------------------------------------
  -- bus snooper
  -----------------------------------------------------------------------------

  type bus_snooper_states_type is (
    bus_snooper_sda_high,
    bus_snooper_sda_low);

  signal current_bus_snooper_state     : bus_snooper_states_type := bus_snooper_sda_high;
  signal next_bus_snooper_state        : bus_snooper_states_type;

  -----------------------------------------------------------------------------
  -- interrupt controller
  -----------------------------------------------------------------------------

  type int_controller_states_type is (
    int_controller_idle,
    int_controller_pending);

  signal current_int_controller_state   : int_controller_states_type := int_controller_idle;
  signal next_int_controller_state      : int_controller_states_type;

  signal current_interrupt_pending      : std_logic := '0';
  signal next_interrupt_pending         : std_logic := '0';

  -----------------------------------------------------------------------------
  -- physical I2C interface
  -----------------------------------------------------------------------------

  constant I2C_DIR_INPUT                : std_logic := '0';
  constant I2C_DIR_OUTPUT               : std_logic := '1';

  signal current_I2C_DIR                : std_logic := I2C_DIR_INPUT;
  signal next_I2C_DIR                   : std_logic;

  signal current_I2C_SDCI               : std_logic := '1';
  signal current_I2C_SDAI               : std_logic := '1';

  -----------------------------------------------------------------------------
  -- debugging
  -----------------------------------------------------------------------------

  component ifc1210_pon_ila_32 is
    port (
      ila_CLK  : in std_logic;
      ila_TRIG : in std_logic_vector(15 downto 0);
      ila_DATA : in std_logic_vector(31 downto 0));
  end component;

  signal ila_TRIG                       : std_logic_vector(15 downto 0);
  signal ila_TRIGs                      : std_logic_vector(15 downto 0) := (others => '0');
  signal ila_DATA                       : std_logic_vector(31 downto 0);
  signal ila_DATAs                      : std_logic_vector(31 downto 0) := (others => '0');

begin

  -----------------------------------------------------------------------------
  -- debugging
  -----------------------------------------------------------------------------

  GEN_ILA : if (enable_ila /= 0) generate
    debug : ifc1210_pon_ila_32
      port map (
        ila_CLK  => elb_CLK,
        ila_TRIG => ila_TRIGs,
        ila_DATA => ila_DATAs);

    debug_SYNCH_PROC : process (elb_CLK)
    begin
      if (rising_edge(elb_CLK)) then
        ila_TRIGs <= ila_TRIG;
        ila_DATAs <= ila_DATA;
      end if;
    end process debug_SYNCH_PROC;

  ila_TRIG <= ila_DATA(9) &             -- [15] CR MSTA
              ila_DATA(10) &            -- [14] CR RSTA
              ila_DATA(13) &            -- [13] SR MCF
              ila_DATA(14) &            -- [12] SR MBB
              ila_DATA(15) &            -- [11] SR MAL
              ila_DATA(16) &            -- [10] SR MIF
              ila_DATA(17) &            -- [9]  SR RXAK
              ila_DATA(25 downto 24) &  -- [8:7] bit receiver
              ila_DATA(24 downto 22) &  -- [6:4] bit sender
              ila_DATA(21 downto 18);   -- [3:0] main controller

  ila_DATA(7 downto 0) <= mpc_reg_i2cdr_w;

  ila_DATA(8)  <= i2c_cr_men_w;
  ila_DATA(9)  <= i2c_cr_msta_w;
  ila_DATA(10) <= i2c_cr_rsta_w;
  ila_DATA(11) <= i2c_cr_mtx_w;
  ila_DATA(12) <= i2c_cr_txak_w;

  ila_DATA(13) <= i2c_sr_mcf_r;
  ila_DATA(14) <= i2c_sr_mbb_r;
  ila_DATA(15) <= i2c_sr_mal_r;
  ila_DATA(16) <= i2c_sr_mif_r;
  ila_DATA(17) <= i2c_sr_rxak_r;

  ila_DATA(21 downto 18) <= std_logic_vector(to_unsigned(controller_states_type'pos(current_controller_state), 4));
  ila_DATA(23 downto 22) <= std_logic_vector(to_unsigned(bit_sender_states_type'pos(current_bit_sender_state), 2));
  ila_DATA(25 downto 24) <= std_logic_vector(to_unsigned(bit_receiver_states_type'pos(current_bit_receiver_state), 2));

  ila_DATA(26) <= current_bit_sender_sda;
  ila_DATA(27) <= current_bit_sender_scl;
  ila_DATA(28) <= int_I2C_SDCI;
  ila_DATA(29) <= int_I2C_SDAI;
  ila_DATA(30) <= prescaler_tick;

  ila_DATA(31) <= i2creg_RDSTRB;
  end generate GEN_ILA;

  -----------------------------------------------------------------------------
  -- status
  -----------------------------------------------------------------------------

  i2cctl_ERROR  <= i2c_sr_mal_r;
  i2cctl_BUSY   <= current_controller_active;

  -----------------------------------------------------------------------------
  -- MPC-like I2C registers
  -----------------------------------------------------------------------------

  mpc_regs_write_SYNCH_PROC : process (elb_CLK) is
  begin
    if (rising_edge(elb_CLK)) then
      if (elb_RESET = '1') then
        mpc_reg_i2cadr_w   <= INITIAL_MPC_REG_I2CADR;
        if ( not FIXED_FDR_G ) then
        mpc_reg_i2cfdr_w   <= INITIAL_MPC_REG_I2CFDR;
        end if;
        mpc_reg_i2ccr_w    <= INITIAL_MPC_REG_I2CCR;
        mpc_reg_i2csr_w    <= INITIAL_MPC_REG_I2CSR;
        mpc_reg_i2cdr_w    <= INITIAL_MPC_REG_I2CDR;
        mpc_reg_i2cdfsrr_w <= INITIAL_MPC_REG_I2CDFSRR;
      else
        -- update registers and generate events (triggers)
        if (i2creg_WRSTRB = '1') then
          if (i2creg_WE0(0) = '1') then
            mpc_reg_i2cadr_w <= i2creg_DATW;
          elsif ( not FIXED_FDR_G and (i2creg_WE0(1) = '1') ) then
            mpc_reg_i2cfdr_w <= i2creg_DATW;
          elsif (i2creg_WE0(2) = '1') then
            mpc_reg_i2cdfsrr_w <= i2creg_DATW;
          elsif (i2creg_WE0(3) = '1') then
            mpc_reg_i2ccr_w <= i2creg_DATW;
          end if;

          if (i2creg_WE1(0) = '1') then
            mpc_reg_i2csr_w <= i2creg_DATW;
            if (i2creg_DATW(4) = '0') then
              i2c_sr_mal_w_event <= '1';
            end if;
            if (i2creg_DATW(1) = '0') then
              i2c_sr_mif_w_event <= '1';
            end if;
          end if;

          if (i2creg_WE2(0) = '1') then
            mpc_reg_i2cdr_w       <= i2creg_DATW;
            mpc_reg_i2cdr_w_event <= '1';
          end if;
        end if;

        -- clear events (triggers)
        if (clear_i2c_cr_rsta_w = '1') then
          i2c_cr_rsta_w <= '0';
        end if;

        if (clear_i2c_sr_mal_w_event = '1') then
            i2c_sr_mal_w_event <= '0';
        end if;

        if (clear_i2c_sr_mif_w_event = '1') then
            i2c_sr_mif_w_event <= '0';
        end if;

        if (clear_mpc_reg_i2cdr_w_event = '1') then
          mpc_reg_i2cdr_w_event <= '0';
        end if;
      end if;
    end if;
  end process mpc_regs_write_SYNCH_PROC;


  mpc_regs_read_SYNCH_PROC : process (elb_CLK) is
  begin
    if (rising_edge(elb_CLK)) then
      if (elb_RESET = '1') then
        local_i2creg_DATR <= (others => '0');
      else
        case i2creg_RDSEL is
          when "00" =>
            local_i2creg_DATR <= mpc_reg_i2ccr_r &
                                 mpc_reg_i2cdfsrr_r &
                                 mpc_reg_i2cfdr_r &
                                 mpc_reg_i2cadr_r;

          when "01" =>
            local_i2creg_DATR <= mpc_reg_i2cesr_r &
                                 mpc_reg_i2csr_r;

          when "10" =>
            local_i2creg_DATR <= "00000000" &
                                 "00000000" &
                                 "00000000" &
                                 mpc_reg_i2cdr_r;
            if (i2creg_RDSTRB = '1') then
              mpc_reg_i2cdr_r_event <= '1';
            end if;

          when "11" =>
            local_i2creg_DATR <= IOXOS_MPC_MASTER_I2C_CTL_REVISION;

          when others =>
            local_i2creg_DATR <= X"0000_0000";
        end case;

        if (clear_mpc_reg_i2cdr_r_event = '1') then
          mpc_reg_i2cdr_r_event <= '0';
        end if;

      end if;
    end if;
  end process mpc_regs_read_SYNCH_PROC;


  i2creg_DATR <= local_i2creg_DATR;

  -----------------------------------------------------------------------------
  -- address register
  -----------------------------------------------------------------------------

  -- The I2C address register specifies the address to which the I2C module
  -- responds if the I2C is addressed as a slave. Not applicable in this
  -- implementation.
  mpc_reg_i2cadr_r <= mpc_reg_i2cadr_w;

  -----------------------------------------------------------------------------
  -- frequency divider register
  -----------------------------------------------------------------------------

  mpc_reg_i2cfdr_r <= mpc_reg_i2cfdr_w;

  -----------------------------------------------------------------------------
  -- control register
  -----------------------------------------------------------------------------

  i2c_cr_men_r  <= i2c_cr_men_w;
  i2c_cr_mien_r <= i2c_cr_mien_w;
  i2c_cr_msta_r <= i2c_cr_msta_w;
  i2c_cr_mtx_r  <= i2c_cr_mtx_w;
  i2c_cr_txak_r <= i2c_cr_txak_w;
  i2c_cr_rsta_r <= '0';                 -- [1] p.820 "The RSTA field is not readable;
                                        -- an attempt to read RSTA returns a 0."
  i2c_cr_rsvd_r <= '0';
  i2c_cr_bcst_r <= i2c_cr_bcst_w;

  -----------------------------------------------------------------------------
  -- status register
  -----------------------------------------------------------------------------

  -- supported flags
  i2c_sr_mbb_r   <= current_i2c_sr_mbb;
  i2c_sr_mal_r   <= current_i2c_sr_mal_r;
  i2c_sr_mif_r   <= current_i2c_sr_mif_r;
  i2c_sr_rxak_r  <= current_i2c_sr_rxak_r;

  -- unsupported flags, used for slave mode only (always zero)
  i2c_sr_maas_r  <= '0';
  i2c_sr_bcstm_r <= '0';
  i2c_sr_srw_r   <= '0';

  -----------------------------------------------------------------------------
  -- extended status register
  -----------------------------------------------------------------------------

  i2c_esr_rsvd_r <= (others => '0');
  i2c_esr_mcs_r  <= std_logic_vector(to_unsigned(controller_states_type'pos(current_controller_state), 4));
  i2c_esr_sclo_r <= current_bit_sender_scl;
  i2c_esr_sdao_r <= current_bit_sender_sda;
  i2c_esr_scli_r <= int_I2C_SDCI;
  i2c_esr_sdai_r <= int_I2C_SDAI;

  -----------------------------------------------------------------------------
  -- data register
  -----------------------------------------------------------------------------

  mpc_reg_i2cdr_r <= current_mpc_reg_i2cdr_r;

  -----------------------------------------------------------------------------
  -- digital filter sampling rate register
  -----------------------------------------------------------------------------

  mpc_reg_i2cdfsrr_r <= mpc_reg_i2cdfsrr_w;

  -----------------------------------------------------------------------------
  -- prescaler
  -----------------------------------------------------------------------------

  prescaler_SYNCH_PROC : process (elb_CLK) is
  begin
    if (rising_edge(elb_CLK)) then
      if (elb_RESET = '1') then
        current_prescaler_value <= (others => '0');
      else
        current_prescaler_value <= next_prescaler_value;
      end if;
    end if;
  end process prescaler_SYNCH_PROC;


  prescaler_COMBO_PROC : process (
    current_prescaler_value,
    prescaler_init_value,
    prescaler_tick) is
  begin
    if (prescaler_tick = '0') then
      next_prescaler_value <= current_prescaler_value - 1;
    else
      next_prescaler_value <= prescaler_init_value;
    end if;
  end process prescaler_COMBO_PROC;


  prescaler_init_value <= fdr_reg_to_value(unsigned(i2c_fdr));

  -----------------------------------------------------------------------------
  -- controller
  -----------------------------------------------------------------------------

  controller_SYNCH_PROC : process (elb_CLK) is
  begin
    if (rising_edge(elb_CLK)) then
      if (elb_RESET = '1') then
        current_controller_state  <= bus_lost;
        current_controller_active <= '0';
        current_i2c_sr_mal_r      <= '0';
        current_i2c_sr_mif_r      <= '0';
        current_i2c_sr_rxak_r     <= '1';
        current_mpc_reg_i2cdr_r   <= (others => '0');
      else
        current_controller_state  <= next_controller_state;
        current_controller_active <= next_controller_active;
        current_i2c_sr_mal_r      <= next_i2c_sr_mal_r;
        current_i2c_sr_mif_r      <= next_i2c_sr_mif_r;
        current_i2c_sr_rxak_r     <= next_i2c_sr_rxak_r;
        current_mpc_reg_i2cdr_r   <= next_mpc_reg_i2cdr_r;
      end if;
    end if;
  end process controller_SYNCH_PROC;


  controller_COMBO_PROC : process (
    bit_sender_ack,
    current_I2C_DIR,
    current_bit_receiver_data,
    current_controller_active,
    current_controller_state,
    current_i2c_sr_mal_r,
    current_i2c_sr_mif_r,
    current_i2c_sr_rxak_r,
    current_mpc_reg_i2cdr_r,
    i2c_cr_men_w,
    i2c_cr_msta_w,
    i2c_cr_mtx_w,
    i2c_cr_rsta_w,
    i2c_cr_txak_w,
    i2c_sr_mal_w_event,
    i2c_sr_mif_w_event,
    mpc_reg_i2cdr_r_event,
    mpc_reg_i2cdr_w,
    mpc_reg_i2cdr_w_event,
    prescaler_tick) is
  begin
    next_controller_state       <= current_controller_state;
    next_controller_active      <= current_controller_active;
    next_I2C_DIR                <= current_I2C_DIR;
    bit_sender_clock_in         <= (others => '0');
    bit_sender_data_in          <= (others => '0');
    bit_sender_length_in        <= (others => '0');
    bit_sender_run              <= '0';
    bit_receiver_run            <= '0';
    clear_i2c_cr_rsta_w         <= '0';
    clear_i2c_sr_mal_w_event    <= '0';
    clear_i2c_sr_mif_w_event    <= '0';
    clear_mpc_reg_i2cdr_w_event <= '0';
    clear_mpc_reg_i2cdr_r_event <= '0';
    i2c_sr_mcf_r                <= '1';
    next_i2c_sr_mal_r           <= current_i2c_sr_mal_r;
    next_i2c_sr_mif_r           <= current_i2c_sr_mif_r;
    next_i2c_sr_rxak_r          <= current_i2c_sr_rxak_r;
    next_mpc_reg_i2cdr_r        <= current_mpc_reg_i2cdr_r;

    if (i2c_sr_mal_w_event = '1') then
      next_i2c_sr_mal_r        <= '0';
      clear_i2c_sr_mal_w_event <= '1';
    end if;

    if (i2c_sr_mif_w_event = '1') then
      next_i2c_sr_mif_r        <= '0';
      clear_i2c_sr_mif_w_event <= '1';
    end if;

    case current_controller_state is
      -------------------------------------------------------------------------
      -- idle state when the bus is not owned
      -------------------------------------------------------------------------

      when bus_lost =>
        next_I2C_DIR                <= I2C_DIR_INPUT;
        clear_mpc_reg_i2cdr_r_event <= '1';
        next_controller_active      <= '0';
        if (i2c_cr_men_w = '1') then
          if (i2c_cr_msta_w = '1') then
            next_controller_state  <= gen_start;
            next_controller_active <= '1';
          end if;
        end if;

      -------------------------------------------------------------------------
      -- generate START condition
      -------------------------------------------------------------------------

      when gen_start =>
        --
        -- A START condition is a transition of SDA from high to low while SCL
        -- is high. We ensure SCL and SDA are high by first setting them to
        -- high. Then, we drive SDA low while leaving SCL high (START
        -- condition).
        --
        -- Note that if SDA was previously left low (this normally does not
        -- happen), the transition from low to high is a STOP condition, which
        -- is fine because a START condition should follow a STOP condition. If
        -- a START condition is generated without a STOP condition, it is a
        -- repeated START condition (see below).
        --
        --         0    1    2    3
        -- tick    |    |    |    |    |    |    |
        --
        --      ___ ______________________________
        -- SCL  ___/
        --
        --      ________ _________ <-- START
        -- SDA  ________/         \_______________
        --
        --
        --         |    |    |    |    |    |    |
        --
        bit_sender_clock_in  <= B"11_000000000000000000";
        bit_sender_data_in   <= B"10_000000000000000000";
        bit_sender_length_in <= B"11_000000000000000000";
        bit_sender_run       <= '1';
        next_I2C_DIR         <= I2C_DIR_OUTPUT;
        if (bit_sender_ack = '1') then
          next_controller_state <= bus_hold;
        end if;

      -------------------------------------------------------------------------
      -- generate repeated START condition
      -------------------------------------------------------------------------

      when gen_restart =>
        --
        -- A repeated START condition (RESTART for short) is a START condition
        -- generated without preceding STOP condition. First, we set SCL low,
        -- then SDA high. Next, we set SCL high, then SDA low (START condition).
        --
        -- Note the difference with the START condition generation: by first
        -- setting SCL low then SDA high, we ensure that no STOP condition is
        -- generated.
        --
        --         0    1    2    3
        -- tick    |    |    |    |    |    |    |
        --
        --      ___           ____________________
        -- SCL  ___\_________/
        --
        --      ________ _________ <-- START
        -- SDA  ________/         \_______________
        --
        --
        --         |    |    |    |    |    |    |
        --
        bit_sender_clock_in  <= B"01_000000000000000000";
        bit_sender_data_in   <= B"10_000000000000000000";
        bit_sender_length_in <= B"11_000000000000000000";
        bit_sender_run       <= '1';
        next_I2C_DIR         <= I2C_DIR_OUTPUT;
        if (bit_sender_ack = '1') then
          next_controller_state <= bus_hold;
        end if;

      -------------------------------------------------------------------------
      -- generate STOP condition
      -------------------------------------------------------------------------

      when gen_stop =>
        --
        -- A STOP condition is a transition of SDA from low to high while SCL
        -- is high. First, we set SCL low, then SDA low. Next, we set SCL high,
        -- then SDA high (STOP condition).
        --
        --         0    1    2    3
        -- tick    |    |    |    |    |    |    |
        --
        --      ___           ____________________
        -- SCL  ___\_________/
        --
        --      ________  STOP --> _______________
        -- SDA  ________\_________/
        --
        --
        --         |    |    |    |    |    |    |
        --
        bit_sender_clock_in  <= B"01_000000000000000000";
        bit_sender_data_in   <= B"01_000000000000000000";
        bit_sender_length_in <= B"11_000000000000000000";
        bit_sender_run       <= '1';
        next_I2C_DIR         <= I2C_DIR_OUTPUT;
        if (bit_sender_ack = '1') then
          next_controller_state <= bus_lost;
        end if;

      -------------------------------------------------------------------------
      -- idle state when the bus is owned
      -------------------------------------------------------------------------

      when bus_hold =>
        -- a write access to the data register triggers the transmission of the
        -- address
        if (mpc_reg_i2cdr_w_event = '1') then
          clear_mpc_reg_i2cdr_w_event <= '1';
          next_controller_state       <= send_address;
        -- a change of the MSTA flag triggers the generation of a STOP condition
        elsif (i2c_cr_msta_w = '0') then
          next_controller_state <= gen_stop;
        -- RSTA is a transient flag which triggers the generation of a repeated
        -- START condition
        elsif (i2c_cr_rsta_w = '1') then
          next_controller_state <= gen_restart;
          clear_i2c_cr_rsta_w   <= '1';
        end if;

      -------------------------------------------------------------------------
      -- transmit target address
      -------------------------------------------------------------------------

      when send_address =>
        --
        --         0    1    2    3    4    5    6    7    8    9   10   11
        -- tick    |    |    |    |    |    |    |    |    |    |    |    |
        --
        --      ___           _________           _________           _____
        -- SCL  ___\_________/         \_________/         \_________/
        --
        --      ________ ___________________ ___________________ __________
        -- SDA  ________X___________________X___________________X__________
        --                       d(7)                d(6)             d(5)
        --
        --         |    |    |    |    |    |    |    |    |    |    |    |
        --
        i2c_sr_mcf_r        <= '0';
        bit_sender_clock_in <= B"010101010101010101_00";
        bit_sender_data_in  <= mpc_reg_i2cdr_w(7) & mpc_reg_i2cdr_w(7) &  -- d(7) master
                               mpc_reg_i2cdr_w(6) & mpc_reg_i2cdr_w(6) &  -- d(6) master
                               mpc_reg_i2cdr_w(5) & mpc_reg_i2cdr_w(5) &  -- d(5) master
                               mpc_reg_i2cdr_w(4) & mpc_reg_i2cdr_w(4) &  -- d(4) master
                               mpc_reg_i2cdr_w(3) & mpc_reg_i2cdr_w(3) &  -- d(3) master
                               mpc_reg_i2cdr_w(2) & mpc_reg_i2cdr_w(2) &  -- d(2) master
                               mpc_reg_i2cdr_w(1) & mpc_reg_i2cdr_w(1) &  -- d(1) master
                               not i2c_cr_mtx_w   & not i2c_cr_mtx_w   &  -- R/W  master
                               '1'                & '1'                &  -- ACK  slave
                               "11";
        bit_sender_length_in <= B"111111111111111111_00";
        bit_sender_run       <= '1';
        bit_receiver_run     <= '1';
        if (bit_sender_ack = '1') then
          next_controller_state <= send_address_update_status;
        end if;

      when send_address_update_status =>
        next_i2c_sr_rxak_r <= current_bit_receiver_data(0);
        if (current_bit_receiver_data(8 downto 1) /= mpc_reg_i2cdr_w(7 downto 1) & not i2c_cr_mtx_w) then
          next_controller_state <= wait_msta_low;
          next_i2c_sr_mal_r     <= '1';
          next_i2c_sr_mif_r     <= '1';
        else
          next_controller_state <= device_selected;
          next_i2c_sr_mif_r     <= '1';
        end if;

      -------------------------------------------------------------------------
      -- device selected (address has been sent)
      -------------------------------------------------------------------------

      when device_selected =>
        -- a write access to the data register triggers the transmission of the
        -- data
        if (mpc_reg_i2cdr_w_event = '1') then
          clear_mpc_reg_i2cdr_w_event <= '1';
          next_controller_state       <= send_data;
        -- a read access to the data register triggers a data capture
        elsif (mpc_reg_i2cdr_r_event = '1' and i2c_cr_mtx_w = '0') then
          clear_mpc_reg_i2cdr_r_event <= '1';
          next_controller_state       <= read_data;
        -- a change of the MSTA flag triggers the generation of a STOP condition
        elsif (i2c_cr_msta_w = '0') then
          next_controller_state <= gen_stop;
        -- RSTA is a transient flag which triggers the generation of a repeated
        -- START condition
        elsif (i2c_cr_rsta_w = '1') then
          next_controller_state <= gen_restart;
          clear_i2c_cr_rsta_w   <= '1';
        end if;

      -------------------------------------------------------------------------
      -- send data
      -------------------------------------------------------------------------

      when send_data =>
        i2c_sr_mcf_r        <= '0';
        bit_sender_clock_in <= B"010101010101010101_00";
        bit_sender_data_in  <= mpc_reg_i2cdr_w(7) & mpc_reg_i2cdr_w(7) &  -- d(7) master
                               mpc_reg_i2cdr_w(6) & mpc_reg_i2cdr_w(6) &  -- d(6) master
                               mpc_reg_i2cdr_w(5) & mpc_reg_i2cdr_w(5) &  -- d(5) master
                               mpc_reg_i2cdr_w(4) & mpc_reg_i2cdr_w(4) &  -- d(4) master
                               mpc_reg_i2cdr_w(3) & mpc_reg_i2cdr_w(3) &  -- d(3) master
                               mpc_reg_i2cdr_w(2) & mpc_reg_i2cdr_w(2) &  -- d(2) master
                               mpc_reg_i2cdr_w(1) & mpc_reg_i2cdr_w(1) &  -- d(1) master
                               mpc_reg_i2cdr_w(0) & mpc_reg_i2cdr_w(0) &  -- d(0) master
                               '1'                & '1'                &  -- ACK  slave
                               "11";
        bit_sender_length_in <= B"111111111111111111_00";
        bit_sender_run       <= '1';
        bit_receiver_run     <= '1';
        if (bit_sender_ack = '1') then
          next_controller_state <= send_data_update_status;
        end if;

      when send_data_update_status =>
        next_i2c_sr_mif_r  <= '1';
        next_i2c_sr_rxak_r <= current_bit_receiver_data(0);
        if (current_bit_receiver_data(8 downto 1) /= mpc_reg_i2cdr_w) then
          next_controller_state <= wait_msta_low;
          next_i2c_sr_mal_r     <= '1';
        else
          next_controller_state <= device_selected;
        end if;

      -------------------------------------------------------------------------
      -- read data
      -------------------------------------------------------------------------

      when read_data =>
        i2c_sr_mcf_r         <= '0';
        bit_sender_clock_in  <= B"010101010101010101_00";
        bit_sender_data_in   <= "11"                          &  -- d(7) slave
                                "11"                          &  -- d(6) slave
                                "11"                          &  -- d(5) slave
                                "11"                          &  -- d(4) slave
                                "11"                          &  -- d(3) slave
                                "11"                          &  -- d(2) slave
                                "11"                          &  -- d(1) slave
                                "11"                          &  -- d(0) slave
                                i2c_cr_txak_w & i2c_cr_txak_w &  -- ACK  master
                                "11";
        bit_sender_length_in <= B"1111_1111_1111_1111_1100";
        bit_sender_run       <= '1';
        bit_receiver_run     <= '1';
        if (mpc_reg_i2cdr_r_event = '1') then
          clear_mpc_reg_i2cdr_r_event <= '1';
        end if;
        if (bit_sender_ack = '1') then
          next_controller_state <= read_data_update_status;
        -- a change of the MSTA flag triggers the generation of a STOP condition
        elsif (i2c_cr_msta_w = '0') then
          next_controller_state <= gen_stop;
          bit_sender_run        <= '0';
          bit_receiver_run      <= '0';
        -- RSTA is a transient flag which triggers the generation of a repeated
        -- START condition
        elsif (i2c_cr_rsta_w = '1') then
          next_controller_state <= gen_restart;
          clear_i2c_cr_rsta_w   <= '1';
          bit_sender_run        <= '0';
          bit_receiver_run      <= '0';
        end if;

      when read_data_update_status =>
        next_i2c_sr_mif_r     <= '1';
        next_mpc_reg_i2cdr_r  <= current_bit_receiver_data(8 downto 1);
        next_controller_state <= device_selected;

      -------------------------------------------------------------------------
      -- wait until cr[msta] is low, after an arbitration loss
      -------------------------------------------------------------------------

      when wait_msta_low =>
        if (i2c_cr_msta_w = '0') then
          next_controller_state <= bus_lost;
        end if;

    end case;
  end process controller_COMBO_PROC;

  -----------------------------------------------------------------------------
  -- bit sender
  -----------------------------------------------------------------------------

  bit_sender_SYNCH_PROC : process (elb_CLK) is
  begin
    if (rising_edge(elb_CLK)) then
      if (elb_RESET = '1') then
        current_bit_sender_state  <= bit_sender_idle;
        current_bit_sender_clock  <= (others => '0');
        current_bit_sender_data   <= (others => '0');
        current_bit_sender_length <= (others => '0');
        current_bit_sender_scl    <= '1';
        current_bit_sender_sda    <= '1';
      else
        current_bit_sender_state  <= next_bit_sender_state;
        current_bit_sender_clock  <= next_bit_sender_clock;
        current_bit_sender_data   <= next_bit_sender_data;
        current_bit_sender_length <= next_bit_sender_length;
        current_bit_sender_scl    <= next_bit_sender_scl;
        current_bit_sender_sda    <= next_bit_sender_sda;
      end if;
    end if;
  end process bit_sender_SYNCH_PROC;


  bit_sender_COMBO_PROC : process (
    bit_sender_data_in,
    bit_sender_length_in,
    bit_sender_run,
    current_bit_sender_data,
    current_bit_sender_length,
    current_bit_sender_scl,
    current_bit_sender_sda,
    current_bit_sender_state,
    prescaler_tick) is
  begin
    next_bit_sender_state  <= current_bit_sender_state;
    next_bit_sender_clock  <= current_bit_sender_clock;
    next_bit_sender_data   <= current_bit_sender_data;
    next_bit_sender_length <= current_bit_sender_length;
    next_bit_sender_scl    <= current_bit_sender_scl;
    next_bit_sender_sda    <= current_bit_sender_sda;
    bit_sender_ack         <= '0';

    case current_bit_sender_state is
      when bit_sender_idle =>
        next_bit_sender_clock  <= bit_sender_clock_in;
        next_bit_sender_data   <= bit_sender_data_in;
        next_bit_sender_length <= bit_sender_length_in;
        if (bit_sender_run = '1' and prescaler_tick = '1') then
          next_bit_sender_state <= bit_sender_set_scl;
        end if;

      when bit_sender_set_scl =>
        if (bit_sender_run = '0') then
          next_bit_sender_state <= bit_sender_idle;
        elsif (current_bit_sender_length(19) = '1') then
          next_bit_sender_scl   <= current_bit_sender_clock(19);
          next_bit_sender_state <= bit_sender_monitor_scl;
        else
          next_bit_sender_state <= bit_sender_done;
        end if;

      when bit_sender_monitor_scl =>
        -- check for clock stretching condition
        if (current_bit_sender_scl = '1' and int_I2C_SDCI = '0') then
          next_bit_sender_state <= bit_sender_wait_end_of_clock_stretching;
        elsif (prescaler_tick = '1') then
          next_bit_sender_clock <= current_bit_sender_clock(18 downto 0) & '0';
          next_bit_sender_state <= bit_sender_set_sda;
        end if;

      when bit_sender_wait_end_of_clock_stretching =>
        if (int_I2C_SDCI = '1') then
          next_bit_sender_state <= bit_sender_monitor_scl;
        end if;

      when bit_sender_set_sda =>
        if (bit_sender_run = '1') then
          next_bit_sender_sda <= current_bit_sender_data(19);
          if (prescaler_tick = '1') then
            next_bit_sender_data   <= current_bit_sender_data(18 downto 0) & '0';
            next_bit_sender_length <= current_bit_sender_length(18 downto 0) & '0';
            next_bit_sender_state  <= bit_sender_set_scl;
          end if;
        else
          next_bit_sender_state <= bit_sender_idle;
        end if;

      when bit_sender_done =>
        bit_sender_ack <= '1';
        if (bit_sender_run = '0') then
          next_bit_sender_state <= bit_sender_idle;
        end if;
    end case;
  end process bit_sender_COMBO_PROC;

  -----------------------------------------------------------------------------
  -- bit receiver
  -----------------------------------------------------------------------------

  bit_receiver_SYNCH_PROC : process (elb_CLK) is
  begin
    if (rising_edge(elb_CLK)) then
      if (elb_RESET = '1') then
        current_bit_receiver_state  <= bit_receiver_idle;
        current_bit_receiver_data   <= (others => '0');
        current_bit_receiver_length <= (others => '0');
      else
        current_bit_receiver_state  <= next_bit_receiver_state;
        current_bit_receiver_data   <= next_bit_receiver_data;
        current_bit_receiver_length <= next_bit_receiver_length;
      end if;
    end if;
  end process bit_receiver_SYNCH_PROC;

  bit_receiver_COMBO_PROC : process (
    bit_receiver_run, current_bit_receiver_data,
    current_bit_receiver_data(8 downto 0), current_bit_receiver_length,
    current_bit_receiver_state, int_I2C_SDAI, int_I2C_SDCI) is
  begin
    next_bit_receiver_state  <= current_bit_receiver_state;
    next_bit_receiver_data   <= current_bit_receiver_data;
    next_bit_receiver_length <= current_bit_receiver_length;

    case current_bit_receiver_state is
      when bit_receiver_idle =>
        if (bit_receiver_run = '1') then
          if (int_I2C_SDCI = '0') then
            next_bit_receiver_state <= bit_receiver_wait_scl_rising_edge;
          else
            next_bit_receiver_state <= bit_receiver_wait_scl_falling_edge;
          end if;
          next_bit_receiver_data   <= (others => '0');
          next_bit_receiver_length <= (others => '0');
        end if;

      when bit_receiver_wait_scl_rising_edge =>
        if (bit_receiver_run = '0') then
          next_bit_receiver_state  <= bit_receiver_idle;
        elsif (int_I2C_SDCI = '1') then
          next_bit_receiver_state <= bit_receiver_capture;
        end if;

      when bit_receiver_capture =>
        next_bit_receiver_data   <= current_bit_receiver_data(8 downto 0) & int_I2C_SDAI;
        next_bit_receiver_length <= current_bit_receiver_length + 1;
        next_bit_receiver_state  <= bit_receiver_wait_scl_falling_edge;

      when bit_receiver_wait_scl_falling_edge =>
        if (bit_receiver_run = '0') then
          next_bit_receiver_state  <= bit_receiver_idle;
        elsif (int_I2C_SDCI = '0') then
          next_bit_receiver_state <= bit_receiver_wait_scl_rising_edge;
        end if;

    end case;
  end process bit_receiver_COMBO_PROC;

  -----------------------------------------------------------------------------
  -- bus snooper
  -----------------------------------------------------------------------------

  bus_snooper_SYNCH_PROC : process (elb_CLK) is
  begin
    if (rising_edge(elb_CLK)) then
      if (elb_RESET = '1') then
        current_bus_snooper_state <= bus_snooper_sda_high;
        current_i2c_sr_mbb        <= '0';
      else
        current_bus_snooper_state <= next_bus_snooper_state;
        current_i2c_sr_mbb        <= next_i2c_sr_mbb;
      end if;
    end if;
  end process bus_snooper_SYNCH_PROC;


  bus_snooper_COMBO_PROC : process (
    current_bus_snooper_state, current_i2c_sr_mbb, int_I2C_SDAI, int_I2C_SDCI) is
  begin
    next_bus_snooper_state <= current_bus_snooper_state;
    next_i2c_sr_mbb        <= current_i2c_sr_mbb;

    case current_bus_snooper_state is
      when bus_snooper_sda_high =>
        if (int_I2C_SDAI = '0') then
          next_bus_snooper_state <= bus_snooper_sda_low;
          if (int_I2C_SDCI = '1') then
            next_i2c_sr_mbb <= '1';
          end if;
        end if;

      when bus_snooper_sda_low =>
        if (int_I2C_SDAI = '1') then
          next_bus_snooper_state <= bus_snooper_sda_high;
          if (int_I2C_SDCI = '1') then
            next_i2c_sr_mbb <= '0';
          end if;
        end if;
    end case;
  end process bus_snooper_COMBO_PROC;

  -----------------------------------------------------------------------------
  -- interrupt controller
  -----------------------------------------------------------------------------

  int_controller_SYNCH_PROC : process (elb_CLK) is
  begin
    if (rising_edge(elb_CLK)) then
      if (elb_RESET = '1') then
        current_int_controller_state <= int_controller_idle;
        current_interrupt_pending    <= '0';
      else
        current_int_controller_state <= next_int_controller_state;
        current_interrupt_pending    <= next_interrupt_pending;
      end if;
    end if;
  end process int_controller_SYNCH_PROC;


  int_controller_COMBO_PROC : process (
    current_i2c_sr_mif_r,
    current_int_controller_state,
    current_interrupt_pending,
    i2c_cr_mien_w) is
  begin
    next_int_controller_state <= current_int_controller_state;
    next_interrupt_pending    <= current_interrupt_pending;

    case current_int_controller_state is
      when int_controller_idle =>
        if (current_i2c_sr_mif_r = '1' and i2c_cr_mien_w = '1') then
          next_int_controller_state <= int_controller_pending;
          next_interrupt_pending    <= '1';
        end if;

      -- attention: if MIEN = 0, interrupt reporting from the I2C module is
      -- disabled. If any pending interrupt conditions exist, THEY ARE NOT
      -- CLEARED.
      when int_controller_pending =>
        if (current_i2c_sr_mif_r = '0') then
          next_int_controller_state <= int_controller_idle;
          next_interrupt_pending    <= '0';
        end if;
    end case;
  end process int_controller_COMBO_PROC;

  i2cctl_IRQOK  <= current_interrupt_pending;
  i2cctl_IRQERR <= '0';

  -----------------------------------------------------------------------------
  -- physical I2C interface
  -----------------------------------------------------------------------------

  physical_SYNCH_PROC : process (elb_CLK) is
  begin
    if (rising_edge(elb_CLK)) then
      current_I2C_DIR  <= next_I2C_DIR;
      current_I2C_SDCI <= int_I2C_SDCI;
      current_I2C_SDAI <= int_I2C_SDAI;
    end if;
  end process physical_SYNCH_PROC;

  int_I2C_DIR  <= current_I2C_DIR;
  int_I2C_SDAO <= current_bit_sender_sda;
  int_I2C_SDC  <= current_bit_sender_scl;

  dbg_STATE( 3 downto 0) <= std_logic_vector(to_unsigned(controller_states_type'pos(current_controller_state), 4));
  dbg_STATE( 5 downto 4) <= std_logic_vector(to_unsigned(bit_receiver_states_type'pos(current_bit_receiver_state), 2));
  dbg_STATE( 8 downto 6) <= std_logic_vector(to_unsigned(bit_sender_states_type'pos(current_bit_sender_state), 3));
end architecture rtl;
