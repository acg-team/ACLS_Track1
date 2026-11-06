# Project 6: Predicting STR Length Effects on Gene Expression with AlphaGenome

## Background

Short tandem repeats (STRs) can have alleles with different numbers of motif copies. Some STRs are associated with gene expression; these are called expression-associated STRs (eSTRs). In this project, you will change STR length in a genomic sequence, predict the resulting RNA-seq signal with AlphaGenome, and compare the predicted length effect with published eSTR statistics.

The aim is to test whether AlphaGenome reproduces the direction and relative strength of observed associations.

## Research questions

1. Does increasing STR length increase or decrease predicted expression of the associated gene?
2. Is the predicted response approximately linear, monotonic, or nonlinear across observed allele lengths?
3. Does the predicted direction agree with the published eSTR effect in the corresponding tissue?

## Data and access

### Published eSTR statistics

Use the tissue-specific tables in the data folder `41588_2019_521_MOESM5_ESM`. This is the supplementary data 1 from https://www.nature.com/articles/s41588-019-0521-9.

Important fields include:

| Field | Use |
| --- | --- |
| `chrom`, `str.start`, `str.end` | STR coordinates in **hg19** |
| `gene`, `gene.name`, `gene.strand` | Associated gene identifier, symbol, and strand |
| `str.motif.forward`, `str.motif.reverse` | Repeat motif information |
| `linreg.beta`, `linreg.beta.se` | Observed association effect estimate and standard error |
| `linreg.top.str`, `linreg.significant` | Identify top STR associations and the supplied significance calls |
| `mashr.beta`, `mashr.beta.se` | Alternative effect estimates for a sensitivity analysis |
| `anova.qval`, `caviar.str.score` | Optional information about SNP-adjusted association and fine-mapping |

Read the original study methods to establish how STR length and expression were encoded and standardized before interpreting coefficient units. 

### Allele lengths

The locus-specific allele-copy counts for STR will be provided.

### AlphaGenome and reference sequence

- [AlphaGenome quick start](https://www.alphagenomedocs.com/colabs/v1/quick_start.html)
- [AlphaGenome input conventions and FAQ](https://www.alphagenomedocs.com/faqs.html)
- [Variant scoring documentation](https://www.alphagenomedocs.com/variant_scoring.html)
- [Gene-mask expression effect scorer](https://www.alphagenomedocs.com/api/generated/alphagenome.models.variant_scorers.GeneMaskLFCScorer.html)

Arrange AlphaGenome access and check the available request quota before selecting the final number of loci. Record model and SDK versions. API-based inference is sufficient; training a model is not required.

## Analysis workflow

### Step 1 — Select tissue and loci

Inspect AlphaGenome output metadata and choose a tissue with a defensible match to an eSTR table. Record the exact ontology term and RNA-seq track names. Predefine how multiple matching tracks will be combined; do not choose the track with the best agreement after seeing results.

For the core analysis, select top, significant eSTRs with observed allele distributions, unambiguous gene mapping, and simple uninterrupted repeats. Include positive and negative observed effects where possible. 

### Step 2 — Harmonize coordinates and verify sequence

The eSTR tables use **hg19**, while AlphaGenome's human reference is **hg38**. Convert the full STR interval to hg38 using a documented mapping method. Check gene identity against hg38 annotation, retaining stable Ensembl IDs while recording original versioned IDs.

Verify both flanks, motif, strand, and repeat boundaries against the hg19 and hg38 reference sequences. Mapping endpoints alone is insufficient in repetitive regions. Exclude ambiguous mappings or loci where the repeat cannot be reconciled. Reference copy number may differ between assemblies; keep observed absolute allele lengths separate from differences relative to the hg38 reference.

AlphaGenome intervals use 0-based, half-open coordinates. Establish the source coordinate convention before conversion and check reference bases explicitly. Do not infer interval length by subtracting coordinates until the convention is known.

### Step 3 — Construct a controlled allele series

For each locus, construct alleles by adding or removing complete motif units on the same hg38 background. Use only observed lengths for the primary analysis. 

Represent each non-reference allele as a validated, anchored insertion/deletion relative to hg38, and verify its reference bases. Use AlphaGenome's variant interface for the main workflow. This avoids manually passing unsupported sequence lengths. 

If using custom sequences instead, keep input lengths supported by the model, preserve genomic context, and explicitly remap target-gene coordinates after each insertion/deletion. 

### Step 4 — Predict target-gene expression effects

Request **RNA_SEQ** outputs for reference and alternate alleles. For the core quantitative analysis, use the documented **GeneMaskLFCScorer** to obtain a signed, exon-aggregated expression change for the target gene relative to the hg38 reference. Filter scores to the prespecified tissue tracks and gene. Use raw signed effect scores rather than quantile ranks.

The scorer provides a gene-level log-fold-change summary, not measured TPM. Keep the reference allele at zero relative effect. Save reference/alternate RNA-seq tracks for the two pilot loci to visualize the underlying prediction; compact gene-level scores are sufficient for the remaining loci. Use the SDK's documented indel alignment rather than comparing unaligned base positions.

Run an unchanged-sequence control and check that its expression difference is zero within numerical tolerance. Check one expansion and one contraction manually before scaling up. Cache successful results and record failed requests.

### Step 5 — Quantify the predicted length response

For each STR–gene pair and tissue, let `L` be the motif-copy count and `D(L)` be the predicted expression effect relative to reference. Fit the descriptive relationship:

```text
D(L) = intercept + beta_predicted * (L - L_reference)
```

Report the predicted slope, its direction, Spearman correlation between length and predicted effect, total predicted effect range, and a length-response plot. Flag flat or nonlinear responses explicitly. Set a small-effect tolerance before assessing direction and examine sensitivity to that choice.

Use an unweighted slope as the primary summary. As an optional sensitivity analysis, weight observed lengths by their GTEx counts, clearly stating that this is a marginal allele-frequency approximation rather than a reconstruction of individual diploid genotypes.

### Step 6 — Compare predictions with observed eSTR statistics

Join predictions and observed results by validated locus, stable gene ID, and tissue.

| Comparison | Interpretation |
| --- | --- |
| Sign of `beta_predicted` versus `linreg.beta` | Primary measure: agreement in expression-effect direction |
| Predicted slope versus observed effect across loci | Exploratory rank agreement; report signed and absolute-effect comparisons separately |
| Comparison with `mashr.beta` | Sensitivity to the observed association estimator |
| Agreement in loci with stronger fine-mapping support | Optional exploration of whether SNP linkage helps explain disagreements |

Report concordant, discordant, and flat/indeterminate cases with explicit denominators. If reporting uncertainty for concordance, use independent loci as the sampling units, not alleles or tracks. For a small selected panel, treat confidence intervals and correlations as descriptive and acknowledge selection bias.

## Expected outputs

- A locus manifest with hg19/hg38 coordinates, gene IDs, tissue tracks, motifs, mapping checks, and exclusion reasons.
- An allele manifest with copy count, length in bp, observed count, hg38-relative change, and variant representation.
- Reproducible scripts or notebooks for data preparation, inference, and comparison, with dependency versions and no credentials.
- A prediction table with one row per locus–gene–allele–track and a summary table with one row per locus–gene–tissue.
- Length-response plots for selected examples, an observed-versus-predicted effect plot, and a direction-concordance summary.
- A written report following the [course requirements](../../README.md), including a **Statement of AI Use**.

**Questions about data or project scope?** Contact me at [xiaf@zhaw.ch](mailto:xiaf@zhaw.ch).
