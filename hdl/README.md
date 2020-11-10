# LedStrip Firmware

Extract the pulse-ID from a data stream (input) that 
originates at an embedded EVR320 module (the EVR320
is not instantiated within this LedStrip module).
Drive two PCA9955 LED controllers over i2c to display
the pulse-ID as a binary number (LED bar).

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

## Register Map (Version 0)

All registers are 32-bit. The address given in this table is
the register index (= word-address), not a byte address:

| Register   | Access | Function                             |
|------------|--------|--------------------------------------|
|  0         | RO     | Version Register                     |
|  1         | R/W    | Control Register                     |
|  2         | R/W    | Marker/Mask                          |
|  3         | RO     | I2C Arbitration Lost Counter         |
|  4         | RO     | I2C Write Not Acknowledged Counter   |
|  5         | RO     | Readback Error/Mismatch Counter      |
|  6         | RO     | Pulse-Id Sequence Error Counter      |
|  7         | RO     | Pulse-Id Watchdog Error Counter      |
|  8         | RO     | Display-update Trigger Counter       |
|  9         | RO     | Stream Synchronization Error Counter |

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

### Version Register
The least-significant 4 bits of the version register define the version
of the register layout (version 0 described in this document).
The most-significant 28 bits optionally contain a (binary-encoded) git
hash (all-zero when unused).

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
with a mask (contents of register R2):

    displayed_pattern :=  (pulse_id << 1) | mask

This feature can be used to permanently light some 'marker' LEDs. If the marker is disabled
then register R2 is ignored.

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
 - Pulse-Id sequence errors. This counter is incremented when the difference between
   subsequently received pulse-ids is not 1.
 - Watchdog errors: Check that a new pulse-ID is received from the EVR stream within 12 ms
   (this timeout value is a generic setting).
 - Trigger counter: This counter increments when the display update is triggered (which
   may happen at a rate that is lower than the pulse-Id update rate if the update trigger
   inputs are used).
 - EVR Stream Synchronization Errors. Checks that all bytes corresponding to a pulse-ID are
   actually received from the EVR stream. 

The readback error counter can be used to ensure that all pulse-IDs have been propagated
correctly to the display hardware. The watchdog error counter can be used to verify that
pulse-Ids are received and the sequence error counter can be used to verify that the
received pulse-Ids are sequential.

## Firmware Module

The top level entity is defined in [LedStripTcsrWrapper.vhd](LedStripTcsrWrapper.vhd).

### Dependencies

