# Makefile automatically generated by ghdl
# Version: GHDL 1.0-dev (v0.37.0) [Dunoon edition] - mcode code generator
# Command used to generate this makefile:
# ghdl --gen-makefile LedStripControllerTb

GHDL=ghdl
GHDLFLAGS=
GHDLRUNFLAGS= --wave=dump.ghw

dflt:
	@echo "Must specify a target: e.g., 'all', 'run' or 'test'"
	@echo " -> 'test' "

# Default target : elaborate
all : elab

# Elaborate target.  Almost useless
elab : force
	$(GHDL) -c $(GHDLFLAGS) -e ledstripcontrollertb

test.log: RUNOUT= > test.log
test.log: GHDLRUNFLAGS=

test.log: run

test.inp: test.log
	sed -n -e 's/^.*@//p' $< > $@

comp.inp: ledStripControllerTb.dataOK
	sed -n -e 's/^.*@//p' $< > $@

.INTERMEDIATE: comp.inp test.inp

test: test.inp comp.inp
	@if ! diff $^; then echo "Test FAILED"; else echo "Test PASSED"; fi

# Run target
run : force
	$(GHDL) -c $(GHDLFLAGS) -r ledstripcontrollertb $(GHDLRUNFLAGS) $(RUNOUT)

# Targets to analyze libraries
init: force
	# /opt/ghdl/v0.37/lib/ghdl/ieee/v93/../../src/ieee/v93/std_logic_1164.vhdl
	# /opt/ghdl/v0.37/lib/ghdl/ieee/v93/../../src/ieee/v93/std_logic_1164-body.vhdl
	# /opt/ghdl/v0.37/lib/ghdl/ieee/v93/../../src/ieee/v93/numeric_std.vhdl
	# /opt/ghdl/v0.37/lib/ghdl/ieee/v93/../../src/ieee/v93/numeric_std-body.vhdl
	# /opt/ghdl/v0.37/lib/ghdl/std/v93/../../src/std/v93/textio.vhdl
	# /opt/ghdl/v0.37/lib/ghdl/std/v93/../../src/std/v93/textio-body.vhdl
	# /opt/ghdl/v0.37/lib/ghdl/ieee/v93/../../src/ieee/math_real.vhdl
	# /opt/ghdl/v0.37/lib/ghdl/ieee/v93/../../src/ieee/math_real-body.vhdl
	$(GHDL) -a $(GHDLFLAGS) StdRtlPkg.vhd
	$(GHDL) -a $(GHDLFLAGS) TextUtilPkg.vhd
	$(GHDL) -a $(GHDLFLAGS) ../MpcI2cSequencerPkg.vhd
	$(GHDL) -a $(GHDLFLAGS) ../ioxos_mpc_master_i2c_ctl_pkg.vhd
	$(GHDL) -a $(GHDLFLAGS) ../ioxos_mpc_master_i2c_ctl.vhd
	$(GHDL) -a $(GHDLFLAGS) ../InpDebouncer.vhd
	$(GHDL) -a $(GHDLFLAGS) ../MpcI2cSequencer.vhd
	$(GHDL) -a $(GHDLFLAGS) ../LedStripController.vhd
	$(GHDL) -a $(GHDLFLAGS) LedStripControllerTb.vhd
	$(GHDL) -a $(GHDLFLAGS) ila_dummy.vhd
	$(GHDL) -a $(GHDLFLAGS) I2cPkg.vhd
	$(GHDL) -a $(GHDLFLAGS) stdlib.vhd
	$(GHDL) -a $(GHDLFLAGS) I2cSlave.vhd
	$(GHDL) -a $(GHDLFLAGS) I2cRegSlave.vhd
	$(GHDL) -a $(GHDLFLAGS) i2cRegSlaveWrap.vhd

.PHONY: force clean

clean:
	$(RM) test.log work-*.cf
