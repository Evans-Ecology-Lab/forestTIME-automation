
# forestTIME-automation

<!-- badges: start -->
[![DOI](https://zenodo.org/badge/1044408066.svg)](https://doi.org/10.5281/zenodo.17088642)
<!-- badges: end -->

This repository automates monthly production and release of annualized tables created with the [`forestTIME` package](https://github.com/Evans-Ecology-Lab/forestTIME).
Get the data from the most recent [GitHub release](https://github.com/Evans-Ecology-Lab/forestTIME-automation/releases) or from the [Zenodo archive](https://doi.org/10.5281/zenodo.17088642).

### Troubleshooting

If this workflow is failing with a "400 bad request" error, it *might* be because there is an unpublished draft that needs to be "cleared".
Navigate to the latest record on Zenodo and if it is a draft, there should be a red "Discard version" button that you can click.
Then try running the workflow again.