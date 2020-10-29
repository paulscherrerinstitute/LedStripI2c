# Bar-graph Display Project

Display current pulse-ID on a LED-bar.
The LEDs are driven by PCA9955 LED controllers
and remote-controlled by I2C over a fiber
connection.

 - [kicad/](kicad/)   [schematics](kicad/ledstrip-sch.pdf) and pcb
 - [hdl/](hdl/)       vhdl code for driving the device from a FPGA
                      ([documentation](hdl/README.md)).
 - [python/](python/) python scripts to drive the device from the USB/I2C
                      adapter (for testing).

The LED device's I2C bus is accessible by three methods:

 - optical (light <-> logic 'low' on I2C bus) 
 - PMOD connector (1.5-3.3 V via i2c-transceiver) for
   connection, e.g., to a Zynq board.
 - USB-I2c bridge from host.

Note that in all use-cases power (5V, 350mA max.) must be
provided at the USB port (from host or USB wall-wart).

A mini-USB connector was deemed mechanically more stable than
micro-USB. USB-C would be an alternative.

Till Straumann, 10/2020.
