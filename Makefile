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


clean:
	rm -rf syn

SHARES ?= 2
ORDER := $(shell expr $(SHARES) - 1)

N ?= 5
MAX_ORDER = $(shell expr $(N) - 1)

resdir:
	mkdir -p syn/low_lat_41/prolead/MSKaes_128bits_round_based
	mkdir -p syn/low_lat_31/prolead/MSKaes_128bits_round_based
	mkdir -p syn/low_lat_41/full_aes/MSKaes_128bits_round_based
	mkdir -p syn/low_lat_31/full_aes/MSKaes_128bits_round_based
	mkdir -p syn/low_lat_41/full_aes/wrapper_aes128
	mkdir -p syn/low_lat_31/full_aes/wrapper_aes128
	mkdir -p syn/low_lat_41/sbox/stage1
	mkdir -p syn/low_lat_41/sbox/stage23
	mkdir -p syn/low_lat_41/sbox/sqscmul
	mkdir -p syn/low_lat_31/sbox/

IA_DEF ?= 0

three_stage_sbox:
	IN_FILES="$(shell find low_lat_41/sbox_ti -type f -name "*.v" ! -name "tb_*.v")" \
	TOP_MODULE="three_stage_sbox" \
	OUT_BASE="syn/low_lat_41/sbox/" \
	LIBERTY="stdcells.lib" \
	yosys synth.tcl -t -l "syn/low_lat_41/sbox/log.txt"

two_stage_sbox:
	IN_FILES="$(shell find low_lat_31/sbox_ti -type f -name "*.v" ! -name "tb_*.v")" \
	TOP_MODULE="two_stage_sbox" \
	OUT_BASE="syn/low_lat_31/sbox/" \
	LIBERTY="stdcells.lib" \
	yosys synth.tcl -t -l "syn/low_lat_31/sbox/log.txt"

sbox_stage%:
	IN_FILES="$(shell find low_lat_41/sbox_ti -type f -name "*.v" ! -name "tb_*.v")" \
	TOP_MODULE="Stage$*_opt" \
	OUT_BASE="syn/low_lat_41/sbox/stage$*" \
	LIBERTY="stdcells.lib" \
	yosys synth.tcl -t -l "syn/low_lat_41/sbox/stage$*/log.txt"

sqscmul:
	IN_FILES="$(shell find low_lat_41/sbox_ti -type f -name "*.v" ! -name "tb_*.v")" \
	TOP_MODULE="GF16_sqscmul" \
	OUT_BASE="syn/low_lat_41/sbox/sqscmul" \
	LIBERTY="stdcells.lib" \
	yosys synth.tcl -t -l "syn/low_lat_41/sbox/sqscmul/log.txt"


low_lat_%/full_aes/wrapper_aes128:
	IN_FILES="$(shell find low_lat_$* -type f -name "*.v" ! -name "tb_*.v")" \
	SHARES=$(SHARES) \
	TOP_MODULE="wrapper_aes128" \
	OUT_BASE="syn/low_lat_$*/full_aes/wrapper_aes128/" \
	LIBERTY="stdcells.lib" \
	yosys synth.tcl -t -l "syn/low_lat_$*/full_aes/wrapper_aes128/log.txt"

low_lat_%/full_aes/MSKaes_128bits_round_based:
	IN_FILES="$(shell find low_lat_$* -type f -name "*.v" ! -name "tb_*.v")" \
	SHARES=$(SHARES) \
	LATENCY=$(LATENCY) \
	TOP_MODULE="MSKaes_128bits_round_based" \
	OUT_BASE="syn/low_lat_$*/full_aes/MSKaes_128bits_round_based/" \
	LIBERTY="stdcells.lib" \
	yosys synth.tcl -t -l "syn/low_lat_$*/full_aes/MSKaes_128bits_round_based/log.txt"

low_lat_%/prolead/MSKaes_128bits_round_based:
	IN_FILES="$(shell find low_lat_$* -type f -name "*.v" ! -name "tb_*.v")" \
	SHARES=$(SHARES) \
	LATENCY=$(LATENCY) \
	TOP_MODULE="MSKaes_128bits_round_based" \
	OUT_BASE="syn/low_lat_$*/prolead/MSKaes_128bits_round_based/" \
	LIBERTY="./PROLEAD/yosys/lib/custom_cells" \
	yosys synth_prolead.tcl -t -l "syn/low_lat_$*/prolead/MSKaes_128bits_round_based/log.txt"

