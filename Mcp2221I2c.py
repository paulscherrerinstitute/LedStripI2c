#!/usr/bin/python3

import usb1
import time

class I2cBusBusyError(RuntimeError):
  def __init__(self, msg):
    super().__init__(msg)

class Mcp2221I2c:
  MICROCHIP_VENDOR_ID = 0x04d8
  MCP2221A_PRODUCT_ID = 0x00dd
  MCP2221A_SYSFREQ    = 12000000.0
  BUF_LEN             = 64
  def __init__(self, ctx):
    self.ctx_ = ctx
    self.hdl_ = self.ctx_.openByVendorIDAndProductID(self.MICROCHIP_VENDOR_ID, self.MCP2221A_PRODUCT_ID, skip_on_error=True)
    self.ep_  = None
    self.ifn_ = None
    self.tom_ = 0
    if self.hdl_ is None:
      raise RuntimeError("MCP2221A USB device not found")
    for ifs in self.hdl_.getDevice().iterSettings():
      if ( usb1.CLASS_HID == ifs.getClass() ): 
        for ep in ifs.iterEndpoints():
          # usb1 has currently no way to obtain the endpoint type :-(
          # direction doesn't seem to matter as it is explicitly set
          # by the device's read/write method
          self.ep_  = ep.getAddress()
          self.ifn_ = ifs.getNumber()
          break
        break
    if self.ep_ is None:
      raise RuntimeError("MCP2221A - no HID/interrupt EP found")
    try:
      self.hdl_.detachKernelDriver( self.ifn_ )
    except usb1.USBErrorNotFound as e:
      print("Detaching kernel driver failed - probably already detached")

  @staticmethod
  def _getBuf():
    return bytearray(Mcp2221I2c.BUF_LEN)

  def _xfer(self, ibuf, obuf = None):
    if obuf is None:
      obuf = ibuf
    put = self.hdl_.interruptWrite( self.ep_, ibuf, self.tom_ )
    if put != len(ibuf):
      raise RuntimeError("MCP2221A._xfer: not all data written")

    # BUG in usb package; should be able to pass a buffer
    # interruptRead:
    #    data = create_binary_buffer(length) # (returns 'length' if 'length' is
    #                                        # already a buffer !
    #    self._interruptTransfer(ep, data, length, ...)
    # -> if length is already a buffer then _interruptTransfer is called
    #    with the wrong argument!
    newb = self.hdl_.interruptRead( self.ep_, self.BUF_LEN, self.tom_ )
    if self.BUF_LEN != len(newb):
      raise RuntimeError("MCP2221A._xfer: not all data read")
    obuf[:] = newb[:]

  # The nominal max. i2c speed of the MCP2221A is 400kHz; typically it seems
  # to max out around 500kHz (i.e., by setting a small divider the effective
  # i2c clock speed still does not increase above ~500kHz)
  # The default divider is 20 which should yield a freq. of 600kHz but in
  # practice is less than that...
  def getStatus(self, buf = None, cancel = False, speed = 0):
    if cancel and 0 != speed:
      # Speed has no effect if 'cancel' is true
      raise RuntimeError("MCP2221A.getStatus(): cancel must be False when changing speed")
    if buf is None:
      buf = self._getBuf()
    buf[0:5] = bytes(5)
    buf[0] = 0x10
    if cancel:
      buf[2] = 0x10
    if 0 != speed:
      buf[3] = 0x20
      buf[4] = round(self.MCP2221A_SYSFREQ / float(speed))
    self._xfer( buf )

  def printStatus(self, buf = None, cancel = False, speed = 0):
    if buf is None:
      buf = self._getBuf()
    self.getStatus(buf, cancel, speed)   

    print("Requested Length     : {:d}".format( (buf[10]<<8) | buf[ 9]));
    print("Transferred Length   : {:d}".format( (buf[12]<<8) | buf[11]));
    print("Current data buf cntr: {:d}".format( buf[13] ));
    print("Current speed divider: {:d}".format( buf[14] ));
    print("Current i2c timeout  : {:d}".format( buf[15] ));
    print("Current SCL pin value: {:d}".format( buf[22] ));
    print("Current SDA pin value: {:d}".format( buf[23] ));
    print("Current i2c r-pending: {:d}".format( buf[25] ));

  def drain(self):
    buf     = self._getBuf()
    #buf[13] = 1
    #while 0 != buf[13]:
    then    = time.clock_gettime(time.CLOCK_MONOTONIC);
    buf[9]  = 1
    while buf[9] != buf[11] or buf[10] != buf[12]:
      self.getStatus( buf )
      now  = time.clock_gettime(time.CLOCK_MONOTONIC);
      if now - then > 2.0:
        self.printStatus(buf)
        raise RuntimeError("Mcp2221A.drain(): timeout");

  def sendStartWrite(self, addr, data, siz = -1, sendStop=True, restart=False):
    if not sendStop and restart:
      # not supported by MCP2221A
      raise RuntimeError("Mcp2221A.sendStartWrite(): invalid args; cannot restart w/o stop")
    buf = self._getBuf()
    if (siz < 0 or siz > len(data)):
      siz = len(data)
    if ( siz > 60 ):
      raise RuntimeError("Transfers > 60 bytes currently not supported")
    if sendStop:
      if restart:
        buf[0] = 0x92
      else:
        buf[0] = 0x90
    else:
      buf[0] = 0x94
    buf[1] = (siz >> 0) & 0xff
    buf[2] = (siz >> 8) & 0xff
    buf[3] = (addr << 1) # I2C WRITE
    buf[4:4+siz] = data[0:siz]
    self._xfer(buf, buf)
    if ( 0x00 != buf[1] ):
      raise I2cBusBusyError("MCP2221.sendStartWrite(): transfer failed (I2C was busy)")

  def sendStartRead(self, addr, data, siz = -1, restart=False):
    buf = self._getBuf()
    if ( siz < 0 or siz > len(data) ):
      siz = len(data)
    if ( siz > 60 ):
      raise RuntimeError("Transfers > 60 bytes currently not supported")
    if restart:
      buf[0] = 0x93
    else:
      buf[0] = 0x91
    buf[1] = (siz  >> 0) & 0xff
    buf[2] = (siz  >> 8) & 0xff
    buf[3] = (addr << 1) | 1 # I2C READ
    self._xfer(buf, buf)
    if ( 0x00 != buf[1] ):
      raise I2cBusBusyError("MCP2221.sendStartRead(): transfer failed (I2C was busy)")

    self.drain()

    buf[0] = 0x40
    self._xfer(buf, buf)

    if ( 0x00 != buf[1] or 60 < buf[3] ):
        print("buf[1]: 0x{:02x}, buf[3]: 0x{:02x}".format( buf.b[1], buf.b[3] ))
        raise RuntimeError("MCP2221.sendStartRead(): readout error\n");
    if ( siz > buf[3] ):
      siz = buf[3]
    data[0:siz] = buf[4:4+siz]
    return siz

  def probeI2cAddr(self, addr, useWrite=True):
    try:
      if useWrite:
        self.sendStartWrite(addr,[])
        self.sendStartWrite(addr,[])
      else:
        self.sendStartRead(addr,[])
        self.sendStartRead(addr,[])
      return True
    except I2cBusBusyError:
      self.getStatus(buf=None, cancel=True)
      return False

  def setOffsetAndRead(self, addr, off, data, siz = -1):
    self.sendStartWrite(addr, [off], siz=-1, sendStop=False)
    self.sendStartRead (addr, data , siz=-1, restart =True )

  def getFlashChipSettings(self):
    buf    = self._getBuf()
    # all zeros in buf now
    buf[0] = 0xB0
    buf[1] = 0x00
    self._xfer(buf, buf)
    if 0 != buf[1]:
      raise RuntimeError("MCP2221.getFlashChipSettings(): command not supported")
    return buf[4:4+buf[2]]

  def getChipSettingsVIDPID(self, settings):
    vid = (settings[5]<<8) | settings[4]
    pid = (settings[7]<<8) | settings[6]
    return vid, pid

  def getChipSettingsmA(self, settings):
    return 2*settings[9]

  def setChipSettingsmA(self, settings, mA):
    if mA < 0 or mA > 510:
      raise RuntimeError("Mcp2221A.setChipSettingsmA() - invalid argument")
    settings[9] = int( (mA + 1)/2 )

  def progFlashChipSettingsmA(self, mA):
    settings = self.getFlashChipSettings()
    self.setChipSettingsmA(settings, mA)
    self.progFlashChipSettings(settings)

  def progFlashChipSettings(self, settings, force=False, password=None):
    if (settings[0] & 2) != 0:
      raise RuntimeError("Security bits will PERMANENTLY LOCK - refusing to change chip settings")
    if not force:
      vid, pid = self.getChipSettingsVIDPID(settings)
      if vid != 0x4d8 or pid != 0xdd:
        raise RuntimeError("Unexpected VID/PID - refusing to change chip settings")
      if (settings[0] & 3) != 0:
        if (settings[1]    ) != 0:
          raise RuntimeError("Password ENABLED - refusing to change chip settings")
    buf = self._getBuf()
    buf[0]    = 0xb1
    buf[1]    = 0x00
    buf[2:12] = settings
    if not password is None:
      buf[12:20] = password
    self._xfer(buf, buf)
    if buf[1] != 0x00:
      if 0x02 == buf[1]:
        raise RuntimeError("Mcp2221A.setFlashChipSettings() ERROR: command not supported")
      elif 0x03 == buf[1]:
        raise RuntimeError("Mcp2221A.setFlashChipSettings() ERROR: command not allowed")
      else:
        raise RuntimeError("Mcp2221A.setFlashChipSettings() ERROR: unknown error")

  def printFlashChipSettings(self, buf=None):
    if buf is None:
      buf = self.getFlashChipSettings()
    vid, pid = self.getChipSettingsVIDPID(buf)
    mA       = self.getChipSettingsmA(buf)
    print("Struct Len: {:4d}".format   ( len(buf) ))
    print("Vendor  ID: {:04x}".format  ( vid      ))
    print("Product ID: {:04x}".format  ( pid      ))
    print("Power attr:   {:02x}".format( buf[ 8]  ))
    print("Current/mA: {:4d}".format   ( mA       ))
