# Project 3: 5-Fluorouracil Sensitivity and Gene Expression in Colorectal Cancer


## Background

**5-Fluorouracil (5-FU)** is a chemotherapy drug used to treat colorectal cancer. However, patients differ in their sensitivity to 5-FU. These differences may be related to microsatellite instability (MSI) status and gene expression.

In this project, you will analyze **colorectal cancer cell lines**, not patient treatment outcomes. Drug sensitivity is measured experimentally in the laboratory. 

## Research questions

1. **Do MSI and MSS colorectal cancer cell lines differ in sensitivity to 5-FU?**
2. **Which gene expression patterns are associated with 5-FU resistance, and can gene expression predict 5-FU sensitivity?**

*Note:* Sanger's cell-line annotation uses **MSI** (microsatellite instable) and **MSS** (microsatellite stable).

## Tasks

1. **Read the database documentation.** Learn how GDSC measures drug response, how MSI/MSS status is defined, and how expression values are normalized.
2. **Download three datasets:**
   - GDSC drug sensitivity results, including **5-Fluorouracil** and `LN_IC50`.
   - Cell-line annotations, including **cancer type**, **MSI/MSS status**, and identifiers.
   - Processed **RNA-seq gene expression**, preferably `log2(TPM + 1)`.
   See [Databases and download links](#databases-and-download-links).
3. **Match the cell lines.** Select colorectal cancer cell lines and join all three datasets using a stable cell-line identifier, such as `SANGER_MODEL_ID`, or a documented mapping. Check for duplicate identifiers, missing data, and different cell-line names. Report the number of MSI and MSS cell lines with complete data. Begin with **one drug-screen dataset (GDSC1 or GDSC2)** rather than mixing them.
4. **Compare 5-FU sensitivity.** Create a boxplot or violin plot of `LN_IC50` for MSI versus MSS colorectal cancer cell lines. Report the number of cell lines in each group, perform an appropriate statistical test (for example, a Wilcoxon rank-sum test), and describe the effect size and direction of the difference.
6. **Prepare the gene expression matrix.** Use one expression profile per cell line. Filter genes with very low expression and, if necessary, retain a limited number of the most variable genes to reduce dimensionality. Check whether expression is already log-transformed; **do not log-transform `log2(TPM + 1)` again**.
7. **Train an Elastic Net model.** Predict continuous **`LN_IC50`** from gene expression. Standardize gene features and tune Elastic Net regularization using cross-validation. Any data-dependent filtering, variance selection, and scaling must be fitted **on training data only**, within the cross-validation procedure.
9. **Interpret the model.** Identify genes with nonzero Elastic Net coefficients and examine how stable these genes are across validation runs. Plot selected genes against `LN_IC50` and discuss which expression patterns are associated with resistance. 

**Interpreting `LN_IC50`:** For the same drug and comparable experiments, higher `LN_IC50` generally means **lower drug sensitivity (greater resistance)**. It is already a natural-log value.


## Databases and download links

Download the following **three datasets**. The exact names and versions of download files may change; record the version/date of every dataset you use.

| Needed dataset | Where to download | What to look for |
| --- | --- | --- |
| **1. 5-FU drug sensitivity** | [Cell Model Passports — Downloads](https://cellmodelpassports.sanger.ac.uk/downloads) · [GDSC drug downloads](https://www.cancerrxgene.org/downloads/drug_data) · [Direct GDSC2 fitted drug-response XLSX (release 8.5, 27 Oct 2023)](https://cog.sanger.ac.uk/cancerrxgene/GDSC_release8.5/GDSC2_fitted_dose_response_27Oct23.xlsx) | GDSC1 or GDSC2 **fitted dose-response** results; filter `DRUG_NAME` to **5-Fluorouracil**, retain `LN_IC50` and cell-line IDs. |
| **2. Cell-line annotations and MSI** | [Cell Model Passports — Downloads](https://cellmodelpassports.sanger.ac.uk/downloads) · [Browse models](https://cellmodelpassports.sanger.ac.uk/passports) | Download the **model list / cell-model annotations** with model identifier, cancer type or tissue, and **MSI status**. If the export lacks MSI, retrieve it from the model annotation pages or API. |
| **3. RNA-seq expression** | [Cell Model Passports — Downloads](https://cellmodelpassports.sanger.ac.uk/downloads) · [Sanger DepMap expression documentation](https://depmap.sanger.ac.uk/documentation/datasets/expression/) | Download the **processed RNA-seq expression matrix** (preferably the merged **TPM/log2(TPM + 1)** dataset). Keep the same cell-line IDs as above. |

The first direct XLSX link is to a **specific historical GDSC2 release**. Sanger provides processed RNA-seq data in combined matrices and reports TPM as **log2(TPM + 1)** in its documentation.

### Documentation for understanding the downloaded files

- [Sanger DepMap — Drug sensitivity](https://depmap.sanger.ac.uk/documentation/datasets/drug-sensitivity/): `LN_IC50`, drug IDs, identifiers, and differences between GDSC1/GDSC2.
- [Sanger DepMap — MSI status](https://depmap.sanger.ac.uk/documentation/cell-models/msi-ploidy-mutational-burden/): how the MSI/MSS labels were assigned.
- [Sanger DepMap — RNA-seq expression](https://depmap.sanger.ac.uk/documentation/datasets/expression/): processing, normalization, and matrix orientation.
- [Sanger DepMap — Cell-model annotations](https://depmap.sanger.ac.uk/documentation/cell-models/): model identifiers and relationships.

### Key fields

| Field | Description |
| --- | --- |
| `SANGER_MODEL_ID` (or mapped equivalent) | Cell-line identifier used to connect the files. |
| `DRUG_NAME` / `DRUG_ID` | Identifies the tested compound; select 5-Fluorouracil. |
| `LN_IC50` | Natural logarithm of the fitted IC50; higher means greater resistance to the same drug under comparable experimental conditions. |
| MSI status | Cell-line classification: **MSI** or **MSS**. |
| Cancer type / tissue | Information used to select colorectal cancer cell lines. |
| Gene / expression columns | Gene identifiers and normalized RNA-seq values for each cell line. |

**Column names and file orientation may differ across releases.** Read the first rows and column names of each file before joining. In the Sanger combined RNA-seq matrix, genes may be rows and cell lines columns; transpose if your modeling tool expects cell lines as rows.

## Tutorials

### Drug-response analysis and matching data

- [Practical GDSC drug-response and gene-expression modeling tutorial (Python)](https://kuraisle.github.io/jmw/data-analysis/gdsc_drug_models.html) — an example of obtaining data, matching samples, and creating prediction models.

### Expression-based machine learning

- [scikit-learn: ElasticNetCV](https://scikit-learn.org/stable/modules/generated/sklearn.linear_model.ElasticNetCV.html) — train Elastic Net and tune regularization.
- [scikit-learn: Pipelines](https://scikit-learn.org/stable/modules/compose.html#pipeline) — combine preprocessing and modeling.
- [scikit-learn: Cross-validation](https://scikit-learn.org/stable/modules/cross_validation.html) — evaluate predictive models.
- [scikit-learn: Common pitfalls and data leakage](https://scikit-learn.org/stable/common_pitfalls.html) — avoid using test data when selecting genes or scaling features.
- [scikit-learn: Feature selection](https://scikit-learn.org/stable/modules/feature_selection.html) — reduce the number of genes.
- [tidymodels for R](https://www.tidymodels.org/start/) — an R alternative.
- [Gene-expression modeling of anticancer drug sensitivity (research example)](https://pmc.ncbi.nlm.nih.gov/articles/PMC8048084/) — background reading on predicting response from expression data.


**Questions or problems with the datasets?** Contact me at [konl@zhaw.ch](mailto:konl@zhaw.ch).
