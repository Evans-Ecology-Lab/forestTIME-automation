
# forestTIME-automation

<!-- badges: start -->
[![run_workflow.yml](https://github.com/Evans-Ecology-Lab/forestTIME-automation/actions/workflows/run_workflow.yml/badge.svg)](https://github.com/Evans-Ecology-Lab/forestTIME-automation/actions/workflows/run_workflow.yml)
[![DOI](https://zenodo.org/badge/1044408066.svg)](https://doi.org/10.5281/zenodo.17088642)
<!-- badges: end -->

This repository automates monthly production and release of annualized tables created with the [`forestTIME` package](https://github.com/Evans-Ecology-Lab/forestTIME).
Get the data from the most recent [Zenodo archive](https://doi.org/10.5281/zenodo.17088642).

### Editing Metadata

If you'd like to add authors, change the title, etc. this should be done directly on the zenodo record.
Create a new version, make edits, and publish.
This workflow copies the metatdata from the latest version and only updates the version number and publication date.


### Troubleshooting

If states with a lot of trees start failing, you may need to adjust this number: https://github.com/Evans-Ecology-Lab/forestTIME-automation/blob/661a92aa9fadda7d8411d9dbc89d16cddb5d957a/state-parquet.R

If the dataset has more than this many rows, it splits it into chunks before doing carbon estimation (the memory-intensive step).  Adding more columns to the data will likely necessitate lowering the threshold for number of rows to do this chunking.  More chunks means slower runs, but it may be necessary to work within the memory constraints of the GitHub runner (16GB for standard runners).