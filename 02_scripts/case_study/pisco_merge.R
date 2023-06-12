library(tidyverse)
library(lme4)
library(lmtest)
library(emmeans)
library(effects)

# Data Loading ------------------------------------------------------------


pisco_hr <- read_csv(here::here("01_data", "02_processed_data", "pisco_rf_hr_predict.csv")) %>%
  select(observed_homerange, predicted_homerange, species)
pisco_pld <- read_csv(here::here("01_data", "02_processed_data", "pisco_rf_pld_predict.csv")) %>%
  select(observed_PLD, predicted_PLD, species) %>%
  mutate(predicted_PLD = case_when(
    species %in% c("Prionace glauca", "Alopias vulpinus") ~ 0,
    TRUE ~ predicted_PLD
  ))
pisco <- read_csv(here::here("01_data", "01_raw_data", "PISCO_kelpforest_fish.1.3.csv"))
pisco_site <- read_csv(here::here("01_data", "01_raw_data", "PISCO_kelpforest_site_table.1.2.csv"))
pisco_taxa <- read_csv(here::here("01_data", "01_raw_data", "PISCO_kelpforest_taxon_table.1.2.csv"))


# Data Manipulation -------------------------------------------------------

pisco <- list(pisco, pisco_site, pisco_taxa) %>%
  reduce(full_join) %>%
  rename(species = species_definition)

pisco_rf <- full_join(pisco_hr, pisco_pld, relationship = "many-to-many") %>%
  group_by(species) %>%
  reframe(
    predicted_homerange = mean(predicted_homerange, na.rm = TRUE),
    predicted_PLD = mean(predicted_PLD, na.rm = TRUE),
    observed_homerange = observed_homerange,
    observed_PLD = observed_PLD
  ) %>%
  mutate(home_range = case_when(
    !is.na(observed_homerange) ~ observed_homerange,
    is.na(observed_homerange) ~ predicted_homerange
  )) %>%
  rename(pld = predicted_PLD) %>%
  filter(pld < 400) %>%
  mutate(magnitude_homerange = floor(log10(home_range))) %>%
  mutate(month_pld = ceiling(pld / 30)) %>%
  mutate(class = case_when(
    month_pld <= 1 & magnitude_homerange < 2 ~ 1,
    magnitude_homerange < -1 & month_pld == 2 ~ 2,
    month_pld == 3 ~ 3,
    month_pld > 3 ~ 4,
    magnitude_homerange %in% c(-1, 0, 1) & month_pld == 2 ~ 5,
    magnitude_homerange >= 2 ~ 6
  )) %>%
  select(species, class, magnitude_homerange, month_pld) %>%
  mutate(class = as.factor(class)) %>%
  distinct() %>%
  mutate(class2 = class) %>%
  select(-class) %>%
  mutate(class = case_when(
    class2 == 1 ~ "1: mid/low",
    class2 == 2 ~ "2: low/mid",
    class2 == 3 ~ "3: mid/high",
    class2 == 4 ~ "4: mid/veryhigh",
    class2 == 5 ~ "5: mid/mid",
    class2 == 6 ~ "6: high/mid"
  ))


sebastes_1 <- c("Sebastes atrovirens/carnatus/chrysomelas/caurinus", -2, 2, 2, "2: low/mid")
sebastes_2 <- c("Sebastes carnatus/caurinus", -2, 2, 2, "2: low/mid")
sebastes_3 <- c("Sebastes chrysomelas/carnatus", -2, 2, 2, "2: low/mid")

pisco_rf <- rbind(pisco_rf, sebastes_1)
pisco_rf <- rbind(pisco_rf, sebastes_2)
pisco_rf <- rbind(pisco_rf, sebastes_3)

pisco <- full_join(pisco, pisco_rf, multiple = "all") %>%
  filter(!is.na(count)) %>%
  filter(!is.na(species)) %>%
  mutate(magnitude_homerange = as.numeric(magnitude_homerange))

pisco_species <- pisco %>%
  select(species, magnitude_homerange, month_pld, class) %>%
  distinct() %>%
  na.omit()

species_list <- pisco_species %>%
  pull(species)

pisco$date <- as.Date(with(pisco, paste(year, month, day, sep = "-")), "%Y-%m-%d")

pisco <- pisco %>%
  filter(species %in% species_list) %>%
  filter(site_status == "MPA")

pisco <- full_join(pisco, pisco_species)

