library(tidyverse)

pisco_fish <- read_csv(here::here("01_data", "01_raw_data", "PISCO_kelpforest_fish.1.3.csv"))
pisco_site <- read_csv(here::here("01_data", "01_raw_data", "PISCO_kelpforest_site_table.1.2.csv"))
pisco_taxa <- read_csv(here::here("01_data", "01_raw_data", "PISCO_kelpforest_taxon_table.1.2.csv"))

pisco <- list(pisco_fish, pisco_site, pisco_taxa) %>%
  reduce(full_join) %>%
  filter(campus == "UCSB") %>%
  filter(!is.na(count)) %>%
  filter(!is.na(species_definition)) %>%
  rename(species = species_definition)

pisco_species <- pisco %>%
  select(species) %>%
  distinct()

data <- read_csv(here::here("01_data", "02_processed_data", "homerange_pld.csv")) %>%
  mutate(home_range = case_when(
    !is.na(observed_homerange) ~ observed_homerange,
    is.na(observed_homerange) ~ predicted_homerange
  )) %>%
  mutate(pld = case_when(
    !is.na(observed_pld) ~ observed_pld,
    is.na(observed_pld) ~ predicted_pld
  )) %>%
  filter(pld < 400) %>%
  mutate(magnitude_homerange = floor(log10(home_range))) %>%
  mutate(month_pld = ceiling(pld / 30)) %>%
  mutate(month_pld = as.factor(month_pld)) %>%
  mutate(magnitude_homerange = as.factor(magnitude_homerange))

species <- left_join(pisco_species, data) %>%
  filter(!is.na(home_range))

ggplot(species, aes(magnitude_homerange, month_pld, color = month_pld, shape = magnitude_homerange)) +
  geom_jitter(size = 2.5) +
  theme_bw()

species_list <- species %>%
  pull(species)

pisco$date <- as.Date(with(pisco, paste(year, month, day, sep = "-")), "%Y-%m-%d")

pisco <- pisco %>%
  filter(species %in% species_list) %>%
  filter(site_status == "MPA")

data <- data %>%
  filter(species %in% species_list)

pisco_sum <- pisco %>%
  group_by(MPA_Name, species, date) %>%
  summarize(average_count = mean(count))

Sebastes_carnatus <- pisco_sum %>%
  filter(species == "Sebastes carnatus")

ggplot(Sebastes_carnatus) +
  geom_point(aes(date, average_count, color = species)) +
  geom_line(aes(date, average_count, color = species, group = 1)) +
  facet_wrap(~MPA_Name, scales = "free") +
  theme_bw() +
  theme(legend.position = "none")

Sebastes_mystinus <- pisco_sum %>%
  filter(species == "Sebastes mystinus")

ggplot(Sebastes_mystinus) +
  geom_point(aes(date, average_count, color = species)) +
  geom_line(aes(date, average_count, color = species, group = 1)) +
  facet_wrap(~MPA_Name, scales = "free") +
  theme_bw() +
  theme(legend.position = "none")

Ophiodon_elongatus <- pisco_sum %>%
  filter(species == "Ophiodon elongatus")

ggplot(Ophiodon_elongatus) +
  geom_point(aes(date, average_count, color = species)) +
  geom_line(aes(date, average_count, color = species, group = 1)) +
  facet_wrap(~MPA_Name, scales = "free") +
  theme_bw() +
  theme(legend.position = "none")
