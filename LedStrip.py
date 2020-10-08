#!/usr/bin/python3

import time
import math

class LedStrip:
  def __init__(self, i2c, i2cAddrLeft = 0x69, i2cAddrRight = 0x05, nLeds=30):
    self.i2cAddrRight_ = i2cAddrRight
    self.i2cAddrLeft_  = i2cAddrLeft
    self.nLeds_        = nLeds
    self.i2c_          = i2c
    self.ctlLeft_      = bytearray(4)
    self.ctlRight_     = bytearray(4)
    self.i2c_.setOffsetAndRead(self.i2cAddrRight_, 0x82, self.ctlRight_)
    self.i2c_.setOffsetAndRead(self.i2cAddrLeft_ , 0x82, self.ctlLeft_ )
    self.ctlLeft_.insert(0, 0x82)
    self.ctlRight_.insert(0, 0x82)

  def setPwmIref(self, pwm, iref = None):
    if pwm is None:
      if iref is None:
        return
      h   = bytearray([0x98])
      pwm = bytearray()
    else:
      h   = bytearray([0x88])
      try:
        if 0 == len(pwm):
          h   = bytearray([0x98])
        elif self.nLeds_ != len(pwm):
          raise RuntimeError("LedStrip.setPwmIref(): invalid pwm arg (must have {:d} elements)".format(self.nLeds_))
      except TypeError:
        pwm = [pwm for i in range(self.nLeds_)]
      pwm = bytearray( pwm )
    if iref is None:
      iref = bytearray()
    else:
      try:
        if self.nLeds_ != len(iref) and 0 != len(iref):
          raise RuntimeError("LedStrip.setPwmIref(): invalid iref arg (must have {:d} elements)".format(self.nLeds_))
      except TypeError:
        iref = [iref for i in range(self.nLeds_)]
      iref = bytearray(iref)
    if self.nLeds_ <= 16:
      if len(pwm) > 0:
        pwm.extend([0 for i in range(16 - self.nLeds_)])
      self.i2c_.sendStartWrite( self.i2cAddrRight_, h + pwm + iref )
    else:
      if len(pwm) > 0:
        pwm.extend([0 for i in range(32 - self.nLeds_)])
      self.i2c_.sendStartWrite( self.i2cAddrRight_, h + pwm[ 0:16] + iref[0 :16         ] )
      self.i2c_.sendStartWrite( self.i2cAddrLeft_ , h + pwm[16:32] + iref[16:self.nLeds_] )

  @staticmethod
  def _getIdxShft(i):
    idx = int(i/4) + 1
    shf = 2*(i&3)
    return idx,shf

  def setCtrl(self, ctrl):
    for i in range(16):
      idx,shf = self._getIdxShft(i)
      self.ctlRight_[ idx] &= ~(3 << shf)
      self.ctlLeft_ [ idx] &= ~(3 << shf)
      if ( ctrl & (1<<i) ):
        self.ctlRight_[ idx ] |= (2 << shf)
      if ( ctrl & (1<<(i+16)) ):
        self.ctlLeft_ [ idx ] |= (2 << shf)
    self.i2c_.sendStartWrite(self.i2cAddrRight_, self.ctlRight_)
    self.i2c_.sendStartWrite(self.i2cAddrLeft_ , self.ctlLeft_ )

  def flipCtrl(self, bitNo, op = 0):
    if bitNo > 16:
      a = self.i2cAddrLeft_
      c = self.ctlLeft_
      i = bitNo - 16
    else:
      a = self.i2cAddrRight_
      c = self.ctlRight_
      i = bitNo
    idx,shf = self._getIdxShft(i)
    v = c[idx]
    if ( op != 0 ):
      v &= ~(3 << shf)
      if ( op > 0 ):
        v |= (2 << shf)
    else:
      v ^= (2<<shf)
    c[idx] = v
    self.i2c_.sendStartWrite(a, c)

  def grayCount(self, n, sleepTime=0.5):
    self.setCtrl(0)
    lastGray = 0
    for i in range(1,n):
      newGray = i ^ (i>>1)
      bitNo   = int(math.log2(newGray^lastGray))
      self.flipCtrl( bitNo )
      time.sleep(sleepTime)
      lastGray = newGray

  def test(self, termCount = (1<<16), sleepTime=0.01):
    self.setCtrl(0xffffffff)
    for i in range(0xa0):
      self.setPwmIref( 0xff, i )
      time.sleep(0.01)
    for i in range(0xf0, -1, -1):
      self.setPwmIref( i, 0xa0 )
      time.sleep(0.01)
    self.setPwmIref(0x60, 0xc0)
    for i in range(2):
      self.setCtrl(0x55555555)
      time.sleep(3.0)
      self.setCtrl(0xaaaaaaaa)
      time.sleep(3.0)
    self.grayCount( termCount, sleepTime )
    

if "__main__" == __name__:
  from Mcp2221I2c import Mcp2221I2c
  import usb1
  with usb1.USBContext() as ctx:
    mcp = Mcp2221I2c( ctx )
    led = LedStrip(mcp)
    led.test((1<<30))
