# Project 7: Predicting STR Length Effects on Gene Expression with NTv3

Follow the [Project 6 description](../project_6/README.md), but use **Nucleotide Transformer v3 (NTv3)** instead of AlphaGenome.

Use an **NTv3 functional-track prediction model**, such as `NTv3_tracks`, which provides RNA-seq predictions. The pretrained backbone alone does not provide gene-expression predictions.

Use the same published eSTR statistics and supplied STR allele-length data as Project 6. Predict expression for different STR lengths in a suitable tissue, summarize the target gene's predicted RNA-seq signal, and compare the predicted length-effect direction with the published tissue-specific eSTR effect.

Adapt the sequence preparation and expression scoring to NTv3. Check the available tissue tracks and ensure the target gene is covered by the model's output region. AlphaGenome-specific API calls and scorers in Project 6 do not apply directly.

The scope, evaluation principles, and expected outputs are otherwise the same as Project 6. A comparison with AlphaGenome is optional.

## Documentation

- [NTv3 documentation](https://github.com/instadeepai/nucleotide-transformer/blob/main/docs/nucleotide_transformer_v3.md)
- [NTv3 tracks model](https://huggingface.co/InstaDeepAI/NTv3_tracks)

**Questions about data or project scope?** Contact me at [xiaf@zhaw.ch](mailto:xiaf@zhaw.ch).
