# ==============================================================================
# Makefile — UVM Verification for det_1011 (Sequence Detector 1011)
# Supports : QuestaSim (vlog/vsim) and Synopsys VCS (vcs/simv)

SIM_DIR   := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
ROOT_DIR  := $(SIM_DIR)/..
TB_DIR    := $(ROOT_DIR)/tb
RTL_DIR   := $(ROOT_DIR)/rtl
TESTS_DIR := $(ROOT_DIR)/tests
LOGS_DIR  := $(ROOT_DIR)/logs
WAVES_DIR := $(ROOT_DIR)/waves

FILELIST  := $(SIM_DIR)/filelist.f
RUN_DO    := $(SIM_DIR)/run.do

# Compiled output for VCS
VCS_OUT   := $(SIM_DIR)/simv

TEST       ?= test_directed_1011
SEED       ?= 1
VERB       ?= UVM_LOW
OVERLAP_EN ?= 1
NUM_CYCLES ?= 1000
DUMP_WAVE  ?= 1           # 1 = dump waveform, 0 = skip

QUESTA_LOG   := $(LOGS_DIR)/$(TEST)_$(SEED)_questa.log
QUESTA_WAVE  := $(WAVES_DIR)/$(TEST)_$(SEED)_questa.vcd
VCS_LOG      := $(LOGS_DIR)/$(TEST)_$(SEED)_vcs.log
VCS_WAVE     := $(WAVES_DIR)/$(TEST)_$(SEED)_vcs.vcd

PLUSARGS := \
    +UVM_TESTNAME=$(TEST)         \
    +ntb_random_seed=$(SEED)      \
    +UVM_VERBOSITY=$(VERB)        \
    +OVERLAP_EN=$(OVERLAP_EN)     \
    +NUM_CYCLES=$(NUM_CYCLES)     \
    +DUMP_WAVE=$(DUMP_WAVE)

# -----------------------------------------------------------------------
# QuestaSim flags
# -----------------------------------------------------------------------
VLOG_FLAGS := \
    -sv                           \
    +incdir+$(TB_DIR)             \
    +incdir+$(TESTS_DIR)          \
    -L uvm

VSIM_FLAGS := \
    -c                            \
    -sv_seed $(SEED)              \
    -L uvm                        \
    +UVM_NO_RELNOTES              \
    $(PLUSARGS)                   \
    +WAVE_FILE=$(QUESTA_WAVE)

# -----------------------------------------------------------------------
# VCS flags
# -----------------------------------------------------------------------
VCS_COMPILE_FLAGS := \
    -sverilog                     \
    -ntb_opts uvm                 \
    +incdir+$(TB_DIR)             \
    +incdir+$(TESTS_DIR)          \
    -timescale=1ns/1ps            \
    -full64                       \
    -debug_access+all             \
    -o $(VCS_OUT)

VCS_RUN_FLAGS := \
    $(PLUSARGS)                   \
    +WAVE_FILE=$(VCS_WAVE)


REGRESSION_TESTS := \
    test_reset_basic        \
    test_directed_1011      \
    test_no_false_positive  \
    test_overlap            \
    test_random_long

REGRESSION_SEEDS := 1 2 3 42 100


.PHONY: all compile compile_questa compile_vcs \
        run run_vcs regress regress_vcs clean help \
        _ensure_dirs

# -----------------------------------------------------------------------
# Default
# -----------------------------------------------------------------------
all: compile


_ensure_dirs:
	@mkdir -p $(LOGS_DIR) $(WAVES_DIR)

compile compile_questa: _ensure_dirs
	@echo "================================================================"
	@echo "  [QUESTA] Compiling..."
	@echo "================================================================"
	vlib work
	vmap work work
	vlog $(VLOG_FLAGS) -f $(FILELIST) \
	    2>&1 | tee $(LOGS_DIR)/compile_questa.log
	@echo "  [QUESTA] Compile done. Log: $(LOGS_DIR)/compile_questa.log"

compile_vcs: _ensure_dirs
	@echo "================================================================"
	@echo "  [VCS] Compiling..."
	@echo "================================================================"
	vcs $(VCS_COMPILE_FLAGS) -f $(FILELIST) \
	    2>&1 | tee $(LOGS_DIR)/compile_vcs.log
	@echo "  [VCS] Compile done. Log: $(LOGS_DIR)/compile_vcs.log"

run: _ensure_dirs
	@echo "================================================================"
	@echo "  [QUESTA] Running TEST=$(TEST)  SEED=$(SEED)"
	@echo "================================================================"
	vsim $(VSIM_FLAGS) \
	    -do $(RUN_DO)  \
	    work.testbench \
	    2>&1 | tee $(QUESTA_LOG)
	@echo "  [QUESTA] Log:  $(QUESTA_LOG)"
	@echo "  [QUESTA] Wave: $(QUESTA_WAVE)"
	@grep -E "(TEST PASSED|TEST FAILED|UVM_ERROR|UVM_FATAL)" $(QUESTA_LOG) || true

