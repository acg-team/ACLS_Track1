# Project 1: Comparing Immune Cell Composition in MSI-H and MSS Tumors


## Background

A tumor contains not only cancer cells, but also immune cells and other cells from the tumor microenvironment (TME). The types and amounts of immune cells may affect tumor behavior and response to treatment.

Microsatellite instability-high (**MSI-H**) tumors often have a stronger immune response than microsatellite-stable (**MSS**) tumors. In this project, you need to use bulk RNA-seq data to estimate immune cell composition and test whether it differs between these two groups.


## Tasks

1. **Get your assigned cancer dataset:** Before starting the analysis, contact me at konl@zhaw.ch to get which TCGA dataset you should work with: COAD (colon), READ (rectal), STAD (stomach), or UCEC (endometrial).
2. **Estimate immune cells** from the expression matrix. Choose one method:
   - **1 option — [EPIC](https://github.com/GfellerLab/EPIC):** Use a predefined reference to estimate cell populations.
   - **2 option (advanced) — [BayesDeBulk](https://github.com/WangLab-MSSM/BayesDeBulk):** Prepare the required marker information and use Bayesian deconvolution. 

4. **Read the official documentation for your chosen method.** Identify which input files, expression format, reference data or marker information, and preprocessing steps are required. Check which inputs are already provided and which you need to prepare.

5. **Compare MSI-H and MSS samples:** Make plots for selected immune cell populations and perform appropriate statistical tests.

## Provided data

The project contains four TCGA cancer cohorts. Each cohort has the same types of files:

```text
project_1/
├── README.md
└── data/
    ├── gene_annotation.tsv
    ├── COAD/
    │   ├── counts.tsv
    │   ├── tpm.csv
    │   ├── sample_metadata.tsv
    │   └── clinical_data.csv
    ├── READ/
    │   ├── counts.tsv
    │   ├── tpm.csv
    │   ├── sample_metadata.tsv
    │   └── clinical_data.csv
    ├── STAD/
    │   ├── counts.tsv
    │   ├── tpm.csv
    │   ├── sample_metadata.tsv
    │   └── clinical_data.csv
    └── UCEC/
        ├── counts.tsv
        ├── tpm.csv
        ├── sample_metadata.tsv
        └── clinical_data.csv
```

### `counts.tsv`

- **Rows:** Genes, identified by gene symbols (for example, `TSPAN6`, `DPM1`). The first column is `gene`.
- **Columns:** TCGA patient IDs (for example, `TCGA-AF-2687`), with one expression profile per patient.
- **Values:** Raw RNA-seq gene counts.

### `tpm.csv`

- **Rows:** Genes, identified by gene symbols. The first column is `gene`.
- **Columns:** TCGA patient IDs, with one expression profile per patient.
- **Values:** TPM (transcripts per million), not log-transformed.

### `sample_metadata.tsv`

- **Rows:** Selected RNA-seq tumor samples, one row per patient.
- **Columns:** Sample information. The main identifiers are:
  - `patient_id`: TCGA patient identifier (for example, `TCGA-AF-2687`).
  - `sample_id`: Full TCGA sample barcode (for example, `TCGA-AF-2687-01A-02R-1736-07`).
- **Other columns:** Information about the original TCGA project and how the sample was selected, including collection-day information where available.

### `clinical_data.csv`

- **Rows:** Patients with clinical annotations.
- **Columns:** Clinical information. **Only the following columns are needed for this project:**

| Column | Description |
| --- | --- |
| `case_submitter_id` | TCGA patient identifier (for example, `TCGA-AF-2687`). |
| `MSI_TMB` | Combined microsatellite instability (MSI) and tumor mutational burden (TMB) category. Possible values include `MSI-H`, `MSS/TMB-H`, and `MSS/TMB-L`. |

`MSS/TMB-H` and `MSS/TMB-L` are both microsatellite-stable (MSS) categories. The clinical file may contain many **other columns**, but they are not required for this project. Some annotations may also be missing for some patients.

### `gene_annotation.tsv`

This is one shared annotation file for all four cancer cohorts.

- **Rows:** Gene annotations, one row per Ensembl gene identifier.
- **Columns:**
  - `gene_id`: Ensembl gene ID, including its version where available (for example, `ENSG00000000003.15`).
  - `gene_symbol`: Gene symbol (for example, `TSPAN6`).


## Analysis workflow

### Step 1 — Load and match the data

1. Read `tpm.csv`, `sample_metadata.tsv`, and the corresponding clinical file.
2. Match by patient id and keep only patients with a usable MSI label.
3. Verify that every patient appears once in the matched data.


### Step 2 — Estimate immune cell composition

- **EPIC option:** Follow the [EPIC documentation](https://github.com/GfellerLab/EPIC)
- **BayesDeBulk option:** Follow the [BayesDeBulk documentation](https://github.com/WangLab-MSSM/BayesDeBulk); prepare the marker information required by the model and check its expression input requirements.
- Save a result table.

### Step 3 — Compare MSI-H and MSS tumors

1. Plot the distribution of each estimated immune cell population in the two groups.
2. Report effect sizes and use an appropriate test, such as the Wilcoxon rank-sum test.
3. Correct for multiple testing when evaluating many cell types (for example, the Benjamini–Hochberg method).
4. Create a box plot.

### Step 4 — Interpret the results

- Which immune cell types show the clearest differences?
- Are the results biologically reasonable?
- How do your findings compare with previous studies?
- What are the limitations of deconvolution from bulk RNA-seq?
