library(tidyverse)
library(lmtest)

# Data Loading ------------------------------------------------------------


pisco_hr <- read_csv(here::here("01_data", "02_processed_data", "pisco_rf_hr_predict.csv")) %>% 
  select(observed_homerange, predicted_homerange, species)
pisco_pld <- read_csv(here::here("01_data", "02_processed_data", "pisco_rf_pld_predict.csv")) %>% 
  select(observed_PLD, predicted_PLD, species) %>% 
  mutate(predicted_PLD = case_when(
    species %in% c("Prionace glauca", "Alopias vulpinus") ~ 0,
    TRUE ~ predicted_PLD
  ))
pisco = read_csv(here::here("01_data", "01_raw_data", "PISCO_kelpforest_fish.1.3.csv"))
pisco_site <- read_csv(here::here("01_data", "01_raw_data", "PISCO_kelpforest_site_table.1.2.csv"))
pisco_taxa <- read_csv(here::here("01_data", "01_raw_data", "PISCO_kelpforest_taxon_table.1.2.csv"))


# Data Manipulation -------------------------------------------------------

pisco <- list(pisco, pisco_site, pisco_taxa) %>%
  reduce(full_join) %>% 
  rename(species = species_definition)

pisco_rf = full_join(pisco_hr, pisco_pld, multiple = "all") %>% 
  group_by(species) %>% 
  reframe(predicted_homerange = mean(predicted_homerange, na.rm=TRUE),
            predicted_PLD = mean(predicted_PLD, na.rm=TRUE),
            observed_homerange = observed_homerange,
            observed_PLD = observed_PLD) %>% 
  mutate(home_range = case_when(
    !is.na(observed_homerange) ~ observed_homerange,
    is.na(observed_homerange) ~ predicted_homerange
  )) %>%
  rename(pld = predicted_PLD) %>%
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

pisco = full_join(pisco, pisco_species)

pisco_sum <- pisco %>%
  mutate(month = month(date),
         year = year(date),
         month_year = year * 100 + month) %>% 
  group_by(MPA_Name, species, month_year, class) %>%
  reframe(average_count = mean(count),
            magnitude_homerange = magnitude_homerange,
            month_pld = month_pld)


pisco_count = pisco_sum %>% 
  group_by(MPA_Name, species, class) %>%
  summarize(count = n()) 

pisco_data = full_join(pisco_count, pisco_sum, multiple = "all")

pisco_class = pisco_data %>% 
  ungroup() %>% 
  select(species, class, magnitude_homerange, month_pld) %>% 
  distinct()

full_sum = pisco_sum %>% 
  group_by(class, month_year, MPA_Name) %>% 
  summarize(average_count = mean(average_count)) %>% 
  filter(average_count < 1000)


# Full Plots --------------------------------------------------------------

f1 = ggplot(pisco_class, aes(magnitude_homerange, month_pld, color = class)) +
  geom_jitter(size = 2.5) +
  theme_bw() + 
  labs(x = "Order of Magnitude of Home Range",
       y = "Pelgaic Larval Duratino Month")
f1

#ggsave(f1, file = paste0("pisco_class.png"), path = here::here("04_figs", "chanel_islands"))

ggplot(pisco_data %>% filter(count > 5)) +
  #geom_point(aes(month_year, average_count, color = class)) +
  geom_line(aes(month_year, average_count, color = class, linetype = species)) +
  facet_wrap(~MPA_Name, scales = "free") +
  theme_bw() + 
  guides(linetype = FALSE)

ggplot(full_sum, aes(month_year, log(average_count))) +
  geom_point(aes(color = class), size = 2.5) +
  facet_wrap(~MPA_Name, scales = "free") +
  theme_bw()
  #geom_smooth(method = "lm", aes(color = class), se = FALSE)

full_sum_sub = full_sum %>% 
  filter(MPA_Name %in% c("Anacapa Island SMR", "Campus Point SMCA", "Edward Ricketts SMCA", "Naples SMCA", "Point Dume SMR", "Scorpion SMR", "Santa Barbara Island SMR", "South Point SMR"))

f2 = ggplot(full_sum_sub, aes(month_year, log(average_count))) +
  geom_point(aes(color = class), size = 2.5) +
  facet_wrap(~MPA_Name, scales = "free", nrow = 2) +
  theme_bw(base_size = 20) + geom_smooth(method = "lm", aes(color = class), se = FALSE) +
  theme(strip.text = element_text(face = "bold"),
        strip.background = element_rect(fill = "white"),
        axis.text.x = element_text(angle = 60, hjust=1)) +
  labs(x = "Time", y = "Log of Average Count")
