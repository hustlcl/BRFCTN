# BRFCTN
MATLAB implementation of BRFCTN for visual data denoising
## BRFCTN quickstart
To verify the BRFCTN for data denoising, please run demo.m the test the example data.

## Project structure
- **`src/`**: 存放项目所有主要的源代码。
  - **`components/`**: 通用的React/Vue/等UI组件。
  - **`pages/`**: 与路由对应的页面组件。
  - **`utils/`**: 辅助函数，如日期处理、HTTP请求等。

- **`public/`**: 存放不需要经过构建流程的静态文件，如 favicon.ico, robots.txt 等。

- **`docs/`**: 项目相关的详细文档。

- **`tests/`**: 所有测试相关文件。
  - **`unit/`**: 针对单个函数或模块的测试。
  - **`integration/`**: 针对多个模块协同工作的测试。

- **`scripts/`**: 存放各种自动化脚本，如 `build.sh`, `deploy.js` 等。

- **`dist/`**: 此目录由构建工具（如 Webpack, Vite）自动生成，包含可用于生产环境的优化后的代码。**不应提交到Git**。
