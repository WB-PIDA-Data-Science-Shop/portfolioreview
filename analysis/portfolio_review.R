# set-up -----------------------------------------------------------------
library(dplyr)
library(ggplot2)
library(stringr)
library(ggthemes)

theme_set(
  theme_minimal()
)

devtools::load_all()

# read-in data -----------------------------------------------------------
wb_projects_gov <- portfolioreview::wb_projects_gov

wb_lending_gov <- wb_projects_gov |> 
  filter(
    product_line_type == "Lending Product"
  )

wb_asa_gov <- wb_projects_gov |> 
  filter(
    product_line_type == "Analytic and Advisory Activities Product"
  )

# analyze ----------------------------------------------------------------
# distinct projects
wb_lending_gov |> 
  group_by(proj_approval_fy) |> 
  summarise(
    rate = n_distinct(proj_id)
  ) |> 
  ggplot(
    aes(proj_approval_fy, rate)
  ) +
  geom_point(
    size = 5,
    alpha = 0.7
  ) +
  geom_line(
    linewidth = 1.5,
    alpha = 0.7
  ) +
  labs(
    x = "Fiscal year of project approval",
    y = "Number of projects"
  )

ggsave(
  here::here("analysis", "figures", "lending_trends.png"),
  width = 8,
  height = 5,
  bg = "white"
)

# by region
wb_lending_gov |> 
  group_by(proj_approval_fy, region) |> 
  summarise(
    rate = n_distinct(proj_id)
  ) |> 
  ggplot(
    aes(proj_approval_fy, rate, color = region)
  ) +
  geom_point(
    size = 5,
    alpha = 0.7
  ) +
  geom_line(
    linewidth = 1.5,
    alpha = 0.7
  ) +
  scale_color_solarized() +
  labs(
    x = "Fiscal year of project approval",
    y = "Number of projects"
  ) +
  theme(
    legend.position = "bottom"
  )

ggsave(
  here::here("analysis", "figures", "lending_trends_by_region.png"),
  width = 8,
  height = 5,
  bg = "white"
)

# thematic breakdown
wb_lending_gov |> 
  group_by(proj_approval_fy) |> 
  summarise(
    rate_pfm = sum(theme_pfm),
    rate_procurement = sum(theme_procurement),
    rate_public_admin = sum(theme_public_admin),
    rate_environmental_social = sum(theme_env_social)
  ) |> 
  ungroup() |> 
  tidyr::pivot_longer(
    cols = starts_with("rate_"),
    names_to = "theme_category",
    values_to = "rate"
  ) |>
  mutate(
    theme_category = str_remove(theme_category, "rate_"),
    theme_category = recode_values(
      theme_category,
      "pfm"                  ~ "Public Financial Management",
      "procurement"          ~ "Public Procurement",
      "public_admin"         ~ "Public Administration",
      "environmental_social" ~ "Environmental & Social"
    )
  ) |> 
  ggplot(
    aes(proj_approval_fy, rate, color = theme_category)
  ) +
  geom_point(
    size = 5,
    alpha = 0.7
  ) +
  geom_line(
    linewidth = 1.5,
    alpha = 0.7
  ) +
  scale_color_solarized() +
  labs(
    x = "Fiscal year of project approval",
    y = "Number of projects"
  ) +
  theme(
    legend.position = "bottom"
  )

ggsave(
  here::here("analysis", "figures", "lending_theme_trends.png"),
  width = 8,
  height = 5,
  bg = "white"
)

wb_lending_gov |> 
  group_by(proj_approval_fy, region) |> 
  summarise(
    rate_pfm = sum(theme_pfm),
    rate_procurement = sum(theme_procurement),
    rate_public_admin = sum(theme_public_admin),
    rate_environmental_social = sum(theme_env_social)
  ) |> 
  ungroup() |> 
  tidyr::pivot_longer(
    cols = starts_with("rate_"),
    names_to = "theme_category",
    values_to = "rate"
  ) |>
  mutate(
    theme_category = str_remove(theme_category, "rate_"),
    theme_category = case_match(
      theme_category,
      "pfm"                  ~ "Public Financial Management",
      "procurement"          ~ "Public Procurement",
      "public_admin"         ~ "Public Administration",
      "environmental_social" ~ "Environmental & Social"
    )
  ) |> 
  ggplot(
    aes(proj_approval_fy, rate, color = theme_category)
  ) +
  geom_point(
    size = 5,
    alpha = 0.7
  ) +
  geom_line(
    linewidth = 1.5,
    alpha = 0.7
  ) +
  scale_color_solarized() +
  facet_wrap(
    vars(region),
    ncol = 2
  ) +
  labs(
    x = "Fiscal year of project approval",
    y = "Number of projects"
  )
  theme(
    legend.position = "bottom"
  )

ggsave(
  here::here("analysis", "figures", "lending_theme_trends_by_region.png"),
  width = 8,
  height = 5,
  bg = "white"
)

# projects by thematic area in FY2026
wb_lending_gov |> 
  filter(proj_approval_fy == 2026) |> 
  summarise(
    rate_pfm = sum(theme_pfm),
    rate_procurement = sum(theme_procurement),
    rate_public_admin = sum(theme_public_admin),
    rate_environmental_social = sum(theme_env_social)
  ) |> 
  tidyr::pivot_longer(
    cols = starts_with("rate_"),
    names_to = "theme_category",
    values_to = "rate"
  ) |>
  mutate(
    theme_category = str_remove(theme_category, "rate_"),
    theme_category = case_match(
      theme_category,
      "pfm"                  ~ "Public Financial Management",
      "procurement"          ~ "Public Procurement",
      "public_admin"         ~ "Public Administration",
      "environmental_social" ~ "Environmental & Social"
    )
  ) |> 
  ggplot() +
  geom_col(
    aes(theme_category, rate, fill = theme_category),
    alpha = 0.7
  ) +
  scale_fill_solarized() +
  theme(legend.position = "bottom")

ggsave(
  here::here("analysis", "figures", "lending_theme_breakdown_2026.png"),
  width = 8,
  height = 5,
  bg = "white"
)

# by region
wb_lending_gov |> 
  filter(proj_approval_fy == 2026) |> 
  summarise(
    rate_pfm = sum(theme_pfm),
    rate_procurement = sum(theme_procurement),
    rate_public_admin = sum(theme_public_admin),
    rate_environmental_social = sum(theme_env_social),
    .by = region
  ) |> 
  tidyr::pivot_longer(
    cols = starts_with("rate_"),
    names_to = "theme_category",
    values_to = "rate"
  ) |>
  mutate(
    theme_category = str_remove(theme_category, "rate_"),
    theme_category = case_match(
      theme_category,
      "pfm"                  ~ "Public Financial Management",
      "procurement"          ~ "Public Procurement",
      "public_admin"         ~ "Public Administration",
      "environmental_social" ~ "Environmental & Social"
    )
  ) |> 
  ggplot() +
  geom_col(
    aes(theme_category, rate, fill = theme_category),
    alpha = 0.7
  ) +
  scale_fill_solarized() +
  facet_wrap(vars(region), ncol = 2) +
  theme(legend.position = "bottom")

ggsave(
  here::here("analysis", "figures", "lending_theme_breakdown_2026_by_region.png"),
  width = 8,
  height = 5,
  bg = "white"
)
