# vcs Makefile
RTL_DIR	=	./rtl
TB_DIR	=	./tb
BUILD_DIR =	./build
INC_DIR	=	+incdir+$(RTL_DIR)
SIMV_DIR	=	./build/simv
SIMV_OPTS	:=	-cm line+cond+fsm+tgl+branch+assert -cm dir	coverage.vdb -cm_name sim1
SIMV_OPTS	+=	+UVM_VERBOSITY=UVM_HIGH


run:
	mkdir	-p $(BUILD_DIR)
	vcs -full64 -sverilog -debug_access+all -kdb -lca \
		-timescale=1ns/1ps \
		-ntb_opts uvm-1.2 \
		-o $(SIMV_DIR) $(RTL_DIR) ./rtl/counter.sv ./tb/tb_counter.sv

simv:
	$(SIMV_DIR) $(SIMV_OPTS)

verdi:
	verdi -dbdir $(BUILD_DIR)/simv.daidir -ssf ./wave.fsdb &



clean:
	rm -rf $(BUILD_DIR) csrc novas* ucli.key verilog files.f *.fsdb inter.fsdb .inter.fsdb.tbsim sys*

.PHONY: all vcs simv verdi clean
