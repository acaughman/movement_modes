library(tidyverse)

pisco_hr <- read_csv(here::here("01_data", "02_processed_data", "pisco_rf_hr_predict.csv"))
pisco_pld <- read_csv(here::here("01_data", "02_processed_data", "pisco_rf_pld_predict.csv"))
pisco = read_csv(here::here("01_data", "01_raw_data", "PISCO_kelpforest_fish.1.3.csv"))
pisco_site <- read_csv(here::here("01_data", "01_raw_data", "PISCO_kelpforest_site_table.1.2.csv"))
pisco_taxa <- read_csv(here::here("01_data", "01_raw_data", "PISCO_kelpforest_taxon_table.1.2.csv"))

pisco <- list(pisco, pisco_site, pisco_taxa) %>%
  reduce(full_join) %>% 
  rename(species = species_definition)

pisco_rf = full_join(pisco_hr, pisco_pld) %>% 
  mutate(home_range = case_when(
    !is.na(observed_homerange) ~ observed_homerange,
    is.na(observed_homerange) ~ predicted_homerange
  )) %>%
  mutate(pld = case_when(
    !is.na(observed_PLD) ~ observed_PLD,
    is.na(observed_PLD) ~ predicted_PLD
  )) %>%
  filter(pld < 400) %>%
  mutate(magnitude_homerange = floor(log10(home_range))) %>%
  mutate(month_pld = ceiling(pld / 30)) %>% 
  mutate(class = case_when(
    magnitude_homerange %in% c(1, 0, -1) & month_pld %in% c(2) ~ 1,
    magnitude_homerange > 1 ~ 2,
    month_pld == 3 ~ 3,
    magnitude_homerange < 2 & month_pld %in% c(1) ~ 4,
    month_pld > 3 ~ 5,
    magnitude_homerange < -3 & month_pld %in% c(2) ~ 7,
    magnitude_homerange %in% c(-2, -3) & month_pld %in% c(2) ~ 8
  )) %>% 
  select(species, class, magnitude_homerange, month_pld) %>% 
  mutate(class = as.factor(class))

pisco = full_join(pisco, pisco_rf, multiple = "all") %>%
  filter(campus == "UCSB") %>%
  filter(!is.na(count)) %>%
  filter(!is.na(species))

pisco_species <- pisco %>%
  select(species, magnitude_homerange, month_pld, class) %>%
  distinct() %>% 
  na.omit()

ggplot(pisco_species, aes(magnitude_homerange, month_pld, color = class)) +
  geom_jitter(size = 2.5) +
  theme_bw()

species_list <- pisco_species %>%
  pull(species)

pisco$date <- as.Date(with(pisco, paste(year, month, day, sep = "-")), "%Y-%m-%d")

pisco <- pisco %>%
  filter(species %in% species_list) %>%
  filter(site_status == "MPA")

pisco_sum <- pisco %>%
  group_by(MPA_Name, species, date, class) %>%
  summarize(average_count = mean(count))

pisco_count = pisco_sum %>% 
  group_by(MPA_Name, species, class) %>%
  summarize(count = n()) %>% 
  filter(count <= 5) %>% 
  pull(species)

pisco_sum = pisco_sum %>% 
  filter(species %in% pisco_count)

ggplot(pisco_sum) +
  geom_point(aes(date, average_count, color = species)) +
  geom_line(aes(date, average_count, color = species, group = 1)) +
  facet_wrap(~MPA_Name, scales = "free") +
  theme_bw() +
  theme(legend.position = "none")
