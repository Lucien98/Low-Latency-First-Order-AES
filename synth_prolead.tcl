# 
# Copyright (C) 2025 Feng Zhou
# 
# 
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
# 

set IN_FILES       [regexp -all -inline {\S+} $::env(IN_FILES)]
set TOP_MODULE     $::env(TOP_MODULE)
set OUT_BASE       $::env(OUT_BASE)
set LIBERTY        $::env(LIBERTY)

if {[info exists env(SHARES)]} {
    set SHARES $::env(SHARES)
} else {
    set SHARES ""
}

if {[info exists env(LATENCY)]} {
    set LATENCY $::env(LATENCY)
} else {
    set LATENCY ""
}

foreach file $IN_FILES {
    yosys read_verilog -defer  $file
}

if {![string equal "" $SHARES]} {
    yosys chparam -set d [expr $SHARES] $TOP_MODULE
}

if {![string equal "" $LATENCY]} {
    yosys chparam -set LATENCY [expr $LATENCY] $TOP_MODULE
}

yosys read_verilog -lib $LIBERTY.v

yosys setattr -set keep_hierarchy 1

yosys synth -top $TOP_MODULE

yosys dfflibmap -liberty $LIBERTY.lib

yosys abc -liberty $LIBERTY.lib

yosys opt_clean

yosys stat -liberty $LIBERTY.lib

yosys setattr -set keep_hierarchy 0
yosys flatten

yosys select $TOP_MODULE
yosys insbuf -buf BUF A Y

yosys write_verilog -noattr -selected $OUT_BASE/design.v