pisco_sum <- pisco %>%
  mutate(
    month = month(date),
    year = year(date),
    month_year = year * 100 + month
  ) %>%
  group_by(MPA_Name, species, month_year, class) %>%
  reframe(
    average_count = mean(count),
    magnitude_homerange = magnitude_homerange,
    month_pld = month_pld
  )


pisco_count <- pisco_sum %>%
  group_by(MPA_Name, species, class) %>%
  summarize(count = n())

pisco_data <- full_join(pisco_count, pisco_sum, multiple = "all")

pisco_class <- pisco_data %>%
  ungroup() %>%
  select(species, class, magnitude_homerange, month_pld) %>%
  distinct()

full_sum <- pisco_sum %>%
  group_by(class, month_year, MPA_Name) %>%
  summarize(average_count = mean(average_count)) %>%
  filter(average_count < 1000)


# Full Plots --------------------------------------------------------------

f1 <- ggplot(pisco_class, aes(magnitude_homerange, month_pld, color = class)) +
  geom_jitter(size = 2.5) +
  theme_bw() +
  labs(
    x = "Order of Magnitude of Home Range",
    y = "Pelgaic Larval Duration Month",
    color = "Class (homerange/PLD)"
  )
f1

# ggsave(f1, file = paste0("pisco_class.png"), path = here::here("04_figs", "chanel_islands"))

ggplot(pisco_data %>% filter(count > 5)) +
  # geom_point(aes(month_year, average_count, color = class)) +
  geom_line(aes(month_year, average_count, color = class, linetype = species)) +
  facet_wrap(~MPA_Name, scales = "free") +
  theme_bw() +
  guides(linetype = "none") +
  scale_color_viridis_d()

pisco_data_sub <- pisco_data %>%
  filter(MPA_Name %in% c("Anacapa Island SMR", "Campus Point SMCA", "Edward Ricketts SMCA", "Naples SMCA", "Point Dume SMR", "Scorpion SMR", "Santa Barbara Island SMR", "South Point SMR"))

f3 <- ggplot(pisco_data_sub %>% filter(count > 5)) +
  # geom_point(aes(month_year, average_count, color = class)) +
  geom_line(aes(month_year, average_count, color = class, linetype = species)) +
  facet_wrap(~MPA_Name, scales = "free", nrow = 2) +
  theme_bw() +
  guides(linetype = FALSE) +
  labs(
    color = "Class (homerange/PLD)",
    x = "Time",
    y = "Average Count"
  ) +
  scale_color_viridis_d()
f3

# ggsave(f3, file = paste0("species_ts.png"), path = here::here("04_figs", "chanel_islands"), height = 10, width = 15)

ggplot(full_sum, aes(month_year, log(average_count))) +
  geom_point(aes(color = class), size = 2.5) +
  facet_wrap(~MPA_Name, scales = "free") +
  geom_smooth(method = "lm", aes(color = class), se = FALSE) +
  theme_bw()
# geom_smooth(method = "lm", aes(color = class), se = FALSE)

full_sum_sub <- full_sum %>%
  filter(MPA_Name %in% c("Anacapa Island SMR", "Campus Point SMCA", "Edward Ricketts SMCA", "Naples SMCA", "Point Dume SMR", "Scorpion SMR", "Santa Barbara Island SMR", "South Point SMR"))

f2 <- ggplot(full_sum_sub, aes(month_year, log(average_count))) +
  geom_point(aes(color = class), size = 2.5) +
  facet_wrap(~MPA_Name, scales = "free", nrow = 2) +
  theme_bw(base_size = 20) +
  geom_smooth(method = "lm", aes(color = class), se = FALSE) +
  theme(
    strip.text = element_text(face = "bold"),
    strip.background = element_rect(fill = "white"),
    axis.text.x = element_text(angle = 60, hjust = 1)
  ) +
  labs(x = "Time", y = "Log of Average Count", color = "Class (homerange/PLD)") +
  scale_color_viridis_d()
f2

# ggsave(f2, file = paste0("class_sum.png"), path = here::here("04_figs", "chanel_islands"), height = 10, width = 15)

# Vandenberg --------------------------------------------------------------

vand_SMR <- pisco_data %>%
  filter(MPA_Name == "Vandenberg SMR")

ggplot(vand_SMR, aes(magnitude_homerange, month_pld, color = class)) +
  geom_jitter(size = 2.5) +
  theme_bw()

