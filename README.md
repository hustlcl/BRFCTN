# BRFCTN
MATLAB implementation of BRFCTN for visual data denoising
## BRFCTN quickstart
To verify the BRFCTN for data denoising, please run demo.m to test the example data.

## Project structure
- **`Data`**: The visual dataset used for the code, we choose HSI from [CAVE](https://www.cs.columbia.edu/CAVE/databases/multispectral/) dataset here. Include one representative image from CAVE called "balloons".
  
- **`Evaluation`**: Stores functions for calculating evaluation metrics, including PSNR, SSIM, FSIM, RMSE, and ERGAS.

- **`Functions`**: Stores functions for higher-order tensor calculating, including contraction and tn_prod operator used in FCTN strcture.

- **`Model`**: Stores the model of BRFCTN.
  - **`run FCTN_model(D, Rank, hyperparameters) to build the class:`**

## To build the class of BRFCTN:
  ### `FCTN_vb = FCTN_model(D, Rank, hyperparameters)`
D is the corrupted tensor, Rank is the predefined FCTN-ranks, and hyperparameters are set as 1e-6 for non-informative prior.

## Then initial the model:
  ### `FCTN_vb = FCTN_vb.initialize()`
  
## Finally run the model:
  ### `FCTN_vb = FCTN_vb.run(MAX_Iter)`



