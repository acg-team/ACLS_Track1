
# ==========================================
# TCGA RNA-seq download and preprocessing
# UCEC, STAD, READ, COAD
# ==========================================

# 1. Install packages
if (!requireNamespace("BiocManager", quietly = TRUE)) {
  install.packages("BiocManager")
}

for (pkg in c("TCGAbiolinks", "SummarizedExperiment")) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    BiocManager::install(pkg, ask = FALSE, update = FALSE)
  }
}

if (!requireNamespace("data.table", quietly = TRUE)) {
  install.packages("data.table")
}

library(TCGAbiolinks)
library(SummarizedExperiment)
library(data.table)

# 2. Settings
projects <- c(
  "TCGA-UCEC",
  "TCGA-STAD",
  "TCGA-READ",
  "TCGA-COAD"
)

output_dir <- "data"
dir.create(output_dir, showWarnings = FALSE)

# 3. Function to save compressed expression matrix
save_matrix <- function(mat, filename) {
  dt <- as.data.table(mat, keep.rownames = "gene")
  fwrite(dt, filename, sep = "\t", compress = "gzip")
}

# 4. Download and process each cohort
for (project in projects) {

  message("\nProcessing: ", project)

  cohort <- sub("TCGA-", "", project)

  cohort_dir <- file.path(output_dir, cohort)
  raw_dir <- file.path(cohort_dir, "GDCdata")

  dir.create(cohort_dir, recursive = TRUE,
             showWarnings = FALSE)
  dir.create(raw_dir, recursive = TRUE,
             showWarnings = FALSE)

  # Query only primary tumors
  query <- GDCquery(
    project = project,
    data.category = "Transcriptome Profiling",
    data.type = "Gene Expression Quantification",
    workflow.type = "STAR - Counts",
    sample.type = "Primary Tumor",
    access = "open"
  )

  # Download
  GDCdownload(
    query,
    method = "api",
    files.per.chunk = 20,
    directory = raw_dir
  )

  # Prepare SummarizedExperiment
  se <- GDCprepare(
    query,
    directory = raw_dir
  )

  # ----------------------------------------
  # 5. Select one sample per patient
  # ----------------------------------------

  cd <- as.data.frame(colData(se))

  sample_ids <- colnames(se)
  patient_ids <- substr(sample_ids, 1, 12)

  # Collection date information, if available
  if ("days_to_collection" %in% colnames(cd)) {
    days <- suppressWarnings(
      as.numeric(as.character(cd$days_to_collection))
    )
  } else {
    days <- rep(NA_real_, length(sample_ids))
  }

  metadata <- data.frame(
    project = project,
    patient_id = patient_ids,
    sample_id = sample_ids,
    days_to_collection = days,
    stringsAsFactors = FALSE
  )

  # Number of samples and available dates per patient
  metadata$n_patient_samples <- as.integer(
    table(metadata$patient_id)[metadata$patient_id]
  )

  metadata$n_dated_samples <- ave(
    !is.na(metadata$days_to_collection),
    metadata$patient_id,
    FUN = sum
  )

  # Prefer samples with known collection dates.
  # Among dated samples, select the largest day.
  # Use barcode only as a deterministic tie-breaker.
  ordering <- order(
    metadata$patient_id,
    -as.integer(!is.na(metadata$days_to_collection)),
    -ifelse(is.na(metadata$days_to_collection),
            -Inf, metadata$days_to_collection),
    metadata$sample_id
  )

  selected_idx <- ordering[
    !duplicated(metadata$patient_id[ordering])
  ]

  metadata <- metadata[selected_idx, , drop = FALSE]

  metadata$selection_note <- ifelse(
    metadata$n_patient_samples == 1,
    "only_sample",
    ifelse(
      metadata$n_dated_samples == metadata$n_patient_samples &
        metadata$n_dated_samples > 0,
      "latest_recorded_collection_day",
      ifelse(
        metadata$n_dated_samples > 0,
        "latest_among_dated_samples_only",
        "no_date_barcode_tiebreak"
      )
    )
  )

  # Keep selected samples
  se <- se[, metadata$sample_id]

  stopifnot(
    !anyDuplicated(metadata$patient_id),
    identical(colnames(se), metadata$sample_id)
  )

  message("Patients retained: ", ncol(se))

  # Save metadata
  fwrite(
    metadata,
    file.path(cohort_dir, "sample_metadata.tsv"),
    sep = "\t"
  )

  # ----------------------------------------
  # 6. Extract counts and TPM
  # ----------------------------------------

  required_assays <- c("unstranded", "tpm_unstrand")

  if (!all(required_assays %in% assayNames(se))) {
    stop(
      "Missing expected assays: ",
      paste(setdiff(required_assays, assayNames(se)),
            collapse = ", ")
    )
  }

  counts <- assay(se, "unstranded")
  tpm <- assay(se, "tpm_unstrand")

  # Save raw counts with Ensembl IDs
  save_matrix(
    counts,
    file.path(cohort_dir, "counts_ensembl.tsv.gz")
  )

  # ----------------------------------------
  # 7. Gene annotation
  # ----------------------------------------

  gene_data <- as.data.frame(rowData(se))

  gene_id <- rownames(se)
  gene_symbol <- as.character(gene_data$gene_name)
  gene_type <- as.character(gene_data$gene_type)

  annotation <- data.frame(
    gene_id = gene_id,
    gene_symbol = gene_symbol,
    gene_type = gene_type
  )

  fwrite(
    annotation,
    file.path(cohort_dir, "gene_annotation.tsv"),
    sep = "\t"
  )

  # ----------------------------------------
  # 8. Prepare protein-coding genes
  # ----------------------------------------

  valid <- !is.na(gene_symbol) &
    nzchar(gene_symbol) &
    !is.na(gene_type) &
    gene_type == "protein_coding"

  # If several Ensembl IDs share the same symbol,
  # keep the one with the highest mean TPM.
  valid_idx <- which(valid)

  mean_tpm <- rowMeans(tpm[valid_idx, , drop = FALSE])

  gene_order <- order(
    gene_symbol[valid_idx],
    -mean_tpm,
    gene_id[valid_idx]
  )

  ordered_idx <- valid_idx[gene_order]

  selected_genes <- ordered_idx[
    !duplicated(gene_symbol[ordered_idx])
  ]

  tpm_symbols <- tpm[selected_genes, , drop = FALSE]

  rownames(tpm_symbols) <- gene_symbol[selected_genes]

  # ----------------------------------------
  # 9. Transform expression
  # ----------------------------------------

  log2_tpm <- log2(tpm_symbols + 1)

  # Save TPM for EPIC
  save_matrix(
    tpm_symbols,
    file.path(cohort_dir, "TPM_symbols.tsv.gz")
  )

  # Save transformed expression for ML / PCA
  save_matrix(
    log2_tpm,
    file.path(cohort_dir, "log2TPM_symbols.tsv.gz")
  )

  # ----------------------------------------
  # 10. Summary
  # ----------------------------------------

  message("Cohort: ", cohort)
  message("Patients: ", ncol(tpm_symbols))
  message("Protein-coding genes: ", nrow(tpm_symbols))
  message("Missing collection dates: ",
          sum(is.na(metadata$days_to_collection)))
  message("Finished: ", project)

  rm(se, counts, tpm, tpm_symbols, log2_tpm)
  gc()
}