ggplot(vand_SMR) +
  # geom_point(aes(date, average_c count, color = species)) +
  geom_line(aes(month_year, average_count, color = class, linetype = species)) +
  theme_bw() +
  guides(linetype = FALSE)

vand_sum <- vand_SMR %>%
  group_by(class, month_year) %>%
  summarize(average_count = mean(average_count))

# Granger Test Playground -------------------------------------------------

vand_ts <- vand_SMR %>%
  select(-count) %>%
  distinct() %>%
  ungroup() %>%
  pivot_wider(names_from = species, values_from = average_count) %>%
  select(month_year, "Embiotoca jacksoni", "Hexagrammos decagrammus", "Embiotoca lateralis", "Sebastes auriculatus", "Sebastes carnatus", "Sebastes atrovirens", "Sebastes caurinus") %>%
  distinct()

names(vand_ts) <- c("month_year", "species1", "species2", "species3", "species4", "species5", "species6", "species7")

ggplot(vand_ts) +
  geom_line(aes(month_year, species1), color = "red") +
  # geom_line(aes(month_year, species2), color = "blue") +
  # geom_line(aes(month_year, species3)) +
  # geom_line(aes(month_year, species4), color = "green") +
  geom_line(aes(month_year, species5), color = "purple") +
  geom_line(aes(month_year, species6), color = "pink") +
  geom_line(aes(month_year, species7), color = "gold") +
  theme_bw()

grangertest(species1 ~ species2, order = 1, data = vand_ts)
grangertest(species1 ~ species3, order = 1, data = vand_ts)
grangertest(species1 ~ species4, order = 1, data = vand_ts)
grangertest(species1 ~ species5, order = 1, data = vand_ts)
grangertest(species1 ~ species6, order = 1, data = vand_ts)
grangertest(species1 ~ species7, order = 1, data = vand_ts)


# Mixed Effects Model Playground ------------------------------------------

full_sum = pisco_sum %>% 
  mutate(average_count = round(average_count,0))

lm1 <- glm(average_count ~ class, data = full_sum, family = quasipoisson())
summary(lm1)
anova(lm1, test = "Chi")

emmeans(lm1, pairwise ~ class)

emmeans(lm1, eff ~ class) %>%
  pluck("contrasts")
emmeans(lm1, del.eff ~ class) %>%
  pluck("contrasts")

sjPlot::plot_model(lm1, show.values = TRUE, show.p = TRUE, ci_method = "wald")

effects <- effect(term = "class", mod = lm1)
summary(effects)
effects_df <- effects %>%
  as.data.frame()

ggplot() +
  geom_point(data = full_sum, aes(class, average_count)) +
  geom_point(data = effects_df, aes(x = class, y = fit), color = "blue") +
  geom_line(data = effects_df, aes(x = class, y = fit), group = 1, color = "blue") +
  geom_ribbon(data = effects_df, aes(x = class, ymin = lower, ymax = upper), alpha = 0.3, fill = "blue") +
  theme_bw()


lmer1 <- glmer(average_count ~ class + (1|MPA_Name), data = full_sum, family = poisson())
summary(lmer1)
deviance(lmer1)

lmer2 <- glmer(average_count ~ class + (1|species), data = full_sum, family = poisson())
summary(lmer2)
deviance(lmer2)

lmer3 <- glmer(average_count ~ class + (1|MPA_Name) + (1|species), data = full_sum, family = poisson())
summary(lmer3)
deviance(lmer3)

anova(lmer1, lmer2, lmer3, test = "Chi")

emmeans(lmer3, pairwise ~ class)

emmeans(lmer3, eff ~ class) %>%
  pluck("contrasts")
emmeans(lmer3, del.eff ~ class) %>%
  pluck("contrasts")

sjPlot::plot_model(lmer3, show.values = TRUE, show.p = TRUE, ci_method = "wald")

effects <- effect(term = "class", mod = lmer3)
summary(effects)
effects_df <- effects %>%
  as.data.frame()

ggplot() +
  geom_point(data = full_sum, aes(class, average_count)) +
  geom_point(data = effects_df, aes(x = class, y = fit), color = "blue") +
  geom_line(data = effects_df, aes(x = class, y = fit), group = 1, color = "blue") +
  geom_ribbon(data = effects_df, aes(x = class, ymin = lower, ymax = upper), alpha = 0.3, fill = "blue") +
  theme_bw()
