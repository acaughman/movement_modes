# Characterizing and Modeling Relationship Between Fish Home Range and Pelagic Larval Duration

This repository contains code used to characterize groupings of home range and PLD within fish and model the relationship between these two variables. It also contains the original random forest files and scripts for working on a case study.

For any questions, comments, or concerns, please contact Alicia Caughman [acaughman@bren.ucsb.edu](acaughman@bren.ucsb.edu).

# Instructions (For Lex)

Scripts you should use

1. `intro_instructions.Rmd`: contains the starting groupings and instructions for your work
2. `fishbase_ex.Rmd`: contains example code for extracting information from FishBase and modeling you can attempt to do to fill in gaps (Please discuss some of this with me in more depth before doing)
3. Any script you create in `02_scripts/characterization`

the Data folder contains the RData (.rda) outputs from simulations used in the main text of Caughman et al. `model_list.xlsx` contains a list of parameters used in each model.

# Repository Structure

## Overview of Files of Use

Please ignore folders/data/scripts no listed here

```
01_data
  |__ 01_raw_data
      |__homerange_rf_predictions.csv
      |__pld_rf_predictions.csv
  |__ 02_processed_data
      |__homerange_pld.csv
      |__clusters.csv
      |__output any final datasets with additional data from fishbase here
02_scripts
  |__characterization
      |__fishbase_ex.Rmd
      |__intro_instructions.Rmd
      |__old
          |__pld_hr_compare.Rmd
03_results
  |__ characterization
      |__output any .csv results you generate as part of your characterization here
  |__ modelling
      |__output any .csv or .rda modeling result data here
04_figs
  |__ characterization
      |__output any figs related to characterization here as .pdf 
  |__ modelling
      |__output any figs related to modelling here as .pdf 
05_writing_drafts
  |__ lex
      |__ put your "messy" methods and polished method drafts here
```

# R Version

All code was run using R version 4.1.3

## Required Libraries

Please make sure you update your package versions and list any packages you add here

+ Data Ingestion, Cleaning, Harmonization, and Organization
  - `tidyverse` (version 2.0.0)
  - `here` (version 1.0.1)
  - `rfishbase` (version 4.0.0)
+ Modelling
  - `mclust` (version 5.4.10)
+ Data Visualization
  - `patchwork` (version 1.1.2)