message("\nAll projects completed.")



library(data.table)

# Input and output paths
input_dir <- "data"
output_dir <- "Projects/project_1/data"

cohorts <- c("COAD", "READ", "STAD", "UCEC")

dir.create(output_dir, recursive = TRUE,
           showWarnings = FALSE)

# ==========================================
# 1. Create one shared gene annotation
# ==========================================

annotations <- lapply(cohorts, function(cohort) {

  path <- file.path(input_dir, cohort,
                    "gene_annotation.tsv")

  ann <- fread(path)

  ann <- ann[, .(gene_id, gene_symbol)]

  ann
})

annotation <- unique(rbindlist(annotations))

# Check for conflicting gene annotations
conflicts <- annotation[
  , .(n_symbols = uniqueN(gene_symbol)),
  by = gene_id
][n_symbols > 1]

if (nrow(conflicts) > 0) {
  stop("Conflicting gene annotations found.")
}

setorder(annotation, gene_id)

fwrite(
  annotation,
  file.path(output_dir, "gene_annotation.tsv"),
  sep = "\t"
)

# ==========================================
# 2. Process each cancer type
# ==========================================

for (cohort in cohorts) {

  message("Processing ", cohort)

  src <- file.path(input_dir, cohort)
  dst <- file.path(output_dir, cohort)

  dir.create(dst, recursive = TRUE,
             showWarnings = FALSE)

  # Read existing expression data
  counts <- fread(
    file.path(src, "counts_ensembl.tsv.gz")
  )

  tpm <- fread(
    file.path(src, "TPM_symbols.tsv.gz")
  )

  metadata <- fread(
    file.path(src, "sample_metadata.tsv")
  )

  # Expected format from the previous script:
  # first column = gene
  # other columns = TCGA sample IDs

  stopifnot("gene" %in% names(counts))
  stopifnot("gene" %in% names(tpm))
  stopifnot("sample_id" %in% names(metadata))

  samples <- metadata$sample_id

  stopifnot(
    all(samples %in% names(counts)),
    all(samples %in% names(tpm)),
    !anyDuplicated(samples)
  )

  # ========================================
  # 3. Convert count gene IDs to symbols
  # ========================================

  gene_symbols <- annotation$gene_symbol[
    match(counts$gene, annotation$gene_id)
  ]

  # Remove genes without a valid symbol
  valid <- !is.na(gene_symbols) &
           nzchar(gene_symbols)

  # Raw count matrix
  counts_matrix <- as.matrix(
    counts[valid, ..samples]
  )

  # Combine Ensembl IDs sharing a symbol.
  # Summing counts preserves raw count scale.
  counts_symbols <- rowsum(
    counts_matrix,
    group = gene_symbols[valid],
    reorder = FALSE
  )

  # ========================================
  # 4. Match counts and TPM genes
  # ========================================

  # TPM already uses gene symbols
  # from the previous processing script.

  if (anyDuplicated(tpm$gene)) {
    stop("Duplicated gene symbols in TPM: ", cohort)
  }

  # Keep genes present in both matrices.
  # This also matches the protein-coding gene
  # selection used in the previous TPM script.
  common_genes <- tpm$gene[
    tpm$gene %in% rownames(counts_symbols)
  ]

  counts_symbols <- counts_symbols[
    common_genes, , drop = FALSE
  ]

  tpm <- tpm[
    match(common_genes, gene)
  ]

  # Make sure sample columns have the same order
  tpm <- tpm[, c("gene", samples), with = FALSE]

  # Convert counts matrix to data.table
  counts_out <- as.data.table(
    counts_symbols,
    keep.rownames = "gene"
  )

  # ========================================
# Replace sample IDs with patient IDs
# ========================================

stopifnot(
  !anyDuplicated(metadata$patient_id),
  identical(names(counts_out)[-1], samples),
  identical(names(tpm)[-1], samples)
)

# Replace column names
setnames(
  counts_out,
  old = metadata$sample_id,
  new = metadata$patient_id
)

setnames(
  tpm,
  old = metadata$sample_id,
  new = metadata$patient_id
)

# Verify
stopifnot(
  identical(names(counts_out)[-1], metadata$patient_id),
  identical(names(tpm)[-1], metadata$patient_id)
)

  # ========================================
  # 5. Save final files
  # ========================================

  fwrite(
    counts_out,
    file.path(dst, "counts.tsv"),
    sep = "\t"
  )

  fwrite(
    tpm,
    file.path(dst, "tpm.csv"),
    sep = ","
  )

  fwrite(
    metadata,
    file.path(dst, "sample_metadata.tsv"),
    sep = "\t"
  )

  # ========================================
  # 6. Validate
  # ========================================

  stopifnot(
    identical(counts_out$gene, tpm$gene),
    identical(
      names(counts_out)[-1],
      names(tpm)[-1]
    ),
    nrow(counts_out) == nrow(tpm),
    ncol(counts_out) == ncol(tpm)
  )

  message(
    cohort, ": ",
    length(common_genes), " genes, ",
    length(samples), " samples"
  )

  rm(counts, tpm, counts_matrix,
     counts_symbols, counts_out)

  gc()
}

message("All datasets prepared successfully.")