f2

#ggsave(f2, file = paste0("class_sum.png"), path = here::here("04_figs", "chanel_islands"), height = 10, width = 15)

# Vandenberg --------------------------------------------------------------

vand_SMR = pisco_data %>% 
  filter(MPA_Name == "Vandenberg SMR")

ggplot(vand_SMR, aes(magnitude_homerange, month_pld, color = class)) +
  geom_jitter(size = 2.5) +
  theme_bw()

ggplot(vand_SMR) +
  #geom_point(aes(date, average_c count, color = species)) +
  geom_line(aes(month_year, average_count, color = class, linetype = species)) +
  theme_bw() +
  guides(linetype = FALSE)

vand_sum = vand_SMR %>% 
  group_by(class, month_year) %>% 
  summarize(average_count = mean(average_count))

ggplot(vand_sum, aes(month_year, average_count)) +
  geom_point(aes(color = class), size = 2.5) +
  theme_bw()

# South Point -------------------------------------------------------------

south_SMR = pisco_data %>% 
  filter(MPA_Name == "South Point SMR")

ggplot(south_SMR, aes(magnitude_homerange, month_pld, color = class)) +
  geom_jitter(size = 2.5) +
  theme_bw()

ggplot(south_SMR) +
  #geom_point(aes(date, average_count, color = species)) +
  geom_line(aes(month_year, average_count, color = class, linetype = species)) +
  theme_bw() +
  guides(linetype = FALSE)

south_sum = south_SMR %>% 
  group_by(class, month_year) %>% 
  summarize(average_count = mean(average_count)) %>% 
  filter(class !=3)

ggplot(south_sum, aes(month_year, average_count)) +
  geom_point(aes(color = class), size = 2.5) +
  theme_bw()

# Scorpion ----------------------------------------------------------------

scorpion_SMR = pisco_data %>% 
  filter(MPA_Name == "Scorpion SMR")

ggplot(scorpion_SMR, aes(magnitude_homerange, month_pld, color = class)) +
  geom_jitter(size = 2.5) +
  theme_bw()

ggplot(scorpion_SMR) +
  #geom_point(aes(date, average_count, color = species)) +
  geom_line(aes(month_year, average_count, color = class, linetype = species)) +
  theme_bw() +
  guides(linetype = FALSE)

scorpion_sum = scorpion_SMR %>% 
  group_by(class, month_year) %>% 
  summarize(average_count = mean(average_count))

ggplot(scorpion_sum, aes(month_year, average_count)) +
  geom_point(aes(color = class), size = 2.5) +
  theme_bw()

# Gull Island -------------------------------------------------------------
gull_SMR = pisco_data %>% 
  filter(MPA_Name == "Gull Island SMR")

ggplot(gull_SMR, aes(magnitude_homerange, month_pld, color = class)) +
  geom_jitter(size = 2.5) +
  theme_bw()

ggplot(gull_SMR) +
  #geom_point(aes(date, average_count, color = species)) +
  geom_line(aes(month_year, average_count, color = class, linetype = species)) +
  theme_bw() +
  guides(linetype = FALSE)

gull_sum = gull_SMR %>% 
  group_by(class, month_year) %>% 
  summarize(average_count = mean(average_count))

ggplot(gull_sum, aes(month_year, average_count)) +
  geom_point(aes(color = class), size = 2.5) +
  theme_bw()

# Santa Barbara -----------------------------------------------------------
sb_SMR = pisco_data %>% 
  filter(MPA_Name == "Santa Barbara Island SMR")

ggplot(sb_SMR, aes(magnitude_homerange, month_pld, color = class)) +
  geom_jitter(size = 2.5) +
  theme_bw()

ggplot(sb_SMR) +
  #geom_point(aes(date, average_count, color = species)) +
  geom_line(aes(month_year, average_count, color = class, linetype = species)) +
  theme_bw() +
  guides(linetype = FALSE)

sb_sum = sb_SMR %>% 
  group_by(class, month_year) %>% 
  summarize(average_count = mean(average_count))

ggplot(sb_sum, aes(month_year, average_count)) +
  geom_point(aes(color = class), size = 2.5) +
  theme_bw()


# Point Dume SMCA ---------------------------------------------------------

dume_SMCA = pisco_data %>% 
  filter(MPA_Name == "Point Dume SMCA")

ggplot(dume_SMCA, aes(magnitude_homerange, month_pld, color = class)) +
  geom_jitter(size = 2.5) +
  theme_bw()

ggplot(dume_SMCA) +
  #geom_point(aes(date, average_count, color = species)) +
  geom_line(aes(month_year, average_count, color = class, linetype = species)) +
  theme_bw() +
  guides(linetype = FALSE)

