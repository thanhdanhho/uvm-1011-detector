## READ ME UVM PROJECT DETECT 1011 
### Author Danh

```bash
cd sim/

# 1. Compile all sources
make compile

# 2. Run a single test
make run TEST=test_directed_1011 SEED=1

# 3. Run with custom parameters
make run TEST=test_overlap SEED=42 OVERLAP_EN=1 VERB=UVM_MEDIUM

# 4. Full regression (5 tests × 5 seeds = 25 runs)
make regress

# 5. Clean artifacts
make clean
```

---

## Quick Start — VCS

```bash
cd sim/

# 1. Compile
make compile_vcs

# 2. Run a single test
make run_vcs TEST=test_directed_1011 SEED=1

# 3. Random long test with a specific seed (reproducible)
make run_vcs TEST=test_random_long SEED=999 NUM_CYCLES=2000

# 4. Full regression
make regress_vcs
```



```bash
# GTKWave (open-source, best for VCD)
gtkwave waves/vcs/test_directed_1011_2_vcs.vcd &

# Verdi (if licensed, best for FSDB)
verdi -ssf waves/vcs/test_directed_1011_2_vcs.fsdb &

# VCS Native (accepts both formats)
dve -full64 -vpd waves/vcs/test_directed_1011_2_vcs.fsdb &
```


```bash
# QuestaSim GUI (native format)
vsim -view waves/questa/test_directed_1011_1_questa.wlf

# GTKWave
gtkwave waves/questa/test_directed_1011_1_questa.vcd &
```

**Wave files include**: `clk`, `rstn`, `in`, `out` (all DUT + interface signals).

---

Quick scan for results:
```bash
grep -E "TEST PASSED|TEST FAILED" logs/*.log
```

---

## Intentional Fail Debug (For Log Validation)

Use this mode when you want to force scoreboard mismatches and verify that
`SB_MISMATCH`, `SB_FAILPOINT`, and CSV export are working as expected.

```bash
cd sim/

# Force a known golden mismatch in scoreboard
make run TEST=test_directed_1011 SEED=1 DUMP_WAVE=0 \
	EXTRA_PLUSARGS="+SB_FAULT_INJECT=1 +SB_FAIL_PRINT_MAX=20"
```

Expected log IDs:
```bash
grep -E "SB_MISMATCH|SB_FAIL_GOLDEN|SB_FAILPOINT|SB_FAIL_CSV" logs/test_directed_1011_1_questa.log
```

CSV fail-point output (auto-generated when mismatches exist):
```bash
logs/<UVM_TESTNAME>_<SEED>_sb_failpoints.csv
# Example:
logs/test_directed_1011_1_sb_failpoints.csv
```

Optional plusargs:
```bash
+SB_FAIL_CSV=0
# Disable CSV generation

+SB_FAIL_CSV_FILE=../logs/custom_failpoints.csv
# Override CSV output path/name
```
