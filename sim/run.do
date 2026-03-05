# ==============================================================================
# run.do — QuestaSim run script (sourced by vsim command line)
# Called by Makefile run target.  vsim passes variables as -G/-do args.
# ==============================================================================

# Wave capture (if enabled by Makefile)
if { [info exists ::env(WAVE_FILE)] && [string length $::env(WAVE_FILE)] > 0 } {
    vcd file $::env(WAVE_FILE)
    vcd add -r /*
    echo "Waveform: $::env(WAVE_FILE)"
}

# Run simulation to completion then quit (batch mode: -c flag suppresses GUI)
run -all
quit -f
