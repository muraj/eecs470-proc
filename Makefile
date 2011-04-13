# make          <- runs simv (after compiling simv if needed)
# make simv     <- compile simv if needed (but do not run)
# make int      <- runs int_simv interactively (after compiling it if needed)
# make syn      <- runs syn_simv (after synthesizing if needed then 
#                                 compiling synsimv if needed)
# make syn_int  <- runs syn_int_simv interactively (much like make syn)
# make clean    <- remove files created during compilations (but not synthesis)
# make nuke     <- remove all files created during compilation and synthesis
#
# To compile additional files, add them to the TESTBENCH or SIMFILES as needed
# Every .vg file will need its own rule and one or more synthesis scripts
# The information contained here (in the rules for those vg files) will be 
# similar to the information in those scripts but that seems hard to avoid.
# 

# Makefile processor customizations
MEM_SIZE=65536
EXTRA_DEFINES=+define+MEM_SIZE_IN_BYTES=$(MEM_SIZE)
ifdef MEM_LATENCY
	EXTRA_DEFINES+= +define+MEM_LATENCY=$(MEM_LATENCY)
endif
ifndef BRANCH_PREDICTION
	EXTRA_DEFINES+= +define+BRANCH_NOT_TAKEN
endif
ifdef ASSOC_DCACHE
	EXTRA_DEFINES+= +define+DCACHE_2WAY
endif
ifdef DEBUG_QUIT
	EXTRA_DEFINES+= +define+DEBUG_QUIT=$(DEBUG_QUIT)
endif
VCS = vcs +v2k +vc -Mupdate -line -full64 +vcs+loopreport $(EXTRA_DEFINES)
LIB = /usr/caen/generic/mentor_lib-D.1/public/eecs470/verilog/lec25dscc25.v
INTFLAGS = -I +memcbk

# For visual debugger
VISFLAGS = -lncurses

all:    simv
	echo $(EXTRA_DEFINES)
	./simv | tee program.out

##### 
# Modify starting here
#####

TESTBENCH = 	sys_defs.vh	    \
		testbench/testbench.v			\
		testbench/mem.v		    		\
		testbench/pipe_print.c
SIMFILES =	verilog/oo_pipeline.v	\
		verilog/icache.v	     \
		verilog/dcache.v	     \
		verilog/if_stage.v     \
		verilog/id_stage.v     \
		verilog/ex_stage.v     \
		verilog/alu.v			     \
		verilog/mult.v		     \
		verilog/mem_cont.v     \
		verilog/cachemem.v     \
		verilog/dcachemem.v    \
		verilog/rob.v			  	 \
		verilog/cb.v					 \
		verilog/superrs.v   	 \
		verilog/lsq.v       	 \
		verilog/rs.v				   \
    verilog/rattable.v     \
		verilog/rat.v					 \
		verilog/ps.v					 \
		verilog/pe.v					 \
		verilog/local_branch.v \
		verilog/regfile.v
SYNFILES = synth/oo_pipeline.vg

synth/oo_pipeline.vg:        $(SIMFILES) synth/pipeline.tcl synth/cachemem128x64.vg
	cd synth && dc_shell-t -f ./pipeline.tcl | tee pipeline_synth.out 

synth/cachemem128x64.vg:  verilog/cachemem.v
	cd synth && dc_shell-t -f ./icache.tcl | tee cachemem128x64_synth.out
 
#####
# Should be no need to modify after here
#####
simv:	$(SIMFILES) $(TESTBENCH)
	$(VCS) $(TESTBENCH) $(SIMFILES)	-o simv

int:	$(SIMFILES) $(TESTBENCH) 
	$(VCS) $(INTFLAGS) $(TESTBENCH) $(SIMFILES) -o int_simv -RI

syn_simv:	$(SYNFILES) $(TESTBENCH)
	$(VCS) $(TESTBENCH) $(SYNFILES) $(LIB) +define+SYNTH=1 -o syn_simv 

syn:	syn_simv
	./syn_simv | tee syn_program.out

syn_int:	$(SYNFILES) $(TESTBENCH)
	$(VCS) $(INTFLAGS) $(TESTBENCH) $(SYNFILES) $(LIB) -o syn_int_simv -RI

clean:
	@rm -rf simv simv.daidir csrc vcs.key program.out
	@rm -rf vis_simv vis_simv.daidir
	@rm -rf syn_simv syn_simv.daidir syn_program.out
	@rm -rf int_simv int_simv.daidir syn_int_simv syn_int_simv.daidir
	@rm -rf synsimv synsimv.daidir csrc vcdplus.vpd vcs.key synprog.out pipeline.out writeback.out vc_hdrs.h
	@(cd llvsimp4; make clean)

nuke:	clean
	@rm -rf *.out results.txt
	@rm -f synth/*.vg synth/*.rep synth/*.db synth/*.chk synth/command.log
	@rm -f synth/*.out synth/*.ddc command.log
	@rm -f synth/*.syn synth/*.mr synth/*.pvl synth/*.svf .vcsmx_rebuild
	@(cd llvsimp4; make nuke)
