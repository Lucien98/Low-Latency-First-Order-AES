# Low Latency First Order AES
## Architecture
We used a modified version of the round-based architecture in [compress_artifact](https://github.com/cassiersg/compress_artifact) (adaptation of input linear mapping of the S-box).

We also include the source code of maskVerif and Prover for formal verification of our constructions.

## Source Code Structure
  - low_lat_31/: round-based AES Implementations using two staged $GF_2^8$ inverter
  	+ sbox_ti: masked AES S-Box / $GF_2^8$ inverter with a latency of 2 cycles
  - low_lat_41/: round-based AES Implementations using three staged $GF_2^8$ inverter
  	+ sbox_ti: masked AES S-Box / $GF_2^8$ inverter with a latency of 3 cycles

## Run the testbenchs
You can use verilator to check the correctness of the AES encryption.

First, install `verilator`, `make`, and `g++`.
```bash
sudo apt update
sudo apt install -y verilator make g++
```

Then run the testbenchs.
```bash
make verilate_31 # check for the 31-cycle first-order AES
make verilate_41 # check for the 41-cycle first-order AES
```
We use the test vector as follows:
 
  - umsk_plaintext: 0x340737e0a29831318d305a88a8f64332
  - umsk_key: 0x3c4fcf098815f7aba6d2ae2816157e2b
  - umsk_ciphertext: 0x320b6a19978511dcfb09dc021d842539

If the process is done correctly, the last line of the above command should be 
```
Recombined ciphertext: 0x320b6a19978511dcfb09dc021d842539
```

## Preparation for Synthesis
To get the area data in the paper, you should install `yosys` and `make`.

```bash
sudo apt update
sudo apt install -y yosys make
```

The version we installed:

 - Yosys 0.33+0.34
 - GNU Make 4.3

Before synthesis, create the directories that stores the results.

```bash
make resdir
```

## Synthesis
We followed the synthesis flow introduced in [Three-Stage-AES](https://github.com/vedadux/Three-Stage-AES)<sup><a href="#ref1">[1]</a></sup>, by modifying the files `Makefile` and `synth.tcl`.


When synthesizing AES S-Box to get the area data, add the parameter "IA_DEF=1" to include the area of input linear mapping of the S-Box.

```bash
make syn_sbox IA_DEF=1 # synthesize S-Box, set IA_DEF=1 to include input linear mapping
make syn_aes_core # synthesize aes core without PRNG
make syn_aes_wrapper # synthesize aes core with PRNG
```

The results can be seen in folders like:

  - `syn/low_lat_31/sbox/stats.txt`
  - `syn/low_lat_31/full_aes/MSKaes_128bits_round_based/stats.txt`
  - `syn/low_lat_31/full_aes/wrapper_aes128/stats.txt`

**Get the area data**
```bash
# sudo apt install python-is-python3 # for ubuntu 25.04
python get_stats.py syn/low_lat_31/sbox
python get_stats.py syn/low_lat_41/sbox
python get_stats.py syn/low_lat_31/full_aes/MSKaes_128bits_round_based RandomZw RandomBw
python get_stats.py syn/low_lat_41/full_aes/MSKaes_128bits_round_based RandomZw RandomBw
python get_stats.py syn/low_lat_31/full_aes/wrapper_aes128
python get_stats.py syn/low_lat_41/full_aes/wrapper_aes128
```


## Formal Verification for the $GF_2^8$ Inverter

We use the formal verification tool maskVerif and Prover to verify the security of our designs for the $GF_2^8$ inverter.

### installation of maskVerif:
**Install the Ocaml development environment.**

1. install opam: `sudo apt install opam`
2. initialize the opam environment: `opam init`; when the command outputs "Do you want opam to modify ~/.profile? [N/y/f]", press `y` and enter.
3. update the current shell environment for opam: `eval $(opam env --switch=default)`
4. install ocamlbuild and ocamlfind: `opam install ocamlbuild ocamlfind`
5. install dependencies for maskVerif: `opam install zarith menhirLib ocamlgraph menhir`

**Build maskVerif**
```bash
make mv
```

### installation of Prover
First, install Graph library.
```bash
sudo apt install libboost-all-dev
```
Second, copy `prover/lib/libsylvan.so` to `/usr/lib`
```bash
sudo cp prover/lib/libsylvan.so /usr/lib
```


Build Prover.
```bash
make prover
```
### Formal verification using maskVerif and Prover
Since our design for the $GF_2^8$ inverter uses the mathematical properties of boolean functions, maskVerif cannot verify its security. In the meanwhile, Prover can verify its security, but it is too slow.

In order to verify the security of our design faster. We split our design into two parts. The first part contains the squarer-scaler-multiplication. The second part contains the $GF_2^4$ inverter and the final two $GF_2^4$ multiplications. The first part fulfills $1$-MO-SNI. Since only maskVerif can verify $d$-MO-SNI, we use it for verification of this module. 

The probing security and uniformity of the second part can be efficiently verified by Prover in several minutes.

```bash
make benchs
make fv
```

## Verification for the Full AES Implementations

We also use PROLEAD to verify the security of the full AES implementations.

Initially, PROLEAD uses a custom file `config.set` to configure the evaluation settings. Later, the configuration files are changed to JSON files. However, fewer examples are provided when using the JSON configuration files. We do not know how to configure some settings with the latest PROLEAD through a JSON file. As a result, we used a previous version to evaluate our designs. The commit id for this version is `915a024daa0aae93aed7aab80c731d9258274f9f`.

### Installing Dependencies for PROLEAD
This version depends on Python 3.8. However, the default Python version in ubuntu 24.04 we used in WSL is Python 3.12. As a result, we should install Python3.8.
```bash
sudo apt update
sudo apt install software-properties-common
sudo add-apt-repository ppa:deadsnakes/ppa
sudo apt update
sudo apt install python3.8 python3.8-dev
```

On the other hand, this version of PROLEAD uses g++-11 for compilation. Install it by
```bash
sudo apt update
sudo apt install g++-11
```

Build PROLEAD:
```bash
make prolead
```
### Syntheis design for PROLEAD
```bash
make syn_aes_core_prolead
```
### Leakage Detection through PROLEAD
```bash
make ev
```

## License

The original code in this repository (excluding submodules) is licensed under the GNU General Public License v3.0 (GPLv3).

However, this project includes several third-party submodules with different licenses. Notably, **some of the submodules (or its dependencies)**, e.g. Prover and parts of the verilog code of the AES S-Box, include a license that **prohibits commercial use**. As a result, **the entire repository cannot be used for commercial purposes** unless that component is removed or replaced.

Please refer to each submodule’s directory and license file for more detailed information.

> **⚠️ Warning:** If you intend to use this project for commercial purposes, you must carefully review and comply with the licenses of all included components. In particular, you may need to remove or replace non-commercial components.


## References
1. <p><a name = "ref1"></a>Three-Stage-AES.https://github.com/vedadux/Three-Stage-AES</p>

