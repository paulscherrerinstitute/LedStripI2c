# LedStrip Firmware

Extract the pulse-ID from a data stream (input) that 
originates at an (external) EVR320. Drive two PCA9955
LED controllers over i2c to display the pulse-ID as a
binary number (LED bar).

## Features

The firmware implements the following features:

 - tosca2/TCSR compatible register interface
 - controllable LED brightness.
 - programmable I2C speed.
 - readback verification: the firmware reads the displayed
   value back and increments an error counter if the readback
   does not match the expected value (catch potential i2c errors).
 - support permanently lit 'marker' LEDs.
 - display pulse-ID as gray-encoded or binary number.
 - error/status counters.

## Register Map

All registers are 32-bit. The address given in this table is
the register index (= word-address), not a byte address:

| Register   | Access | Function                          |
|------------|--------|-----------------------------------|
|  0         | R/W    | Control Register                  |
|  1         | R/W    | Marker/Mask                       |
|  2         | RO     | I2C Arbitration Lost Counter      |
|  3         | RO     | I2C Write Not Acknowledged Counter|
|  4         | RO     | Readback Error/Mismatch Counter   |

