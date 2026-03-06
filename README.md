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
>>>>>>> b7ec471 (Initial commit)
