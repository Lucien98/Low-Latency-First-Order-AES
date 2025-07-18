# 
# Copyright (C) 2024 Vedad Hadžić
# Modified by Feng Zhou, 2025
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

import json
import functools
import argparse

NUM_SHARES = 0

CELLS_INFO = {
    "$_AND_":   {"ins": ["A", "B"], "out": "Y"},
    "$_NAND_":  {"ins": ["A", "B"], "out": "Y"},
    "$_OR_":    {"ins": ["A", "B"], "out": "Y"},
    "$_NOR_":   {"ins": ["A", "B"], "out": "Y"},
    "$_XOR_":   {"ins": ["A", "B"], "out": "Y"},
    "$_XNOR_":  {"ins": ["A", "B"], "out": "Y"},
    "$_NOT_":   {"ins": ["A"], "out": "Y"},
    "$_ANDNOT_": {"ins": ["A", "B"], "out": "Y"},
    "$_ORNOT_":  {"ins": ["A", "B"], "out": "Y"},
    "$_DFF_P_": {"ins": ["D"], "out": "Q"},
}

LINES = []

NUM_IDS = 0
def get_id():
    global NUM_IDS
    NUM_IDS += 1
    return NUM_IDS - 1

def gate(op, *args):
    global LINES
    c = get_id()
    assert(all(map(lambda x: type(x) is int, args)))
    LINES.append(op + " " + " ".join(map(str, args)))
    return c

def and_impl(a, b):
    a_str, b_str = (type(a) is str), (type(b) is str)
    if a_str and b_str:
        return str(int(a) & int(b))
    elif a_str:
        return b if int(a) else "0"
    elif b_str:
        return a if int(b) else "0"
    return gate("and", a, b)

def not_impl(a):
    if type(a) is str: 
        return str(1 - int(a))
    return gate("not", a)

def nand_impl(a, b):
    return not_impl(and_impl(a, b))

def xor_impl(a, b):
    a_str, b_str = (type(a) is str), (type(b) is str)
    if a_str and b_str:
        return str(int(a) ^ int(b))
    elif a_str:
        return not_impl(b) if int(a) else b
    elif b_str:
        return not_impl(a) if int(b) else a
    return gate("xor", a, b)

def xnor_impl(a, b):
    return not_impl(xor_impl(a, b))

def or_impl(a, b):
    return not_impl(and_impl(not_impl(a), not_impl(b)))

def nand_impl(a, b):
    return not_impl(and_impl(a, b))

def nor_impl(a, b):
    return not_impl(or_impl(a, b))

def andnot_impl(a, b):
    return and_impl(a, not_impl(b))

def ornot_impl(a, b):
    return or_impl(a, not_impl(b))

def dff_impl(d):
    if type(d) is str:
        return d
    return gate("reg", d)

def out_impl(val, idx):
    global LINES
    LINES.append(f"out {val} 0_{idx}")

def outsh_impl(val, idx, dom):
    global LINES
    LINES.append(f"out {val} {idx}_{dom}")

def evaluate(bit, bit_defines, symbol_table):
    if bit in symbol_table:
        return symbol_table[bit]
    func, ins = bit_defines[bit]
    inputs = [evaluate(b, bit_defines, symbol_table) for b in ins]
    result = CELL_IMPL[func](*inputs)
    symbol_table[bit] = result
    return result

CELL_IMPL = {
    "$_AND_":   and_impl,
    "$_NAND_":  nand_impl,
    "$_OR_":    or_impl,
    "$_NOR_":   nor_impl,
    "$_XOR_":   xor_impl,
    "$_XNOR_":  xnor_impl,
    "$_NOT_":   not_impl,
    "$_ANDNOT_": andnot_impl,
    "$_ORNOT_":  ornot_impl,
    "$_DFF_P_": dff_impl,
}

def parse_module(circuit_path):
    with open(circuit_path, "r") as f:
        data = json.load(f)
    modules = data["modules"]
    assert(len(modules) != 0)
    module_name = list(modules.keys())[0]
    return modules[module_name]

def get_bit_names(module):
    bit_names = {}
    for name_id, name_info in module["netnames"].items():
        real_name = name_id
        if "attributes" in name_info and "hdlname" in name_info["attributes"]:
            real_name = ".".join(name_info["attributes"]["hdlname"].split())
        assert("bits" in name_info)
        for idx, bit in enumerate(name_info["bits"]):
            suffix = "" if len(name_info["bits"]) == 1 else f"[{idx}]"
            if bit not in bit_names:
                bit_names[bit] = []
            bit_names[bit].append(real_name + suffix)
    return bit_names

def get_bit_defines(module):
    bit_defines = {}
    for cell_name, cell_info in module["cells"].items():
        cell_type = cell_info["type"]
        type_info = CELLS_INFO[cell_type]
        connections = cell_info["connections"]
        out_bit = connections[type_info["out"]][0]
        in_bits = [connections[port][0] for port in type_info["ins"]]
        bit_defines[out_bit] = (cell_type, in_bits)
    return bit_defines

