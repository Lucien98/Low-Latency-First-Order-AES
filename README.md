# Low Latency and Low Randomness First Order AES Threshold Implementations
This project utilizes a modified version of the round-based architecture (excluding the S-Boxes) from [compress_artifact](https://github.com/cassiersg/compress_artifact). Modifications includes:

  - adaptations to the scheduling of the input linear mapping to the S-box.
  - Removal of redundant pipeline registers when the number of shares is 4.

For evaluations of these implementations, please refer to [Low_Latency_First_Order_AES](https://github.com/Lucien98/Low_Latency_First_Order_AES).

## License
See LICENSE.txt for details.
