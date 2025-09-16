# BRFCTN
MATLAB implementation of BRFCTN for visual data denoising
## BRFCTN quickstart
To verify the BRFCTN for data denoising, please run demo.m the test the example data.

## Project structure
- **`Data\`**: The visual dataset used for the code, we choose HSI from [CAVE](https://www.cs.columbia.edu/CAVE/databases/multispectral/) dataset here.
  - **`balloons_ms.mat`**: A representative image from CAVE called "balloons".

- **`Evaluation\`**: Stores functions for calculating evaluation metrics, including PSNR, SSIM, FSIM, RMSE, and ERGAS.
  - **

- **`docs/`**: 项目相关的详细文档。

- **`tests/`**: 所有测试相关文件。
  - **`unit/`**: 针对单个函数或模块的测试。
  - **`integration/`**: 针对多个模块协同工作的测试。

- **`scripts/`**: 存放各种自动化脚本，如 `build.sh`, `deploy.js` 等。

- **`dist/`**: 此目录由构建工具（如 Webpack, Vite）自动生成，包含可用于生产环境的优化后的代码。**不应提交到Git**。
