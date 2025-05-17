# Wireless Communications

#  5G NR Sparse Channel Estimation and Mobility Robustness
-  Author：Chenchen Guo    cg4421
- This project implements a complete physical-layer simulation of the 5G NR downlink with MMSE and Sparse-MMSE channel estimation under realistic multipath fading. The simulation incorporates EPA fading profiles and UE mobility (via Doppler shifts), and evaluates estimator performance across SNR and speed settings.

> This work extends Lab7 by introducing EPA channels, Sparse post-processing, and adaptive thresholding.

---

## Features

- Modular MATLAB simulation of 5G NR downlink PHY chain
- EPA multipath fading channel with Doppler effect
- MMSE and Sparse-MMSE estimators with:
  - Fixed threshold: τ = α · max‖h‖
  - Adaptive threshold: τ = α · √(noise variance)
- Performance evaluation via MSE and BER
- Visual comparisons at multiple speeds (30, 60, 120 m/s)
- All plots reproducible from `.mlx` file

---

## File Structure

| File | Description |
|------|-------------|
| `runSimulation.mlx` | Main experiment (run this to generate all results & plots) |
| `runSimulation.pdf` | Exported version of the full `.mlx` for quick reading |
| `FDChan.m` | EPA channel model with Doppler and multipath fading |
| `NRgNBTxFD.m` | Transmitter for NR-PDSCH |
| `NRUERxFD.m` | Receiver: implements MMSE and Sparse-MMSE estimators |
| `kernelReg.m` | Kernel regression smoother used before thresholding |
| `sparseThreshold.m` | Soft-thresholding function |
| `plotChan.m` | Channel visualization utility |
| `plotChanCompare.m` | Compares true vs estimated channel (debug tool) |
| `README.md` | You’re reading it! |

---

## How to Run

Open MATLAB and run:
> open('runSimulation.mlx');


---

## Results & Analysis
All result figures, observations, and MSE/BER comparisons can be found in the runSimulation.pdf report.

The PDF includes:

MSE vs SNR comparisons between MMSE and Sparse-MMSE

Evaluation of fixed vs adaptive thresholding

BER trends under different mobility levels

Numerical gap analysis and insights

👉 Open runSimulation.pdf to see all plots and explanations.
[Click here to view the full simulation report (PDF)](./runSimulation.pdf)
