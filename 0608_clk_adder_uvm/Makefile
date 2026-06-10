VCS_OPTS  = -full64 -sverilog
VCS_OPTS += -ntb_opts uvm-1.2
VCS_OPTS += -timescale=1ns/1ps 
VCS_OPTS += -debug_access+all -kdb -lca
VCS_SRC_FILES = ./rtl/adder.sv ./tb/tb_adder.sv
VCS_OUTPUT = -o simv

SIMV_OPTS  = + UVM_TESTNAME=adder_test
SIMV_OPTS += + UVM_VERBOSITY=UVM_MEDIUM
SIMV_OPTS += + ntb_random_seed = 1234

.PHONY: compile simv clean

compile:
	@vcs $(VCS_OPTS) $(VCS_SRC_FILES) $(VCS_OUTPUT)
	@echo "타겟 [$@]"
simv: compile
	@./simv $(SIMV_OPTS)
	@echo "의존 타겟 [$<]"
	@echo "타겟 [$@]"
clean:
	@rm -rf simv* csrc *.log *.key *.h
	@echo "결과물 정리 완료"