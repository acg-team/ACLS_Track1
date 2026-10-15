# Project 4: Predicting Tumor Characteristics from Histology Images Using UNI


## Background

Whole-slide images (WSIs) are very large digital images of tumor tissue. They contain information about tumor structure and the tumor microenvironment. The pretrained **UNI** model can convert small regions of a histology image into numerical features called **embeddings**. We can then use these features to train a model that predicts a tumor characteristic.

## Research question — choose one option

- **Option A — Colorectal cancer (TCGA-COAD / TCGA-READ):** Can features extracted from histology images distinguish **MSI-H** from **MSS** tumors?
- **Option B — Melanoma (TCGA-SKCM):** Can features extracted from histology images distinguish **BRAF-mutated** from **BRAF-wild-type** tumors?

**Contact me at [konl@zhaw.ch](mailto:konl@zhaw.ch) before starting** to get access to files.

## 1. First: request HPC access

You **must have access to the ZHAW HPC cluster** before starting this project.

1. Use your **student university email address** to request an HPC account.
2. Complete and submit the **[HPC access request form](https://signup.hpc.zhaw.ch/)**.
4. **Email to me [konl@zhaw.ch](mailto:konl@zhaw.ch)** once your account is active. I will give permission to access the folder with tumor images.

## 2. Data

### Histology slides

Tumor images is in:

```text
/cfs/earth/scratch/icls/shared/icls-14042025-cancer-genomics-image-analysis
```

**Do not write into it**. You should create their own working folder.

### Clinical and molecular labels

| Option | Data source |
| --- | --- | --- |
| CRC | [Project 1: COAD clinical data](../project_1/data/COAD/clinical_data.csv) or [READ clinical data](../project_1/data/READ/clinical_data.csv) | 
| Melanoma | [TCGA-SKCM PanCancer Atlas on cBioPortal](https://www.cbioportal.org/study/summary?id=skcm_tcga_pan_can_atlas_2018) (mutation and sample information), or request data from me.

For CRC, use `MSI_TMB`: `MSI-H` is the MSI-H group, and both `MSS/TMB-H` and `MSS/TMB-L` belong to the MSS group. Remove patients without a known label.

## 3. Connect to the cluster

Open a terminal and connect using HPC username:

```bash
ssh YOUR_USERNAME@login-rhel8.hpc.zhaw.ch
```

Prepare a working directory in your own scratch space:

```bash
export WORK=/cfs/earth/scratch/$USER/project_4
mkdir -p "$WORK"/{results,cache,tmp}
export TMPDIR="$WORK/tmp"
export XDG_CACHE_HOME="$WORK/cache"
export HF_HOME="$WORK/cache/huggingface"
export MPLCONFIGDIR="$WORK/cache/matplotlib"
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
```

Once you have folder permission, you can inspect the slides using:

```bash
export SLIDE_ROOT=/cfs/earth/scratch/icls/shared/icls-14042025-cancer-genomics-image-analysis
ls -lh "$SLIDE_ROOT" | head
find "$SLIDE_ROOT" -type f \( -iname '*.svs' -o -iname '*.tif' -o -iname '*.tiff' -o -iname '*.ndpi' \) | head -20
```

## 4. Request a GPU node with Slurm

Do heavy image processing on a **compute node**, not the login node. Example interactive allocation:

```bash
salloc -p earth-5 -t 04:00:00 -c 8 --mem=48G --gres=gpu:a100:1 --constraint=rhel8 --job-name=uni_project
```

When the allocation is granted, start a shell on the allocated compute node (if your cluster setup has not already placed you there):

```bash
srun --pty bash -l
hostname
echo "$SLURM_JOB_ID"
nvidia-smi
```

A different GPU partition (for example `earth-4` with an L40S) may be available. Release the allocation with `exit` when finished.

### Optional: Jupyter Notebook on a compute node

On the **allocated compute node**, after activating your Python environment:

```bash
jupyter notebook --no-browser --ip=0.0.0.0 --port=8890 --notebook-dir="$WORK"
```

Record the **actual** compute-node hostname shown by `hostname`. Then, in a **new terminal on your laptop**, create an SSH tunnel:

```bash
ssh -N -L 8890:COMPUTE_NODE_HOSTNAME:8890 YOUR_USERNAME@login-rhel8.hpc.zhaw.ch
```

Replace both placeholders. Open the notebook URL displayed by Jupyter (usually `http://localhost:8890/?token=...`) in your laptop browser. If port 8890 is already in use, choose another port consistently in both commands.

## 5. Read the UNI documentation and prepare your environment

Start with these official resources:

- [UNI GitHub repository — installation and inference](https://github.com/mahmoodlab/UNI)
- [UNI walkthrough notebook — extracting image features and downstream tasks](https://github.com/mahmoodlab/UNI/blob/main/notebooks/uni_walkthrough.ipynb)
- [UNI model on Hugging Face](https://huggingface.co/MahmoodLab/UNI)
- [UNI2-h model on Hugging Face](https://huggingface.co/MahmoodLab/UNI2-h)
- [TRIDENT — processing whole slides and extracting UNI features](https://github.com/mahmoodlab/TRIDENT)
- [TRIDENT documentation](https://trident-docs.readthedocs.io/en/latest/)

A possible fresh environment (run only where your HPC policy allows installation):

```bash
conda create -n uni_project python=3.10 -y
conda activate uni_project
cd "$WORK"
git clone https://github.com/mahmoodlab/UNI.git
cd UNI
pip install -e .
pip install openslide-python h5py scikit-learn pandas
```

To access gated model weights, log in using your own Hugging Face account:

```bash
hf auth login
```

See the [Hugging Face CLI authentication guide](https://huggingface.co/docs/huggingface_hub/guides/cli).

## 6. Extract image embeddings with UNI

Use the pretrained UNI encoder without changing its weights. Extract features from several tissue patches per slide, then create **one embedding per patient**. This allows a smaller classifier to be trained without fine-tuning the full image model.

### A. Test UNI on one image patch

The following example uses the original **UNI** model (not UNI2-h). It expects a **small RGB tissue image**, not a complete `.svs` whole-slide file.

```python
import torch
import timm
from PIL import Image
from timm.data import resolve_data_config
from timm.data.transforms_factory import create_transform

model = timm.create_model(
    "hf-hub:MahmoodLab/uni",
    pretrained=True,
    init_values=1e-5,
    dynamic_img_size=True,
    num_classes=0
).eval().to("cuda")

transform = create_transform(
    **resolve_data_config(model.pretrained_cfg, model=model)
)

patch = Image.open("/path/to/your_tissue_patch.png").convert("RGB")
x = transform(patch).unsqueeze(0).to("cuda")

with torch.inference_mode():
    embedding = model(x)

print(embedding.shape)  # For original UNI: [1, 1024]
```

UNI2-h uses a different architecture and **1536-dimensional** embeddings. Follow the [official UNI2-h model-loading example](https://github.com/mahmoodlab/UNI) if you choose UNI2-h. Do not mix embeddings from different models.

### B. Process whole-slide images

Whole-slide files are too large to load as ordinary images. First identify tumor/tissue regions, extract patch coordinates, and create patch embeddings. [TRIDENT](https://github.com/mahmoodlab/TRIDENT) provides an established workflow for segmentation, patch extraction, and UNI feature extraction.

For example, after installing TRIDENT and selecting **one authorized slide**:

```bash
python run_single_slide.py \
  --slide_path /path/to/authorized_slide.svs \
  --job_dir "$WORK/results/test_slide" \
  --patch_encoder uni_v1 \
  --mag 20 \
  --patch_size 256
```

Run this from the TRIDENT installation directory and check the [current TRIDENT instructions](https://github.com/mahmoodlab/TRIDENT) for options and dependencies. Start with **one slide** before processing more. Depending on the slide data, you may need to adjust magnification, tissue segmentation, or patch sampling.

### C. Combine patch embeddings into one patient embedding

For a simple baseline, **average the patch embeddings for each slide**, then average slide embeddings for patients with several slides. This is called **mean pooling**. Exclude background and poor-quality patches first. Keep track of how many patches and slides contributed to each patient.

Your final input table should look like this:

| patient_id | label | embedding_0 | embedding_1 | ... |
| --- | --- | ---: | ---: | --- |
| TCGA-XX-0001 | 1 | 0.12 | -0.35 | ... |
| TCGA-XX-0002 | 0 | 0.08 | 0.21 | ... |

One row should represent **one patient**, with `label = 1` for MSI-H or BRAF-mutated and `label = 0` for MSS or BRAF-wild-type, depending on the project. The embeddings will have 1024 columns for original UNI or 1536 for UNI2-h.

## 7. Train a classification head to predict MSI or BRAF status

**Do not retrain UNI from the beginning.** Keep the UNI encoder frozen and train a small prediction model on the extracted features. A linear classifier is an appropriate first baseline; in PyTorch, the equivalent prediction layer is `torch.nn.Linear(embedding_dim, 2)`.

Useful tutorials:

- [PyTorch transfer learning tutorial](https://docs.pytorch.org/tutorials/beginner/transfer_learning_tutorial.html) — frozen feature extractors and classification heads
- [scikit-learn logistic regression](https://scikit-learn.org/stable/modules/generated/sklearn.linear_model.LogisticRegression.html)
- [scikit-learn model evaluation](https://scikit-learn.org/stable/modules/model_evaluation.html)

## 8. Evaluate your model and interpret the results