def parse_spec(spec_path):
    with open(spec_path, "r") as f:
        return json.load(f)

def set_num_shares(num_shares):
    global NUM_SHARES
    if NUM_SHARES == 0:
        NUM_SHARES = num_shares
    assert(NUM_SHARES == num_shares)

def get_sharing(secret, num_shares):
    global LINES
    shares = [get_id() for i in range(num_shares)]
    for idx, sh in enumerate(shares):
        LINES.append(f"in {sh} {secret}{idx}")
    return shares

def get_random():
    global LINES
    idx = get_id()
    LINES.append(f"ref {idx}")
    return idx

def execute_circuit(ports, bit_defines, bit_names, spec):
    global LINES
    secrets = {}
    masks = {}
    outputs = []
    symbol_table = {}
    port_items = list(ports.items())
    for i in range(len(port_items)):
        port_id, port_info = port_items[i]
        port_spec = spec[port_id]

        if port_spec["type"] == "S" and port_id[-1] == "0":
            port_id_next, port_info_next = port_items[i+1]
            bits = port_info["bits"] + port_info_next["bits"]
            assert(port_info["direction"] == "input")
            umsk_port_id = port_id[:-1]
            num_secrets = port_spec["len"]
            assert(len(bits) % num_secrets == 0)
            num_shares = len(bits) // num_secrets
            set_num_shares(num_shares)
            # print("num_input_shares", num_shares)
            for i in range(num_secrets):
                positions = [j for j in range(i, len(bits), num_secrets)]
                assert(len(positions) == num_shares), f"{positions}"
                secret = f"{len(secrets)}_"
                secrets[(umsk_port_id, i)] = secret
                shares = get_sharing(secret, num_shares)
                for p, sh in zip(positions, shares):
                    symbol_table[bits[p]] = sh

    for port_id, port_info in ports.items():    
        port_spec = spec[port_id]
        bits = port_info["bits"]
        if port_spec["type"] == "M":
            assert(port_info["direction"] == "input"), port_info
            assert(port_spec["len"] == "?" or port_spec["len"] == len(bits))
            for idx, bit in enumerate(bits):
                mask = get_random()
                masks[(port_id, idx)] = mask
                symbol_table[bit] = mask
        elif type(port_spec["type"]) is int:
            assert(port_info["direction"] == "input"), f"{port_id}: {port_info}"
            value = port_spec["type"]
            assert(port_spec["len"] == len(bits))
            for idx, bit in enumerate(bits):
                symbol_table[bit] = str((value >> idx) & 1)

    for i in range(len(port_items)):
        port_id, port_info = port_items[i]
        port_spec = spec[port_id]
        if port_spec["type"] == "O" and port_id[-1] == "0":
            port_id_next, port_info_next = port_items[i+1]
            bits = port_info["bits"] + port_info_next["bits"]
            assert(port_info["direction"] == "output")
            num_outputs = port_spec["len"]
            assert(len(bits) % num_outputs == 0)
            num_shares = len(bits) // num_outputs
            set_num_shares(num_shares)
            # print("num_output_shares", num_shares)
            for i in range(num_outputs):
                positions = [j for j in range(i, len(bits), num_outputs)]
                share_bits = []
                shares = [evaluate(bits[p], bit_defines, symbol_table) for p in positions]
                outputs.append(tuple(shares))

    inverse_symbol_table = {sym: idx for idx, sym in symbol_table.items() if type(sym) is not str}


    LINES = [(l + " #").ljust(15, " ") + 
             (f"{i}: {bit_names[inverse_symbol_table[i]][0]}" 
                if i in inverse_symbol_table else 
              "")
        for i,l in enumerate(LINES)]

    final_outs = []
    # for i in range(NUM_SHARES):
    #     dom_out = [out[i] for out in outputs]
    #     print(dom_out)
    #     dom_out = functools.reduce(lambda a, b: gate("and", a, b), dom_out)
    #     final_outs.append(dom_out)
    # for i, o in enumerate(final_outs):
    #     out_impl(o, i)
    for i in range(NUM_SHARES):
        for idx, share in enumerate(outputs):
            outsh_impl(share[i], idx, i)
    
    print("\n".join(LINES))

def get_args():
    parser = argparse.ArgumentParser(description="Encode a circuit for SILVER.")
    parser.add_argument("--circ", help="Path to the circuit JSON file")
    parser.add_argument("--spec", help="Path to the specification JSON file")

    return parser.parse_args()


if __name__ == "__main__":
    args = get_args()
    module = parse_module(args.circ)
    spec = parse_spec(args.spec)
    bit_names = get_bit_names(module)
    bit_defines = get_bit_defines(module)
    execute_circuit(module["ports"], bit_defines, bit_names, spec)
