# Low Latency and Low Randomness First Order Threshold Implementation of AES S-Box
This repository contains the source code of S-Boxes in our paper **First-Order Hardware Masking of AES with Low Randomness and Low Latency**.

Part of the code are taken from [Masked_AES_hardware](https://github.com/ECSIS-lab/curse_of_re-encryption/tree/main/Masked_AES_hardware).

The correction terms are extracted from [AESTIScheme](https://github.com/GitHub-lancel/AESTIScheme).

To reproduce the results presented in the paper, please refer to [Low_Latency_First_Order_AES](https://github.com/Lucien98/Low_Latency_First_Order_AES).



## 📜 License and Acknowledgements

Part of the code is taken from the [Masked_AES_hardware repository](https://github.com/ECSIS-lab/curse_of_re-encryption/tree/main/Masked_AES_hardware), originally developed by Rei Ueno and colleagues at Tohoku University.

The original work is licensed under a permissive academic-use license that allows copying, redistribution, and modification **as long as**:
- It is **not used for monetary profit**, resale, or commercial distribution.
- The **copyright notice** is included prominently.

We have extracted and modified certain modules (e.g., `Stage1`, `Stage2`, `Stage3`, `Inversion_TI`, etc.) for our own purposes. The modified files retain the original license notice in their headers, along with clear annotations of the changes.

The other parts of the code is licensed under the **GNU General Public License v3.0 (GPLv3)**. See https://www.gnu.org/licenses/ for more details.
