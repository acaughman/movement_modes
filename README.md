# Marine fish trait interactions give rise to unique ontogenetic movement combinations

This repository contains code used in the paper: Rosenberg, L.J., Bradley, D., Gaines, S.D., Caughman, A.M. Marine fish trait interactions give rise to unique ontogenetic movement combinations. Marine Ecology Progress Series. in Revision.

The associated zenodo repository is located at <a href="https://doi.org/10.5281/zenodo.15811366"><img src="https://zenodo.org/badge/612754347.svg" alt="DOI"></a>

For any questions, comments, or concerns, please contact Alicia Caughman [acaughman@bren.ucsb.edu](acaughman@bren.ucsb.edu).

# Instructions

The order of running scripts should be as follows: 

1. The first script clusters the movement data from (Darcy et al. 2024) `01_clustering.R`. It runs a Guassian Mixture model and produces a CSV file with the assigned clusters for each species.
2. The next script to be run is called `02_fishbase_data.Rmd`. This script .
3. The third script to be run is called `02_PCA.Rmd`. This script .
4. The fourth script in the folder `04_stats.Rmd` contains all code for .
5. The fifth script to be run is `05_figures.Rmd`. It contains all additional analysis and figure generation for the paper and supplemental material.
6. The final script to be run is `06_sensitivity.Rmd`. It runs all analysis and creates figures associated with the sensitivity analysis on two subsets of data: 1) constrained for uncertainty and 2) purely empirical

the 01_data folder contains the required .csv files for running all scripts.

# Repository Structure

## Overview of Files of Use

Please ignore folders/data/scripts no listed here

```
01_data
  |__ 01_raw_data
      |__homerange_pld.csv
      |__iucn_codes.csv
  |__ 02_processed_data
      |__clusters.csv 
      |__filled_data.csv
      |__homerange_pld_processed.csv
      |__hr_lm_constrained.csv 
      |__hr_lm_empirical.csv
      |__hr_lm.csv
      |__pld_lm_constrained.csv 
      |__pld_lm_empirical.csv
      |__pld_lm.csv
02_scripts
  |__01_clustering.Rmd
  |__02_fishbase_data.Rmd need to merge with fishbase_data_in.Rmd
  |__03_PCA.Rmd
  |__04_stats.Rmd
  |__05_figures.Rmd
  |__06_sensitivity.Rmd
03_figs 
  |__fig1.pdf
  |__fig2.pdf
  |__fig3.pdf
  |__fig4.pdf
  |__fig5.pdf
  |__supplemental
    |__figS1.pdf
    |__figS2.pdf
    |__figS3.pdf
    |__figS4.pdf
    |__figS5.pdf
    |__figS6.pdf
    |__figS7.pdf
```

# R Version

All code was run using R version 4.1.3

## Required Libraries

+ Data Ingestion, Cleaning, Harmonization, and Organization
  - `tidyverse` (version 2.0.0)
  - `here` (version 1.0.1)
  - `rfishbase` (version 4.0.0)
  - `naniar` (version 1.0.0)
  - `car` (version 3.1-2)
  - `rstatix` (version 0.7.2)
  - `FSA` (version 0.9.5)
+ Modelling and Statistics
  - `mclust` (version 5.4.10)
  - `AdaptGuass` (version 1.6)
  - `factoextra` (version 1.0.7)
  - `fpc` (version 2.2-11)
  - `FactoMineR` (version 2.10)
  - `vegan` (version 2.6-4)
  - `pairwiseAdonis` (version 0.4.1)
  - `effectsize` (version 0.8.6)
  - `chi.posthoc.test` (version 0.1.2)
  - `MASS` (version 7.3-60.0.1)
  - `marginaleffects` (version 0.18.0)
+ Data Visualization
  - `patchwork` (version 1.1.2)
  - `broom` (version 1.0.5)
  - `ggrepel` (version 0.9.5)