The module requires the [PulseidExtractor](https://github.com/paulscherrerinstitute/PulseIdExtractor.git)
which is registered as a submodule.

### Generics

Most of the generics have reasonable default values but a value for the bus frequency must
be supplied by the user.

| Generic                |Default Value| Description                                          |
|------------------------|-------------|------------------------------------------------------|
|  TCSR_CLOCK_FRQ_G      |             | Bus Frequency (Hz)                                   |
|  DFLT_I2C_SCL_FRQ_G    | 400.0E3     | Default SCL Frequency (Hz)                           |
|  PULSEID_OFFSET_G      | 52          | Starting offset of pulse-id in EVR stream            |
|  PULSEID_LENGTH_G      |  8          | Size of pulse-id (in bytes)                          |
|  PULSEID_BIGEND_G      | false       | Representation in EVR stream (big- vs. little-endian)|
|  ASYNC_CLOCKS_G        | true        | Whether the bus- and evr-clocks are asynchronous     |
|  I2C_ADDR_R_G          | "0000101"   | I2C (7-bit) address of RHS PCA9955                   |
|  I2C_ADDR_L_G          | "1101001"   | I2C (7-bit) address of LHS PCA9955                   |
|  I2C_SYNC_STAGES_G     | 3           | How many synchronizer stages on SCL/SDA inputs       |
|  I2C_DEBOUNCE_CYCLES_G | 10          | For how many bus-cycles to debounce SCL/SDA inputs   |
|  NUM_LEDS_G            | 30          | How many LEDs are physically loaded on the board     |
|  DFLT_MARKER_ENABLE_G  | '1'         | Default value of marker-enable bit in R0             |
|  PULSEID_WDOG_PER_MS_G | 12.0        | Pulse-Id watchdog timeout [ms]; disabled when 0.0    |
|  VERSION_G             | x"000_0000" | Firmware Version ID (e.g., git-hash)                 |

*Note*: The i2c addresses of the PCA9955 controllers is defined by hardware straps on the board
        but there are *slightly different versions of the PCA9955* which interpret the strapping
        differently (PCA9955 vs. PCA9955B). Consult the KiCad schematics and hardware manuals for
        details.

### Ports

The module's ports are listed in the following table. Signals are in the clock-domain of the last
clock previously listed.

|  Signal   |     Type/Default                             | Description       |
|-----------|----------------------------------------------|-------------------|
|  tcsrCLK  | in  std_logic                                |  Bus clock        |
|  tcsrRST  | in  std_logic                                |  Synchronous reset|
|  tcsrADD  | in  std_logic_vector( 4 downto 2)            |  (Word-) address  |
|  tcsrDATW | in  std_logic_vector(31 downto 0)            |  Write data       |
|  tcsrWE   | in  std_logic_vector( 3 downto 0)            |  Lane write-enable|
|  tcsrDATR | out std_logic_vector(31 downto 0)            |  Read data        |
|  tcsrWR   | in  std_logic                                |  Write strobe     |
|  tcsrRD   | in  std_logic                                |  Read strobe      |
|  tcsrACK  | out std_logic                                |  ACK (always '1') |
|  tcsrERR  | out std_logic                                |  ERR (always '0') |
|  sclInp   | in  std_logic                                |  i2c SCL input    |
|  sclOut   | out std_logic                                |  i2c SCL output   |
|  sdaInp   | in  std_logic                                |  i2c SDA input    |
|  sdaOut   | out std_logic                                |  i2c SDA output   |
|  evrClk   | in  std_logic                                |  EVR clock        |
|  evrStream| in  EvrStreamType                            |  EVR data stream  |
|  ledTrig  | in  std_logic_vector(15 downto 0) := x"0001" |  Update trigger   |

### Constraints

If the bus- and evr- clocks are asynchronous then some details need to be
considered: There are two clock-domain crossings in the module

 - The pulse-ID is taken from the `evrClk` into the `tcsrCLK` domain. If the
   `ASYNC_CLOCKS_G` generic is set to `true` then a synchronizer stage is
   instantiated which synchronizes and delays the pulse-ID strobe signal until
   the (parallel) pulse-ID has stabilized and can be safely read into the `tcslCLK`
   domain. A proper `DATAPATHONLY` constraint should be defined:

       INST "*B_PulseIdExtractor.U_GetPid/rClk_pulseid_*" TNM = LEDSTRIP_PULSEID_REG;
       TIMESPEC TS_<name> = FROM "LEDSTRIP_PULSEID_REG" TO <tnm_of_bus_clock_domain> <delay> DATAPATHONLY;

   The user has to provide proper definitions for the items in angled-brackets. The
   maximum datapath delay should limit any delay to less than the two bus-cycles delay
   of the strobe signal. Some margin needs to allocated to possible clock skew!

 - The trigger multiplexer setting crosses from the `tcsrCLK` into the `evrCLK` domain.
   Assuming that this setting remains mostly stable and we don't care about glitches
   during a change of the mux setting we can set a false-path:

       INST "*B_PulseIdExtractor.trgMuxEvr_*"          TNM = LEDSTRIP_MUX_REG;
       TIMESPEC TS_<name> = FROM <tnm_of_bus_clock_domain> TO "LEDSTRIP_MUX_REG" TIG;