run_vcs: _ensure_dirs
	@echo "================================================================"
	@echo "  [VCS] Running TEST=$(TEST)  SEED=$(SEED)"
	@echo "================================================================"
	$(VCS_OUT) $(VCS_RUN_FLAGS) \
	    2>&1 | tee $(VCS_LOG)
	@echo "  [VCS] Log:  $(VCS_LOG)"
	@echo "  [VCS] Wave: $(VCS_WAVE)"
	@grep -E "(TEST PASSED|TEST FAILED|UVM_ERROR|UVM_FATAL)" $(VCS_LOG) || true


regress: _ensure_dirs
	@echo "================================================================"
	@echo "  [QUESTA] Regression: $(words $(REGRESSION_TESTS)) tests × $(words $(REGRESSION_SEEDS)) seeds"
	@echo "================================================================"
	@pass=0; fail=0; \
	for t in $(REGRESSION_TESTS); do \
	    for s in $(REGRESSION_SEEDS); do \
	        echo "--- Running $$t seed=$$s ---"; \
	        log=$(LOGS_DIR)/$$t\_$$s\_questa.log; \
	        wave=$(WAVES_DIR)/$$t\_$$s\_questa.vcd; \
	        vsim -c -sv_seed $$s -L uvm +UVM_NO_RELNOTES \
	            +UVM_TESTNAME=$$t +ntb_random_seed=$$s \
	            +UVM_VERBOSITY=$(VERB) +OVERLAP_EN=$(OVERLAP_EN) \
	            +NUM_CYCLES=$(NUM_CYCLES) +DUMP_WAVE=$(DUMP_WAVE) \
	            +WAVE_FILE=$$wave \
	            -do $(RUN_DO) work.testbench \
	            2>&1 | tee $$log; \
	        if grep -q "TEST PASSED" $$log; then \
	            pass=$$((pass+1)); \
	            echo "  PASS: $$t seed=$$s"; \
	        else \
	            fail=$$((fail+1)); \
	            echo "  FAIL: $$t seed=$$s  (see $$log)"; \
	        fi; \
	    done; \
	done; \
	echo "================================================================"; \
	echo "  REGRESSION DONE: PASS=$$pass  FAIL=$$fail"; \
	echo "================================================================"; \
	test $$fail -eq 0


regress_vcs: _ensure_dirs
	@echo "================================================================"
	@echo "  [VCS] Regression: $(words $(REGRESSION_TESTS)) tests × $(words $(REGRESSION_SEEDS)) seeds"
	@echo "================================================================"
	@pass=0; fail=0; \
	for t in $(REGRESSION_TESTS); do \
	    for s in $(REGRESSION_SEEDS); do \
	        echo "--- Running $$t seed=$$s ---"; \
	        log=$(LOGS_DIR)/$$t\_$$s\_vcs.log; \
	        wave=$(WAVES_DIR)/$$t\_$$s\_vcs.vcd; \
	        $(VCS_OUT) \
	            +UVM_TESTNAME=$$t +ntb_random_seed=$$s \
	            +UVM_VERBOSITY=$(VERB) +OVERLAP_EN=$(OVERLAP_EN) \
	            +NUM_CYCLES=$(NUM_CYCLES) +DUMP_WAVE=$(DUMP_WAVE) \
	            +WAVE_FILE=$$wave \
	            2>&1 | tee $$log; \
	        if grep -q "TEST PASSED" $$log; then \
	            pass=$$((pass+1)); \
	            echo "  PASS: $$t seed=$$s"; \
	        else \
	            fail=$$((fail+1)); \
	            echo "  FAIL: $$t seed=$$s  (see $$log)"; \
	        fi; \
	    done; \
	done; \
	echo "================================================================"; \
	echo "  REGRESSION DONE: PASS=$$pass  FAIL=$$fail"; \
	echo "================================================================"; \
	test $$fail -eq 0

# -----------------------------------------------------------------------
# D) CLEAN
# -----------------------------------------------------------------------
clean:
	@echo "Cleaning generated files..."
	rm -rf work/ $(VCS_OUT) $(SIM_DIR)/simv.daidir csrc
	rm -rf $(LOGS_DIR)/*.log $(WAVES_DIR)/*.vcd $(WAVES_DIR)/*.wlf
	rm -f  transcript ucli.key vc_hdrs.h .vlocker
	@echo "Clean done."


help:
	@echo ""
	@echo "Usage:"
	@echo "  make compile                              Compile (QuestaSim)"
	@echo "  make compile_vcs                          Compile (VCS)"
	@echo "  make run TEST=<name> SEED=<n>             Run on QuestaSim"
	@echo "  make run_vcs TEST=<name> SEED=<n>         Run on VCS"
	@echo "  make regress                              Regression (Questa)"
	@echo "  make regress_vcs                          Regression (VCS)"
	@echo "  make clean                                Remove artifacts"
	@echo ""
	@echo "Runtime overrides:"
	@echo "  TEST=$(TEST)  SEED=$(SEED)  VERB=$(VERB)"
	@echo "  OVERLAP_EN=$(OVERLAP_EN)  NUM_CYCLES=$(NUM_CYCLES)  DUMP_WAVE=$(DUMP_WAVE)"
	@echo ""
	@echo "Available tests:"
	@for t in $(REGRESSION_TESTS); do echo "  $$t"; done
	@echo ""
