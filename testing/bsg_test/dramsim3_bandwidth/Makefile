export BASEJUMP_STL_DIR = $(abspath ../../..)
export BSG_CADENV_DIR = $(abspath ../../../../bsg_cadenv)
include $(BSG_CADENV_DIR)/cadenv.mk

INCDIR += +incdir+$(BASEJUMP_STL_DIR)/bsg_misc
INCDIR += +incdir+$(BASEJUMP_STL_DIR)/bsg_test

CFLAGS += -CFLAGS "-std=c++11 -g -Wall"
CFLAGS += -CFLAGS "-fPIC"
CFLAGS += -CFLAGS "-I$(BASEJUMP_STL_DIR)/imports/DRAMSim3/src"
CFLAGS += -CFLAGS "-I$(BASEJUMP_STL_DIR)/imports/DRAMSim3/ext/headers"
CFLAGS += -CFLAGS "-I$(BASEJUMP_STL_DIR)/imports/DRAMSim3/ext/fmt/include"
CFLAGS += -CFLAGS "-DFMT_HEADER_ONLY=1"
CFLAGS += -CFLAGS "-DCMD_TRACE"
CFLAGS += -CFLAGS "-DBASEJUMP_STL_DIR=$(BASEJUMP_STL_DIR)"

VCS_FLAGS = -full64 +lint=all,noSVA-UA,noSVA-NSVU,noVCDE +v2k -cpp g++
VCS_FLAGS += -sverilog -full64 -timescale=1ps/1ps +vcs+vcdpluson

SIMV = $(abspath simv)

simv:
	vcs $(VCS_FLAGS) -f sv.include -l vcs.log $(INCDIR) $(CFLAGS)

out/%/trace.tr:
	mkdir -p out
	mkdir -p out/$*
	python $*.py > $@

%.run: simv out/%/trace.tr
	(cd out/$*; $(SIMV) -l simv.log)

%.dve:
	dve -full64 -vpd out/$*/vcdplus.vpd &

clean:
	rm -rf csrc simv.daidir simv ucli.key vcdplus.vpd vc_hdrs.h DVEfiles
	rm -f vcs.log bsg_nonsynth_dramsim3_trace.txt dramsim3epoch.json
	rm -f trace.tr *.trace *.pyc
	rm -rf out
