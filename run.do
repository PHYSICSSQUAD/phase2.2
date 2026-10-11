# 🔥 NEW (MUL/DIV integration) - compile + run the main UVM testbench on Questa / ModelSim.
# 🔥 Usage (from the repo root):   vsim -c -do "do run.do"
# 🔥 Optional environment variables:
# 🔥   UVM_SRC      : path to UVM-1.2 "src" folder
# 🔥                  (default: $MODEL_TECH/../verilog_src/uvm-1.2/src)
# 🔥   UVM_TEST     : test name (default: test_random, which top.sv already runs)
# 🔥   TB_ROOT      : repo root, only needed when not running from the repo root
# 🔥   DPI_CPP_PATH : full path to a Questa-compatible C/C++ compiler executable;
# 🔥                  set this if vsim reports vsim-7019 during DPI export compilation
# 🔥 Exit code: 0 = no UVM_ERROR / UVM_FATAL / simulator error, 1 otherwise.

# 🔥 helper: stop with exit code 1 on any failing command
proc die {msg} {
    echo "RUN.DO ERROR: $msg"
    quit -code 1 -f
}
proc run_or_die {cmd} {
    if {[catch {uplevel #0 $cmd} msg]} { die "'[lindex $cmd 0]' failed: $msg" }
}

# 🔥 repo root = folder with tb/top.sv (current dir, $TB_ROOT, or this script's folder)
set ROOT [pwd]
if {![file exists $ROOT/tb/top.sv] && [info exists ::env(TB_ROOT)]} {
    set ROOT [file normalize $::env(TB_ROOT)]
}
if {![file exists $ROOT/tb/top.sv]} {
    catch {set ROOT [file dirname [file normalize [info script]]]}
}
if {![file exists $ROOT/tb/top.sv]} { die "run from the repo root or set TB_ROOT (tb/top.sv not found)" }

# 🔥 UVM location
if {[info exists ::env(UVM_SRC)]} {
    set UVM [file normalize $::env(UVM_SRC)]
} else {
    set UVM [file normalize $::env(MODEL_TECH)/../verilog_src/uvm-1.2/src]
}
if {![file exists $UVM/uvm_pkg.sv]} { die "UVM not found at $UVM (set UVM_SRC)" }
echo "RUN.DO: ROOT=$ROOT"
echo "RUN.DO: UVM =$UVM"

# 🔥 fresh work library
if {[file exists work]} { catch {vdel -all -lib work} }
run_or_die {vlib work}

# 🔥 1) UVM with its optional DPI imports disabled. Some Questa builds can still
# 🔥 generate DPI export wrappers during elaboration; those need a compatible C/C++ compiler.
run_or_die [list vlog -sv -work work +define+UVM_NO_DPI +incdir+$UVM $UVM/uvm_pkg.sv]

# 🔥 2) RTL packages
run_or_die [list vlog -sv -work work \
    $ROOT/rtl/package/cv32e40p_apu_core_pkg.sv \
    $ROOT/rtl/package/cv32e40p_fpu_pkg.sv \
    $ROOT/rtl/package/cv32e40p_pkg.sv]

# 🔥 3) RTL. A prelude is still needed: cv32e40p_core.sv / decoder.sv / alu.sv /
# 🔥 controller.sv use package types without importing them. The prelude imports
# 🔥 the packages into the compilation unit ($unit) of the RTL files only (-mfcu).
# 🔥 The latch register file is excluded (duplicate module cv32e40p_register_file),
# 🔥 design.sv is excluded (not part of the core).
set PRELUDE [file join [pwd] rtl_prelude_autogen.sv]
set fh [open $PRELUDE w]
puts $fh "import cv32e40p_pkg::*;"
puts $fh "import cv32e40p_apu_core_pkg::*;"
close $fh
set RTL_FILES {}
foreach f [lsort [glob -directory $ROOT/rtl *.sv]] {
    set n [file tail $f]
    if {$n eq "cv32e40p_register_file_latch.sv" || $n eq "design.sv"} { continue }
    lappend RTL_FILES $f
}
run_or_die [concat [list vlog -sv -work work -mfcu $PRELUDE] $RTL_FILES]
file delete -force $PRELUDE

# 🔥 4) Testbench (agents + interfaces + bind are pulled in by tb/top.sv includes)
set TB_INC {}
foreach d {tb tb/agents/base tb/agents/instruction tb/agents/data tb/agents/reset \
           tb/agents/debug tb/agents/mul tb/environment tb/test tb/virtual_sequences} {
    lappend TB_INC +incdir+$ROOT/$d
}
run_or_die [concat [list vlog -sv -work work +define+UVM_NO_DPI+MUL_NO_COVERGROUP +incdir+$UVM] \
                   $TB_INC [list $ROOT/tb/top.sv]]

# 🔥 5) Simulate. -suppress 19: ModelSim looks for an "mtiUvm" library it does not need.
set TEST test_random
if {[info exists ::env(UVM_TEST)]} { set TEST $::env(UVM_TEST) }
set LOG [file join [pwd] run_sim.log]
set SIM_CMD [list vsim -c -onfinish stop -suppress 19 -l $LOG]
if {[info exists ::env(DPI_CPP_PATH)] && [string trim $::env(DPI_CPP_PATH)] ne ""} {
    # Point Questa at its bundled/supported compiler when it cannot find one itself.
    lappend SIM_CMD -dpicpppath $::env(DPI_CPP_PATH)
    echo "RUN.DO: DPI compiler=$::env(DPI_CPP_PATH)"
}
lappend SIM_CMD work.top +UVM_TESTNAME=$TEST +UVM_NO_RELNOTES
run_or_die $SIM_CMD
onbreak {resume}
run -all
catch {transcript flush}

# 🔥 6) Pass / fail from the simulation log
set fh [open $LOG r]
set txt [read $fh]
close $fh
set n_err -1
set n_fat -1
regexp {UVM_ERROR\s*:\s*(\d+)} $txt -> n_err
regexp {UVM_FATAL\s*:\s*(\d+)} $txt -> n_fat
set sim_fatal [regexp {\*\* (Fatal|Error)} $txt]
if {[regexp {Checked : (\d+)\s+PASS : (\d+)\s+FAIL : (\d+)} $txt -> c p f]} {
    echo "RUN.DO: MUL scoreboard Checked=$c PASS=$p FAIL=$f"
}
echo "RUN.DO: UVM_ERROR=$n_err UVM_FATAL=$n_fat simulator_error=$sim_fatal"
if {$n_err != 0 || $n_fat != 0 || $sim_fatal} {
    echo "RUN.DO: TEST FAILED"
    quit -code 1 -f
}
echo "RUN.DO: TEST PASSED"
quit -code 0 -f