dume_SMCA_sum = dume_SMCA %>% 
  group_by(class, month_year) %>% 
  summarize(average_count = mean(average_count))

ggplot(dume_SMCA_sum, aes(month_year, average_count)) +
  geom_point(aes(color = class), size = 2.5) +
  theme_bw()


# Point Dume SMR ---------------------------------------------------------

dume_SMR = pisco_data %>% 
  filter(MPA_Name == "Point Dume SMR")

ggplot(dume_SMR, aes(magnitude_homerange, month_pld, color = class)) +
  geom_jitter(size = 2.5) +
  theme_bw()

ggplot(dume_SMR) +
  #geom_point(aes(date, average_count, color = species)) +
  geom_line(aes(month_year, average_count, color = class, linetype = species)) +
  theme_bw() +
  guides(linetype = FALSE)

dume_SMR_sum = dume_SMR %>% 
  group_by(class, month_year) %>% 
  summarize(average_count = mean(average_count))

ggplot(dume_SMR_sum, aes(month_year, average_count)) +
  geom_point(aes(color = class), size = 2.5) +
  theme_bw()

# Point Conception --------------------------------------------------------
conception_SMR = pisco_data %>% 
  filter(MPA_Name == "Point Conception SMR")

ggplot(conception_SMR, aes(magnitude_homerange, month_pld, color = class)) +
  geom_jitter(size = 2.5) +
  theme_bw()

ggplot(conception_SMR) +
  #geom_point(aes(date, average_count, color = species)) +
  geom_line(aes(month_year, average_count, color = class, linetype = species)) +
  theme_bw() +
  guides(linetype = FALSE)

conception_SMR_sum = conception_SMR %>% 
  group_by(class, month_year) %>% 
  summarize(average_count = mean(average_count))

ggplot(conception_SMR_sum, aes(month_year, average_count)) +
  geom_point(aes(color = class), size = 2.5) +
  theme_bw()

# Painted Cave ------------------------------------------------------------

cave_SMCA = pisco_data %>% 
  filter(MPA_Name == "Painted Cave SMCA")

ggplot(cave_SMCA, aes(magnitude_homerange, month_pld, color = class)) +
  geom_jitter(size = 2.5) +
  theme_bw()

ggplot(cave_SMCA) +
  #geom_point(aes(date, average_count, color = species)) +
  geom_line(aes(month_year, average_count, color = class, linetype = species)) +
  theme_bw() +
  guides(linetype = FALSE)

cave_SMCA_sum = cave_SMCA %>% 
  group_by(class, month_year) %>% 
  summarize(average_count = mean(average_count))

ggplot(cave_SMCA_sum, aes(month_year, average_count)) +
  geom_point(aes(color = class), size = 2.5) +
  theme_bw()

# Naples SMCA -------------------------------------------------------------

naples_SMCA = pisco_data %>% 
  filter(MPA_Name == "Naples SMCA")

ggplot(naples_SMCA, aes(magnitude_homerange, month_pld, color = class)) +
  geom_jitter(size = 2.5) +
  theme_bw()

ggplot(naples_SMCA) +
  #geom_point(aes(date, average_count, color = species)) +
  geom_line(aes(month_year, average_count, color = class, linetype = species)) +
  theme_bw() +
  guides(linetype = FALSE)

naples_SMCA_sum = naples_SMCA %>% 
  group_by(class, month_year) %>% 
  summarize(average_count = mean(average_count))

ggplot(naples_SMCA_sum, aes(month_year, average_count)) +
  geom_point(aes(color = class), size = 2.5) +
  theme_bw()

# Carrington Point --------------------------------------------------------

carrington_SMR = pisco_data %>% 
  filter(MPA_Name == "Carrington Point SMR")

ggplot(carrington_SMR, aes(magnitude_homerange, month_pld, color = class)) +
  geom_jitter(size = 2.5) +
  theme_bw()

ggplot(carrington_SMR) +
  #geom_point(aes(date, average_count, color = species)) +
  geom_line(aes(month_year, average_count, color = class, linetype = species)) +
  theme_bw() +
  guides(linetype = FALSE)

carrington_SMR_sum = carrington_SMR %>% 
  group_by(class, month_year) %>% 
  summarize(average_count = mean(average_count))

ggplot(carrington_SMR_sum, aes(month_year, average_count)) +
  geom_point(aes(color = class), size = 2.5) +
  theme_bw()

# Campus Point SMCA -------------------------------------------------------
campus_SMCA = pisco_data %>% 
  filter(MPA_Name == "Campus Point SMCA")

