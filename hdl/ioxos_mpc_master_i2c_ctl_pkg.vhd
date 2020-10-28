-------------------------------------------------------------------------
--
-- Project      :   IFC_XXXX (IFC_1210, IFC_1211, IFC_1410)
-- File name    :   ioxos_mpc_master_i2c_ctl_pkg.vhd
-- Title        :   MPC-compatible master I2C controller (package)
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


package ioxos_mpc_master_i2c_ctl_pkg is

  constant IOXOS_MPC_MASTER_I2C_CTL_REVISION      : std_logic_vector(31 downto 0) := X"28101501";

  constant IOXOS_MPC_MASTER_I2C_CTL_FDR_0x00      : integer :=   384;
  constant IOXOS_MPC_MASTER_I2C_CTL_FDR_0x01      : integer :=   416;
  constant IOXOS_MPC_MASTER_I2C_CTL_FDR_0x02      : integer :=   480;
  constant IOXOS_MPC_MASTER_I2C_CTL_FDR_0x03      : integer :=   576;
  constant IOXOS_MPC_MASTER_I2C_CTL_FDR_0x04      : integer :=   640;
  constant IOXOS_MPC_MASTER_I2C_CTL_FDR_0x05      : integer :=   704;
  constant IOXOS_MPC_MASTER_I2C_CTL_FDR_0x06      : integer :=   832;
  constant IOXOS_MPC_MASTER_I2C_CTL_FDR_0x07      : integer :=  1024;
  constant IOXOS_MPC_MASTER_I2C_CTL_FDR_0x08      : integer :=  1152;
  constant IOXOS_MPC_MASTER_I2C_CTL_FDR_0x09      : integer :=  1280;
  constant IOXOS_MPC_MASTER_I2C_CTL_FDR_0x0A      : integer :=  1536;
  constant IOXOS_MPC_MASTER_I2C_CTL_FDR_0x0B      : integer :=  1920;
  constant IOXOS_MPC_MASTER_I2C_CTL_FDR_0x0C      : integer :=  2304;
  constant IOXOS_MPC_MASTER_I2C_CTL_FDR_0x0D      : integer :=  2560;
  constant IOXOS_MPC_MASTER_I2C_CTL_FDR_0x0E      : integer :=  3072;
  constant IOXOS_MPC_MASTER_I2C_CTL_FDR_0x0F      : integer :=  3840;
  constant IOXOS_MPC_MASTER_I2C_CTL_FDR_0x10      : integer :=  4608;
  constant IOXOS_MPC_MASTER_I2C_CTL_FDR_0x11      : integer :=  5120;
  constant IOXOS_MPC_MASTER_I2C_CTL_FDR_0x12      : integer :=  6144;
  constant IOXOS_MPC_MASTER_I2C_CTL_FDR_0x13      : integer :=  7680;
  constant IOXOS_MPC_MASTER_I2C_CTL_FDR_0x14      : integer :=  9216;
  constant IOXOS_MPC_MASTER_I2C_CTL_FDR_0x15      : integer := 10240;
  constant IOXOS_MPC_MASTER_I2C_CTL_FDR_0x16      : integer := 12288;
  constant IOXOS_MPC_MASTER_I2C_CTL_FDR_0x17      : integer := 15360;
  constant IOXOS_MPC_MASTER_I2C_CTL_FDR_0x18      : integer := 18432;
  constant IOXOS_MPC_MASTER_I2C_CTL_FDR_0x19      : integer := 20480;
  constant IOXOS_MPC_MASTER_I2C_CTL_FDR_0x1A      : integer := 24576;
  constant IOXOS_MPC_MASTER_I2C_CTL_FDR_0x1B      : integer := 30720;
  constant IOXOS_MPC_MASTER_I2C_CTL_FDR_0x1C      : integer := 36864;
  constant IOXOS_MPC_MASTER_I2C_CTL_FDR_0x1D      : integer := 40960;
  constant IOXOS_MPC_MASTER_I2C_CTL_FDR_0x1E      : integer := 49152;
  constant IOXOS_MPC_MASTER_I2C_CTL_FDR_0x1F      : integer := 61440;
  constant IOXOS_MPC_MASTER_I2C_CTL_FDR_0x20      : integer :=   256;
  constant IOXOS_MPC_MASTER_I2C_CTL_FDR_0x21      : integer :=   288;
  constant IOXOS_MPC_MASTER_I2C_CTL_FDR_0x22      : integer :=   320;
  constant IOXOS_MPC_MASTER_I2C_CTL_FDR_0x23      : integer :=   352;
  constant IOXOS_MPC_MASTER_I2C_CTL_FDR_0x24      : integer :=   384;
  constant IOXOS_MPC_MASTER_I2C_CTL_FDR_0x25      : integer :=   448;
  constant IOXOS_MPC_MASTER_I2C_CTL_FDR_0x26      : integer :=   512;
  constant IOXOS_MPC_MASTER_I2C_CTL_FDR_0x27      : integer :=   576;
  constant IOXOS_MPC_MASTER_I2C_CTL_FDR_0x28      : integer :=   640;
  constant IOXOS_MPC_MASTER_I2C_CTL_FDR_0x29      : integer :=   768;
  constant IOXOS_MPC_MASTER_I2C_CTL_FDR_0x2A      : integer :=   896;
  constant IOXOS_MPC_MASTER_I2C_CTL_FDR_0x2B      : integer :=  1024;
  constant IOXOS_MPC_MASTER_I2C_CTL_FDR_0x2C      : integer :=  1280;
  constant IOXOS_MPC_MASTER_I2C_CTL_FDR_0x2D      : integer :=  1536;
  constant IOXOS_MPC_MASTER_I2C_CTL_FDR_0x2E      : integer :=  1792;
  constant IOXOS_MPC_MASTER_I2C_CTL_FDR_0x2F      : integer :=  2048;
  constant IOXOS_MPC_MASTER_I2C_CTL_FDR_0x30      : integer :=  2560;
  constant IOXOS_MPC_MASTER_I2C_CTL_FDR_0x31      : integer :=  3072;
  constant IOXOS_MPC_MASTER_I2C_CTL_FDR_0x32      : integer :=  3584;
  constant IOXOS_MPC_MASTER_I2C_CTL_FDR_0x33      : integer :=  4096;
  constant IOXOS_MPC_MASTER_I2C_CTL_FDR_0x34      : integer :=  5120;
  constant IOXOS_MPC_MASTER_I2C_CTL_FDR_0x35      : integer :=  6144;
  constant IOXOS_MPC_MASTER_I2C_CTL_FDR_0x36      : integer :=  7168;
  constant IOXOS_MPC_MASTER_I2C_CTL_FDR_0x37      : integer :=  8192;
  constant IOXOS_MPC_MASTER_I2C_CTL_FDR_0x38      : integer := 10240;
  constant IOXOS_MPC_MASTER_I2C_CTL_FDR_0x39      : integer := 12288;
  constant IOXOS_MPC_MASTER_I2C_CTL_FDR_0x3A      : integer := 14336;
  constant IOXOS_MPC_MASTER_I2C_CTL_FDR_0x3B      : integer := 16384;
  constant IOXOS_MPC_MASTER_I2C_CTL_FDR_0x3C      : integer := 20480;
  constant IOXOS_MPC_MASTER_I2C_CTL_FDR_0x3D      : integer := 24576;
  constant IOXOS_MPC_MASTER_I2C_CTL_FDR_0x3E      : integer :=   128; -- changed: was 28672
  constant IOXOS_MPC_MASTER_I2C_CTL_FDR_0x3F      : integer :=    64; -- changed: was 32768

  type IoxosMpcMasterI2cDividerTableArray is array (natural range <>) of integer;
  constant IOXOS_MPC_MASTER_I2C_DIVIDER_TABLE     : IoxosMpcMasterI2cDividerTableArray := (
    IOXOS_MPC_MASTER_I2C_CTL_FDR_0x00,
    IOXOS_MPC_MASTER_I2C_CTL_FDR_0x01,
    IOXOS_MPC_MASTER_I2C_CTL_FDR_0x02,
    IOXOS_MPC_MASTER_I2C_CTL_FDR_0x03,
    IOXOS_MPC_MASTER_I2C_CTL_FDR_0x04,
    IOXOS_MPC_MASTER_I2C_CTL_FDR_0x05,
    IOXOS_MPC_MASTER_I2C_CTL_FDR_0x06,
    IOXOS_MPC_MASTER_I2C_CTL_FDR_0x07,
    IOXOS_MPC_MASTER_I2C_CTL_FDR_0x08,
    IOXOS_MPC_MASTER_I2C_CTL_FDR_0x09,
    IOXOS_MPC_MASTER_I2C_CTL_FDR_0x0A,
    IOXOS_MPC_MASTER_I2C_CTL_FDR_0x0B,
    IOXOS_MPC_MASTER_I2C_CTL_FDR_0x0C,
    IOXOS_MPC_MASTER_I2C_CTL_FDR_0x0D,
    IOXOS_MPC_MASTER_I2C_CTL_FDR_0x0E,
    IOXOS_MPC_MASTER_I2C_CTL_FDR_0x0F,
    IOXOS_MPC_MASTER_I2C_CTL_FDR_0x10,
    IOXOS_MPC_MASTER_I2C_CTL_FDR_0x11,
    IOXOS_MPC_MASTER_I2C_CTL_FDR_0x12,
    IOXOS_MPC_MASTER_I2C_CTL_FDR_0x13,
    IOXOS_MPC_MASTER_I2C_CTL_FDR_0x14,
    IOXOS_MPC_MASTER_I2C_CTL_FDR_0x15,
    IOXOS_MPC_MASTER_I2C_CTL_FDR_0x16,
    IOXOS_MPC_MASTER_I2C_CTL_FDR_0x17,
    IOXOS_MPC_MASTER_I2C_CTL_FDR_0x18,
    IOXOS_MPC_MASTER_I2C_CTL_FDR_0x19,
    IOXOS_MPC_MASTER_I2C_CTL_FDR_0x1A,
    IOXOS_MPC_MASTER_I2C_CTL_FDR_0x1B,
    IOXOS_MPC_MASTER_I2C_CTL_FDR_0x1C,
    IOXOS_MPC_MASTER_I2C_CTL_FDR_0x1D,
    IOXOS_MPC_MASTER_I2C_CTL_FDR_0x1E,
    IOXOS_MPC_MASTER_I2C_CTL_FDR_0x1F,
    IOXOS_MPC_MASTER_I2C_CTL_FDR_0x20,
    IOXOS_MPC_MASTER_I2C_CTL_FDR_0x21,
    IOXOS_MPC_MASTER_I2C_CTL_FDR_0x22,
    IOXOS_MPC_MASTER_I2C_CTL_FDR_0x23,
    IOXOS_MPC_MASTER_I2C_CTL_FDR_0x24,
    IOXOS_MPC_MASTER_I2C_CTL_FDR_0x25,
    IOXOS_MPC_MASTER_I2C_CTL_FDR_0x26,
    IOXOS_MPC_MASTER_I2C_CTL_FDR_0x27,
    IOXOS_MPC_MASTER_I2C_CTL_FDR_0x28,
    IOXOS_MPC_MASTER_I2C_CTL_FDR_0x29,
    IOXOS_MPC_MASTER_I2C_CTL_FDR_0x2A,
    IOXOS_MPC_MASTER_I2C_CTL_FDR_0x2B,
    IOXOS_MPC_MASTER_I2C_CTL_FDR_0x2C,
    IOXOS_MPC_MASTER_I2C_CTL_FDR_0x2D,
    IOXOS_MPC_MASTER_I2C_CTL_FDR_0x2E,
    IOXOS_MPC_MASTER_I2C_CTL_FDR_0x2F,
    IOXOS_MPC_MASTER_I2C_CTL_FDR_0x30,
    IOXOS_MPC_MASTER_I2C_CTL_FDR_0x31,
    IOXOS_MPC_MASTER_I2C_CTL_FDR_0x32,
    IOXOS_MPC_MASTER_I2C_CTL_FDR_0x33,
    IOXOS_MPC_MASTER_I2C_CTL_FDR_0x34,
    IOXOS_MPC_MASTER_I2C_CTL_FDR_0x35,
    IOXOS_MPC_MASTER_I2C_CTL_FDR_0x36,
    IOXOS_MPC_MASTER_I2C_CTL_FDR_0x37,
    IOXOS_MPC_MASTER_I2C_CTL_FDR_0x38,
    IOXOS_MPC_MASTER_I2C_CTL_FDR_0x39,
    IOXOS_MPC_MASTER_I2C_CTL_FDR_0x3A,
    IOXOS_MPC_MASTER_I2C_CTL_FDR_0x3B,
    IOXOS_MPC_MASTER_I2C_CTL_FDR_0x3C,
    IOXOS_MPC_MASTER_I2C_CTL_FDR_0x3D,
    IOXOS_MPC_MASTER_I2C_CTL_FDR_0x3E,
    IOXOS_MPC_MASTER_I2C_CTL_FDR_0x3F
  );


end package ioxos_mpc_master_i2c_ctl_pkg;

