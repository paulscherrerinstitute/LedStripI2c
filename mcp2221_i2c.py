#!/usr/bin/python3

import usb1

class LedStrip:
  def __init__(self, ctx):
    self.ctx_ = ctx
    self.hdl_ = self.ctx_.openByVendorIDAndProductID(0x4d8, 0x00dd, skip_on_error=True)
    if self.hdl_ is None:
      raise RuntimeError("LedStrip USB device not found")

with usb1.USBContext() as ctx:
  lstr = LedStrip( ctx )
