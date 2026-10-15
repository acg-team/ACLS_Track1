# Project 2: Investigating Gene Expression Patterns in MSI-H and MSS Tumors

## Background

Microsatellite instability-high (**MSI-H**) and microsatellite-stable (**MSS**) tumors may have different gene expression patterns. Some of these differences may be linked to DNA repair, immune activity, or other biological processes. In this project, you will explore these patterns and test whether they can help predict MSI status.

## Tasks

1. **Get your assigned dataset:** Contact me at **konl@zhaw.ch** to discuss which TCGA dataset you should work with: COAD (colon), READ (rectal), STAD (stomach), or UCEC (endometrial).
2. **Check data quality:** Examine expression distributions, genes with little or no expression, unusual samples, and possible technical noise or batch effects.
3. **Prepare gene expression data:** Use an appropriate transformation (for example, `log2(TPM + 1)`). Filter genes with very low expression and decide whether feature scaling is needed.
4. **Perform PCA:** Visualize samples using principal component analysis (PCA). Color samples by MSI status and investigate whether the groups separate. Examine possible outliers and other factors associated with the main PCs.
5. **Train a Random Forest classifier:** Use selected PCs as input features to predict **MSI-H versus MSS**. Compare the results with a simple baseline and evaluate performance using cross-validation or a test set.
6. **Investigate feature importance:** Identify which PCs contribute most to the predictions. Examine the gene loadings of these PCs to identify **candidate genes** that may be associated with MSI status.
7. **Visualize selected genes:** Create boxplots or similar figures showing expression of selected candidate genes in MSI-H and MSS tumors. Explore whether the differences are statistically supported.

## Provided data

Project 2 uses **the same data as Project 1**. The files are stored in the [Project 1 data folder](../project_1/data/), so there is no need to make a second copy.

### `counts.tsv`

- **Rows:** Genes identified by gene symbols, such as `TSPAN6` or `DPM1`. The first column is `gene`.
- **Columns:** TCGA patient IDs (for example, `TCGA-AF-2687`); one expression profile per patient.
- **Values:** Raw RNA-seq gene counts.

### `tpm.csv`

- **Rows:** Genes identified by gene symbols. The first column is `gene`.
- **Columns:** TCGA patient IDs; one expression profile per patient.
- **Values:** TPM (transcripts per million), not log-transformed.

### `sample_metadata.tsv`

- **Rows:** Selected RNA-seq tumor samples, one row per patient.
- **Columns:**
  - `patient_id`: TCGA patient identifier.
  - `sample_id`: Full TCGA sample barcode.
  - Other columns record the TCGA project, sample selection, and collection-day information where available.

### `clinical_data.csv`

- **Rows:** Patients with clinical annotations.
- **Columns:** Only the following two columns are required:

| Column | Description |
| --- | --- |
| `case_submitter_id` | TCGA patient identifier. |
| `MSI_TMB` | Combined MSI and tumor mutational burden (TMB) group. Values include `MSI-H`, `MSS/TMB-H`, and `MSS/TMB-L`. |

For this project, **combine `MSS/TMB-H` and `MSS/TMB-L` into one MSS group** and compare it with `MSI-H`. The clinical file contains other columns, but these are not required for the main project. Some values may be missing.

### `gene_annotation.tsv`

One shared file for all four cohorts.

- **Rows:** Gene annotations, one row per Ensembl gene identifier.
- **Columns:**
  - `gene_id`: Ensembl gene ID, possibly including a version.
  - `gene_symbol`: Gene symbol.
