-------------------------------------------------------------------------------
-- File       : i2cRegSlaveWrap.vhd
-- Author     : Benjamin Reese  <bareese@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-------------------------------------------------------------------------------
-- Description: Simulation testbed for i2cRegSlaveWrap
-------------------------------------------------------------------------------
-- This file is part of 'SLAC Firmware Standard Library'.
-- It is subject to the license terms in the LICENSE.txt file found in the 
-- top-level directory of this distribution and at: 
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
-- No part of 'SLAC Firmware Standard Library', including this file, 
-- may be copied, modified, propagated, or distributed except according to 
-- the terms contained in the LICENSE.txt file.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.StdRtlPkg.all;
use work.i2cPkg.all;

entity i2cRegSlaveWrap is
  
  generic (
    TPD_G : time := 1 ns;

    I2C_ADDR_G : integer range 0 to 1023 := 0;
    TENBIT_G   : integer range 0 to 1    := 0;
    FILTER_G   : integer range 2 to 512  := 4;

    ADDR_SIZE_G  : positive             := 2;
    DATA_SIZE_G  : positive             := 2;
    ENDIANNESS_G : integer range 0 to 1 := 0);

  port (
    clk    : in    sl;
    rst    : in    sl;

    addr   : out   slv(8*ADDR_SIZE_G-1 downto 0);
    wrEn   : out   sl;
    wrData : out   slv(8*DATA_SIZE_G-1 downto 0);
    rdEn   : out   sl;
    rdData : in    slv(8*DATA_SIZE_G-1 downto 0);

    i2cSda : inout sl;
    i2cScl : inout sl);

end entity i2cRegSlaveWrap;

architecture rtl of i2cRegSlaveWrap is

  signal i2ci : i2c_in_type;
  signal i2co : i2c_out_type;

begin

  U_IF : entity work.i2cRegSlave
    generic map (
      TENBIT_G             => TENBIT_G,
      I2C_ADDR_G           => I2C_ADDR_G,
      OUTPUT_EN_POLARITY_G => 0,
      FILTER_G             => FILTER_G,
      ADDR_SIZE_G          => ADDR_SIZE_G,
      DATA_SIZE_G          => DATA_SIZE_G,
      ENDIANNESS_G         => ENDIANNESS_G)
    port map (
      sRst    => rst,
      clk    => clk,
      addr   => addr,
      wrEn   => wrEn,
      wrData => wrData,
      rdEn   => rdEn,
      rdData => rdData,
      i2ci   => i2ci,
      i2co   => i2co);

  i2cSda <= i2co.sda when i2co.sdaoen = '0' else 'Z';
  i2ci.sda <= i2cSda;

  i2cScl <= i2co.scl when i2co.scloen = '0' else 'Z';
  i2ci.scl <= i2cScl;

end architecture rtl;
