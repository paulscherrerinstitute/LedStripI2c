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

The control register provides the following functionality
(Defaults marked with 'G' can be changed by setting a VHDL generic)

| Bit Range| Default           | Function                                               |
|----------|-------------------|--------------------------------------------------------|
| [31:24]  | set for 400kHz (G)| Clock divider for generating SCL (see below)           |
| [23:20]  | 0                 | Multiplexer to select update trigger                   |
| [18]     | 1 (G)             | Enable Marker.                                         |
| [17]     | 0                 | Enable binary encoding of display (Gray-code otherwise)|
| [16]     | 0                 | Reset firmware block (held in reset while bit is set)  |
| [15:08]  | 255               | Brightness PWM setting for PCA9955                     |
| [07:00]  | 128               | Brightness IREF current setting for PCA9955            |

### Clock Divider
The i2c SCL clock is derived from the bus clock fed into the firmware module.

    SCL_clock = Bus_clock / divider_value / 4

The divider value is computed from the corresponding 8 bits in the control register.
If the most-significant bit of the divider value is set then bits [7:0] define the
divider value verbatim, e.g.,

    0xC0 => divider value 0x40 => SCL freq. = bus-freq / 64 / 4

If the MSbit is clear then the divider is taken from a table of larger values (consult
the firmware sources for details).

### Trigger Multiplexer
The firmware has 16 inputs for (Evr-generated) triggers which can be used to decimate
the rate at which the display updates (useful for slow cameras). The multiplexer selects
one of these triggers. By default trigger #0 is permanently asserted 1 (which results in
the display updating every time a new pulse-ID streams out of the EVR) and trigger #1 is
permanently asserted 0 (which results in the display not updating).

### Marker
If the marker is enabled then the displayed pulse-ID is shifted left by one bit and ORed
with a mask (contents of register R1):

    displayed_pattern :=  (pulse_id << 1) | mask

This feature can be used to permanently light some 'marker' LEDs. If the marker is disabled
then register R1 is ignored.

### Encoding
The pulse-ID can be displayed in binary- or gray-encoding. The latter has obvious advantages
when capturing the display with a camera. If exposure-time overlaps the change of the pulse-ID
then the relative brightness of the changing LED confers some information about the timing of
the shutter. It also avoids any ambiguity of a not properly synchronized readout.

### Reset
While this bit is asserted the firmware block (including the i2c controller) is held in reset.
Note that the reset does not extend to the remote PCA9955 LED controllers.

### PWM and IREF
The PCA9955 supports controlling LED brightness by two (cumulative) methods: PWM at a frequency
of multiple kHz as well as modulating an analog current source. Both parameters can be programmed
in the control register.

*NOTE*: The i2c transactions required to change the brightness are interleaved with updating
        the pulse-ID.  I.e., if the pulse-ID does not update (e.g., because the trigger mux
        selects the permanently disabled trigger) then the brightness settings are not forwarded
        to the PCA9955 controllers either. Similarly, if the update rate is reduced then changes
        to the brightness take longer to be forwarded to the PCA9955 (after each pulse-ID update
        *one* brightness setting for *one* LED is transmitted, e.g., it takes 64 pulse-ID updates
        to forward the PWM and IREF to all 32 channels in the PCA9955 devices).

### Error counters
The counters keep track of

 - Lost i2c arbitrations. Because normally (i.e., unless the USB-i2c bridge or the PMOD connector
   are in active use) there are no other bus masters these errors are most likely caused by too
   high a SCL frequency or non-optimal filter settings (only tunable via generics). Try lowering
   the i2c SCL frequency.
 - Unacknowledged i2c transactions. This occurs most likely because the LedStrip hardware module
   is not connected or intermediate entities (e.g., GPIO ports) are not configured correctly.
 - Readback errors. The readback failed or readback data does not match the expected value (e.g.,
   because a glitch on the i2c bus). An unacknowledged transaction error also implies a readback
   error but the converse is not true.

The readback error counter can be used to ensure that all pulse-IDs have been propagated
correctly to the display hardware.



