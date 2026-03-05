<<<<<<< HEAD
# uvm-1011-detector
UVM Example Detect 1011
=======
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

---

## Runtime Plusargs

| Plusarg | Default | Description |
|---------|---------|-------------|
| `+UVM_TESTNAME=<name>` | — | Test class to run |
| `+ntb_random_seed=<n>` | 1 | RNG seed (makes random tests reproducible) |
| `+UVM_VERBOSITY=<lvl>` | UVM_LOW | Log verbosity (UVM_LOW / MEDIUM / HIGH / DEBUG) |
| `+OVERLAP_EN=<0\|1>` | 1 | 1 = overlap mode; 0 = non-overlap |
| `+NUM_CYCLES=<n>` | 1000 | Random test cycle count (min 1000 enforced) |
| `+DUMP_WAVE=<0\|1>` | 1 | Enable VCD waveform dump |
| `+WAVE_FILE=<path>` | auto | Override waveform output path |

---

## Test Descriptions

### `test_reset_basic`
Checks reset correctness:
1. Detects 1011 after initial power-on reset.
2. Injects a mid-simulation 3-cycle reset (`rstn=0`).
3. Detects 1011 again after reset recovery.

### `test_directed_1011`
Sends the exact bit sequence `0000 1011 0000`.  
Expects exactly **one** detection pulse from the scoreboard.

### `test_no_false_positive`
Sends near-miss patterns (`1010`, `1001`, `0111`, `1110`, `00000000`, `11111111`, `1010101010`).  
Expects **zero** detections. Any `dout=1` from DUT fails the scoreboard.

### `test_overlap`
- `OVERLAP_EN=1`: Sends `1011011` → expects **2 detections** (overlapping).
- `OVERLAP_EN=0`: Sends `1011 [6-cycle gap] 1011` → expects **2 detections** (separate).

### `test_random_long`
Drives ≥ 1000 random bits. The golden FSM scoreboard verifies every cycle.  
Same `SEED` always produces the same bit stream (deterministic regression).

---

## Scoreboard — Golden Model

The scoreboard implements a behavioral FSM mirror:

```
IDLE  --1--> S1 --0--> S10 --1--> S101 --1--> S1011 (dout=1)
             ^                      ^             |
             +--- 1 (self-loop) ----+             +--1--> S1
                                                  +--0--> S10
```

**Per-cycle algorithm:**
1. Compute `expected_dout` = (`g_state == G_S1011`)
2. Compare vs `tr.dout` from monitor
3. Advance `g_state` via `gold_next()`

**Mismatch log format:**
```
MISMATCH @ cycle=42 | history[7:0]=01101011 | rstn=1 | din=1 | expected_dout=1 | actual_dout=0 | golden_state=S101
```

---

## Waveform Viewing

```bash
# QuestaSim GUI
vsim -view waves/test_directed_1011_1_questa.vcd

# GTKWave (open-source)
gtkwave waves/test_directed_1011_1_questa.vcd &

# VCS + Verdi (if licensed)
verdi -ssf waves/test_directed_1011_1_vcs.fsdb &
```

Waveform includes: `clk`, `rstn`, `in`, `out` (all DUT + interface signals).

---

## Injecting DUT Bugs (Debug Verification)

To verify the scoreboard catches bugs, modify `rtl/dut_1011.sv`:

```systemverilog
// Bug: wrong transition from S1011 (break overlap)
S1011: next_state = in ? S1011 : IDLE;  // ← wrong: should be S1 / S10
```

Re-run any test → scoreboard will report:
```
UVM_ERROR @ SB_MISMATCH: MISMATCH @ cycle=... history=... expected=X actual=Y
TEST FAILED: test_directed_1011 (errors=1)
```

---

## Log Files

All logs land in `logs/` with format `<TEST>_<SEED>_<tool>.log`:

```
logs/
├── compile_questa.log
├── compile_vcs.log
├── test_directed_1011_1_questa.log
├── test_random_long_42_vcs.log
└── ...
```

Quick scan for results:
```bash
grep -E "TEST PASSED|TEST FAILED" logs/*.log
```
>>>>>>> b7ec471 (Initial commit)