.PHONY: syn_sbox

syn_sbox:
	make two_stage_sbox IA_DEF=1
	make three_stage_sbox IA_DEF=1

syn_aes_core:
	make low_lat_31/full_aes/MSKaes_128bits_round_based SHARES=4 LATENCY=2
	make low_lat_41/full_aes/MSKaes_128bits_round_based SHARES=2 LATENCY=3

syn_aes_wrapper:
	make low_lat_31/full_aes/wrapper_aes128 SHARES=4 LATENCY=2
	make low_lat_41/full_aes/wrapper_aes128 SHARES=2 LATENCY=3

syn_aes_core_prolead:
	make low_lat_31/prolead/MSKaes_128bits_round_based SHARES=4 LATENCY=2
	make low_lat_41/prolead/MSKaes_128bits_round_based SHARES=2 LATENCY=3



verilate_%:
	@ID=$*; \
	MODULE=low_lat_$${ID}; \
	if [ "$$ID" = "41" ]; then LATENCY=3; SHARES_VAL=2; \
	elif [ "$$ID" = "31" ]; then LATENCY=2; SHARES_VAL=4; \
	else LATENCY=3; SHARES_VAL=2; fi; \
	VERILATOR_IN_FILES=$$(find $$MODULE -type f -name "*.v" ! -name "tb_*.v"); \
	verilator -Wno-fatal -cc $$VERILATOR_IN_FILES \
		--exe tb.cpp \
		--top-module wrapper_aes128 \
		-CFLAGS "-O2 -Wall" \
		--trace \
		-I$$MODULE \
		-I$$MODULE/sbox \
		-DDEFAULTSHARES=$$SHARES_VAL -DLATENCY=$$LATENCY; \
	$(MAKE) -C obj_dir -f Vwrapper_aes128.mk; \
	./obj_dir/Vwrapper_aes128

veri_%_sbox:
	@ID=$*; \
	MODULE=low_lat_$${ID}; \
	VERILATOR_IN_FILES=$$(find $$MODULE -type f -name "*.v" ! -name "tb_*.v"); \
	verilator -Wno-fatal -cc $$VERILATOR_IN_FILES \
		--exe tb_sbox.cpp \
		--top-module three_stage_sbox \
		-CFLAGS "-O2 -Wall" \
		--trace \
		-I$$MODULE \
		-I$$MODULE/sbox; \
	$(MAKE) -C obj_dir -f Vthree_stage_sbox.mk; \
	./obj_dir/Vthree_stage_sbox


mv:
	make -C maskVerif
	cp ./maskVerif/maskverif .

prover:
	make -C prover

NOTION ?= NI

benchs:
	python make_mv.py  --circ syn/low_lat_41/sbox/sqscmul/pre.json --spec annonation/GF16_sqscmul.json --notion SNI > syn/low_lat_41/sbox/sqscmul/sqscmul.mv
	python make_mv.py  --circ syn/low_lat_41/sbox/stage23/pre.json --spec annonation/stage23_opt.json --notion Probing > syn/low_lat_41/sbox/stage23/stage23.mv

	python make_silver.py  --circ syn/low_lat_41/sbox/stage23/pre.json --spec annonation/stage23_opt.json > syn/low_lat_41/sbox/stage23/stage23.nl

	make three_stage_sbox
	python make_silver.py  --circ syn/low_lat_41/sbox/pre.json --spec annonation/inverter.json > syn/low_lat_41/sbox/inverter.nl

fv:
	./maskverif < syn/low_lat_41/sbox/sqscmul/sqscmul.mv
# 	./maskverif < syn/low_lat_41/sbox/stage23/stage23.mv
	./prover/bin/verify --insfile syn/low_lat_41/sbox/stage23/stage23.nl
	./prover/bin/verify --insfile syn/low_lat_41/sbox/inverter.nl

prolead:
	make -C PROLEAD CXX=g++-11

detect_leakage_%:
	mkdir -p report/low_lat_$*
	./PROLEAD/release/PROLEAD \
		-lf ./PROLEAD/library.lib \
		-ln custom\
		-df syn/low_lat_$*/prolead/MSKaes_128bits_round_based/design.v \
		-cf config/config$*.set \
		-rf report/low_lat_$* \
		-mn MSKaes_128bits_round_based\
		2>&1 | tee report/low_lat_$*/Report.dat

ev:
	make detect_leakage_41
	make detect_leakage_31
