# PAPER TITLE

This repository contains code used in the paper: PAPER INFO

For any questions, comments, or concerns, please contact Alicia Caughman [acaughman@bren.ucsb.edu](acaughman@bren.ucsb.edu).

# Instructions

The order of running scripts should be as follows: 

UPDATE THESE TO MATCH OUR WORKFLOW - with brief info about what each script does and it's outputs. This is an example from my last paper

1. The first script is the simulation model `01_final_model.R`. It will produce a CSV file with the model data.
2. The next script to be run after all simulation models is called `02_data_merge.Rmd`. This script merges all simulation data into one CSV for additional analysis and plotting.
3. 
4. The fourth script in the folder `04_supplemental.Rmd` contains all code for analysis and figure generation in the supplemental.
5. The final script to be run is `05_figures.Rmd`. It contains all additional analysis and figure generation for the paper and supplemental material.

the 01_data folder contains the required .csv files for running all scripts.

# Repository Structure

## Overview of Files of Use

Please ignore folders/data/scripts no listed here

```
01_data
  |__ 01_raw_data
      |__homerange_pld.csv
  |__ 02_processed_data
      |__clusters.csv 
      |__ TO DO delete data that isn't used in paper scripts a add columns here
02_scripts
  |__01_fishbase_data.Rmd
  |__02_clustering.Rmd
  |__03_PCA.Rmd
  |__04_stats.Rmd
  |__05_figures.Rmd
03_figs TO DO change folder name and fix file paths and strucutre file this way deleting all extra
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
```

# R Version

All code was run using R version 4.1.3

## Required Libraries

TO DO Update This

+ Data Ingestion, Cleaning, Harmonization, and Organization
  - `tidyverse` (version 2.0.0)
  - `here` (version 1.0.1)
  - `rfishbase` (version 4.0.0)
+ Modelling and Statistics
  - `mclust` (version 5.4.10)
+ Data Visualization
  - `patchwork` (version 1.1.2)