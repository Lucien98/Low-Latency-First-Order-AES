// 
// Copyright (C) 2025 Feng Zhou
// 
// 
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
// 
#include "Vthree_stage_sbox.h"
#include "verilated.h"
#include "verilated_vcd_c.h"
#include <iostream>
#include <iomanip>
#include <random>

vluint64_t main_time = 0;
double sc_time_stamp() { return main_time; }

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);

    // Instantiate DUT
    Vthree_stage_sbox *dut = new Vthree_stage_sbox;

    // Optional: enable waveform tracing
    Verilated::traceEverOn(true);
    VerilatedVcdC *tfp = new VerilatedVcdC;
    dut->trace(tfp, 99);
    tfp->open("wave.vcd");

    // Random generator for r
    std::mt19937_64 rng(0);  // fixed seed for reproducibility

    dut->CLK = 0;
    dut->in0 = 0;
    dut->in1 = 0;
    dut->r = 0;

    // Clock and simulation parameters
    const int T = 2;      // 2ns
    const int Td = 1;     // 1ns half-period

    for (int i = 0; i < 1; i++) {
        for (int j = 0; j < 26/2; j++) {
            // Apply inputs
            dut->in1 = i;
            dut->in0 = j;
            // dut->r = rng();  // 64-bit random value

            // Toggle clock: 1 full cycle = 2 evals
            for (int k = 0; k < 2; k++) {
                dut->CLK = !dut->CLK;
                dut->eval();
                tfp->dump(main_time);
                main_time += Td;
            }

            // Optional: print output
            uint8_t X = i ^ j;
            uint8_t Q = dut->out0 ^ dut->out1;

            std::cout << std::hex << std::setfill('0')  // 设置十六进制输出和填充字符
              << "in0: 0x" << std::setw(2) << (int)j
              << " in1: 0x" << std::setw(2) << (int)i
              << " X:  0x" << std::setw(2) << (int)X
              << " Q:  0x" << std::setw(2) << (int)Q
              << std::endl;
        }
    }

    tfp->close();
    delete dut;
    delete tfp;

    return 0;
}
