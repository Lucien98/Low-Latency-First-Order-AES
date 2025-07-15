# 
# Copyright (C) 2024 Vedad Hadžić
# Modified by Feng Zhou, 2025
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

# coding: utf-8

import re
import json
import sys

GE = 0.798
RANDOM_BIT_GE = 39.4

def get_row(prefix, rand_names):
    module_name = prefix.split("/")[-1]
    module_dir = prefix.split("/")[-2]
    # print(module_dir)

    if module_name == "sbox" and module_dir == "low_lat_41":
        module_name = "three_stage_sbox"
    if module_name == "sbox" and module_dir == "low_lat_31":
        module_name = "two_stage_sbox"

    area_rex = re.compile(rf"Chip area for module '\\{module_name}': (\d+\.\d+)")
    # area_rex = re.compile(f"Chip area for top module '\\\\{module_name}': (\\d+\\.\\d+)")
    with open(f"{prefix}/stats.txt", "r") as f:
        area = float(area_rex.search(f.read()).groups()[0])
    
    with open(f"{prefix}/pre.json", "r") as f:
        data = json.load(f)
        found = False
        for m in data["modules"].keys():
            if module_name in m:
                found = True
                ports = data["modules"][m]["ports"]
                bits = sum([len(ports[name]["bits"]) for name in rand_names])
        assert(found)
    area_ge = area / GE
    if "sbox" in module_name: bits = 4
    area_prng = bits * RANDOM_BIT_GE
    # print(f" {bits:3d} & {area_ge:7.1f} & {area_ge+area_prng:7.1f} \\\\")
    print(f" {bits:3d}\t{area_ge:8.1f}\t{area_ge+area_prng:8.1f}")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(f"python3 {sys.argv[0]} PREFIX [RANDOM_NAMES...]")
    get_row(sys.argv[1], sys.argv[2:])