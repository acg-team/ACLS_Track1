
# Project 1: Comparing Immune Cell Composition in MSI-H and MSS Tumors

## Background

Microsatellite instability-high (MSI-H) tumors often show a stronger immune response than microsatellite-stable (MSS) tumors.

## Goal

Investigate how immune cell composition differs between MSI-H and MSS tumors.

## Tasks

1. Download the clinical and gene expression data from the `data` folder.
2. Select one TCGA cancer dataset: COAD, READ, UCEC, or STAD.
3. Estimate immune cell composition using:
   - Easy option: EPIC
   - Advanced option: BayesDeBulk
4. Compare immune cell proportions between MSI-H and MSS samples.
5. Identify which immune cell types show the largest differences.
6. Visualize the results using boxplots and heatmaps.
7. Optional: Train a machine learning model to predict MSI status.

## Tools

- R
- [EPIC](https://github.com/GfellerLab/EPIC)
- [BayesDeBulk](https://github.com/WangLab-MSSM/BayesDeBulk)

## Data

Files are available in the [data folder](data/).

- `clinical.csv`: Sample information, including MSI status.
- `expression.csv.gz`: Gene expression matrix.

## Expected Results

- Estimated immune cell proportions
- Statistical comparisons between MSI-H and MSS tumors
- Figures showing immune cell differences
- Biological interpretation of the results

## Final Presentation

Present your research question, methods, results, and conclusions.