ggplot(campus_SMCA, aes(magnitude_homerange, month_pld, color = class)) +
  geom_jitter(size = 2.5) +
  theme_bw()

ggplot(campus_SMCA) +
  #geom_point(aes(date, average_count, color = species)) +
  geom_line(aes(month_year, average_count, color = class, linetype = species)) +
  theme_bw() +
  guides(linetype = FALSE)

campus_SMCA_sum = campus_SMCA %>% 
  group_by(class, month_year) %>% 
  summarize(average_count = mean(average_count))

ggplot(campus_SMCA_sum, aes(month_year, average_count)) +
  geom_point(aes(color = class), size = 2.5) +
  theme_bw()


# Harris Point ------------------------------------------------------------


harris_point = pisco_data %>% 
  filter(MPA_Name == "Harris Point SMR")

ggplot(harris_point, aes(magnitude_homerange, month_pld, color = class)) +
  geom_jitter(size = 2.5) +
  theme_bw()

ggplot(harris_point) +
  #geom_point(aes(date, average_count, color = species)) +
  geom_line(aes(month_year, average_count, color = class, linetype = species)) +
  theme_bw() +
  guides(linetype = FALSE)

harris_point_sum = harris_point %>% 
  group_by(class, month_year) %>% 
  summarize(average_count = mean(average_count))

ggplot(harris_point_sum, aes(month_year, average_count)) +
  geom_point(aes(color = class), size = 2.5) +
  theme_bw()

# Anacapa Island SMR ------------------------------------------------------

anapaca_SMR = pisco_data %>% 
  filter(MPA_Name == "Anacapa Island SMR")

ggplot(anapaca_SMR, aes(magnitude_homerange, month_pld, color = class)) +
  geom_jitter(size = 2.5) +
  theme_bw()

ggplot(anapaca_SMR) +
  #geom_point(aes(date, average_count, color = species)) +
  geom_line(aes(month_year, average_count, color = class, linetype = species)) +
  theme_bw() +
  guides(linetype = FALSE)

anapaca_SMR_sum = anapaca_SMR %>% 
  group_by(class, month_year) %>% 
  summarize(average_count = mean(average_count))

ggplot(anapaca_SMR_sum, aes(month_year, average_count)) +
  geom_point(aes(color = class), size = 2.5) +
  theme_bw()


# Anacapa Island SMCA -----------------------------------------------------

anapaca_SMCA = pisco_data %>% 
  filter(MPA_Name == "Anacapa Island SMCA")

ggplot(anapaca_SMCA, aes(magnitude_homerange, month_pld, color = class)) +
  geom_jitter(size = 2.5) +
  theme_bw()

ggplot(anapaca_SMCA) +
  #geom_point(aes(date, average_count, color = species)) +
  geom_line(aes(month_year, average_count, color = class, linetype = species)) +
  theme_bw() +
  guides(linetype = FALSE)

anapaca_SMCA_sum = anapaca_SMCA %>% 
  group_by(class, month_year) %>% 
  summarize(average_count = mean(average_count))

ggplot(anapaca_SMCA_sum, aes(month_year, average_count)) +
  geom_point(aes(color = class), size = 2.5) +
  theme_bw()

# Granger Test Playground -------------------------------------------------

vand_ts = vand_SMR %>% 
  select(-count) %>% 
  distinct() %>% 
  ungroup() %>% 
  pivot_wider(names_from = species, values_from = average_count) %>%
  select(month_year, "Embiotoca jacksoni", "Hexagrammos decagrammus", "Embiotoca lateralis", "Sebastes auriculatus", "Sebastes carnatus", "Sebastes atrovirens","Sebastes caurinus") %>% 
  distinct() 

names(vand_ts) = c("month_year", "species1", "species2", "species3", "species4", "species5", "species6", "species7")

ggplot(vand_ts) +
  geom_line(aes(month_year, species1), color = "red") +
  # geom_line(aes(month_year, species2), color = "blue") +
  # geom_line(aes(month_year, species3)) +
  # geom_line(aes(month_year, species4), color = "green") +
  # geom_line(aes(month_year, species5), color = "purple") +
  # geom_line(aes(month_year, species6), color = "pink") +
  geom_line(aes(month_year, species7), color = "gold") +
  theme_bw()

grangertest(species1 ~ species2, order = 1, data = vand_ts)
grangertest(species1 ~ species3, order = 1, data = vand_ts)
grangertest(species1 ~ species5, order = 1, data = vand_ts)
grangertest(species1 ~ species6, order = 1, data = vand_ts)
grangertest(species1 ~ species7, order = 1, data = vand_ts)
