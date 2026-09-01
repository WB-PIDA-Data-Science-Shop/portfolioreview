# set-up -----------------------------------------------------------------
library(dplyr)
library(ggplot2)
library(stringr)
library(ggthemes)
library(tidyr)

theme_set(
  theme_minimal(
    base_size = 14
  )
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

wb_country_ida <- portfolioreview::wb_country_list |>
  distinct(country_code, country_name) |>
  left_join(
    portfolioreview::wb_income_and_region |>
      select(country_code, lending_category),
    by = "country_code"
  ) |>
  filter(
    lending_category %in% c("IDA", "Blend")
  ) |>
  select(country_code, lending_category)

cpia_raw <- readr::read_csv(
  here::here("data-raw", "input", "data360", "WB_CPIA_WIDEF.csv")
) 

cpia <- cpia_raw|>
  filter(
    COMP_BREAKDOWN_1_LABEL %in% c(
      "Quality of Budgetary and Financial Management",
      "Quality of Public Administration",
      "Policies and Institutions for Environmental Sustainability",
      "Transparency, Accountability, and Corruption in the Public Sector"
    ),
    OBS_STATUS != "O"
  ) |>
  select(
    country_code = REF_AREA,
    indicator = COMP_BREAKDOWN_1_LABEL,
    `2005`:`2024`
  ) |>
  pivot_longer(
    cols = `2005`:`2024`,
    names_to = "year",
    values_to = "value"
  )

# export tables ----------------------------------------------------------
wb_projects_gov |> 
  count(proj_approval_fy, product_line_type) |>
  pivot_wider(
    names_from = product_line_type,
    values_from = n,
    values_fill = 0
  )

# analyze ----------------------------------------------------------------
# number of projects per country
wb_lending_gov |> 
  group_by(country_name) |> 
  summarise(
    rate = n_distinct(proj_id)
  ) |> 
  arrange(desc(rate)) |> 
  ggplot(
    aes(rate, reorder(country_name, rate))
  ) +
  geom_col(
    fill = "steelblue",
    alpha = 0.7
  )

ggsave(
  here::here("analysis", "figures", "lending_by_country.png"),
  width = 8,
  height = 12,
  bg = "white"
)

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
  facet_wrap(
    vars(theme_category)
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

# country count ----------------------------------------------------------
# number of countries with projects, divided by lending and ASA
# with two facets: proj_approval_fy == 2026 vs. all years
wb_projects_gov |> 
  mutate(
    product_line_type = case_match(
      product_line_type,
      "Lending Product" ~ "Lending",
      "Analytic and Advisory Activities Product" ~ "ASA"
    ),
    ida_cycle = if_else(
      proj_approval_fy >= 2026,
      "IDA21",
      "Before-IDA21"
    )
  ) |> 
  group_by(ida_cycle, product_line_type) |> 
  summarise(
    n_countries = n_distinct(country_name)
  ) |> 
  ggplot(
    aes(product_line_type, n_countries, fill = product_line_type)
  ) +
  geom_col(
    alpha = 0.7
  ) +
  # add number of projects as text labels
  geom_text(
    aes(label = n_countries),
    vjust = -0.5,
    size = 5
  ) +
  labs(
    x = "Product line",
    y = "Number of countries with projects"
  ) +
  scale_fill_solarized() +
  facet_wrap(
    vars(ida_cycle),
    ncol = 2
  ) +
  theme(
    legend.position = "none"
  )

ggsave(
  here::here("analysis", "figures", "country_count_by_cycle.png"),
  width = 8,
  height = 6,
  bg = "white"
)

# by theme
wb_projects_gov |> 
  mutate(
    product_line_type = case_match(
      product_line_type,
      "Lending Product" ~ "Lending",
      "Analytic and Advisory Activities Product" ~ "ASA"
    ),
    ida_cycle = if_else(
      proj_approval_fy >= 2026,
      "IDA21",
      "Before-IDA21"
    )
  ) |> 
  tidyr::pivot_longer(
    cols = c(theme_pfm, theme_procurement, theme_public_admin, theme_env_social),
    names_to = "theme",
    values_to = "has_theme",
    names_prefix = "theme_"
  ) |> 
  # relabel themes
  mutate(
    theme = case_match(
      theme,
      "pfm"                  ~ "Public Financial Management",
      "procurement"          ~ "Public Procurement",
      "public_admin"         ~ "Public Administration",
      "env_social"          ~ "Environmental and Social"
    )
  ) |>
  filter(has_theme == 1) |>
  group_by(ida_cycle, theme) |> 
  summarise(
    n_countries = n_distinct(country_name)
  ) |> 
  ggplot(
    aes(theme, n_countries, fill = theme)
  ) +
  geom_col(
    alpha = 0.7
  ) +
  # add number of projects as text labels
  geom_text(
    aes(label = n_countries),
    vjust = -0.5,
    size = 5
  ) +
  # tilt x-axis labels for readability
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    legend.position = "none"
  ) +
  scale_fill_solarized() +
  facet_wrap(
    vars(ida_cycle),
    ncol = 2
  ) +
  labs(
    x = "Thematic area",
    y = "Number of countries with projects"
  )

ggsave(
  here::here("analysis", "figures", "country_count_by_theme_cycle.png"),
  width = 8,
  height = 7,
  bg = "white"
)

# cumulative number of projects by thematic area
wb_projects_gov |>
  pivot_longer(
    cols = starts_with("theme_"),
    names_to = "theme",
    values_to = "counter"
  ) |>
  mutate(
    approval_fy = coalesce(
      proj_approval_fy, lubridate::year(asa_approval_date)
    )
  ) |>
  filter(
    approval_fy >= 2020
  ) |>
  summarise(
    counter = sum(counter),
    .by = c("theme", "approval_fy")
  ) |>
  arrange(
    theme, approval_fy
  ) |>
  mutate(
    cumulative_projects = cumsum(counter),
    .by = c("theme")
  ) |>
  mutate(
    theme_category = str_remove(theme, "theme_"),
    theme_category = case_match(
      theme_category,
      "pfm"                  ~ "Public Financial Management",
      "procurement"          ~ "Public Procurement",
      "public_admin"         ~ "Public Administration",
      "env_social" ~ "Environmental & Social"
    )
  ) |> 
  ggplot(
    aes(approval_fy, cumulative_projects, color = theme_category)
  ) +
  geom_point(
    size = 4
  ) +
  geom_line(
    linewidth = 1.5
  ) +
  scale_color_tableau(
     name = "Institutional Dimension",
     labels = function(x) str_wrap(x, width = 35)
  ) +
  scale_x_continuous(
    breaks = seq(2010, 2025, by = 1)
  ) +
  guides(
    color = guide_legend(nrow = 2, byrow = TRUE)
  ) +
  theme_bw(
    base_size = 14
  ) +
  theme(
    legend.position = "bottom",
    panel.grid.minor = element_blank(),
    strip.text = element_text(size = 12, face = "bold")
  ) +
  labs(
    x = "Project Approval Year",
    y = "Cumulative Number of Projects"
  )

ggsave(
  here::here("analysis", "figures", "cumulative_projects_by_theme.png"),
  width = 10,
  height = 8,
  bg = "white"
)

# cpia -------------------------------------------------------------------
# CPIA
gov_ida <- wb_projects_gov |> 
  distinct(country_code) |>
  mutate(
    pc10_supported = "Yes"
  )

cpia_ida <- cpia |>
  inner_join(
    wb_country_ida,
    by = c("country_code" = "country_code")
  ) |>
  left_join(
    gov_ida,
    by = c("country_code")
  ) |>
  replace_na(
    list(pc10_supported = "No")
  ) |>
  mutate(
    indicator = factor(
      indicator,
      levels = c(
        "Quality of Budgetary and Financial Management",
        "Quality of Public Administration",
        "Transparency, Accountability, and Corruption in the Public Sector",
        "Policies and Institutions for Environmental Sustainability"
      )
    ),
    pc10_supported = factor(
      pc10_supported,
      levels = c("Yes", "No")
    )
  )

cpia_ida |>
  summarise(
    value = mean(value, na.rm = TRUE),
    .by = c(year, indicator)
  ) |>
  mutate(
    year = as.integer(year)
  ) |>
  filter(
    year >= 2020
  ) |>
  ggplot(
    aes(year, value, color = indicator)
  ) +
  geom_point(
    size = 4,
    show.legend = FALSE
  ) +
  ggrepel::geom_text_repel(
    data = . %>% filter(year %in% c(2020, 2024)),
    aes(
      label = round(value, 2)
    ),
    vjust = -0.5,
    size = 5,
    show.legend = FALSE
  ) +
  geom_line(
    linewidth = 1.5,
    key_glyph = draw_key_rect
  )  +
  labs(
    x = "Year",
    y = "CPIA Score"
  ) +
  scale_color_tableau(
     name = "Institutional Dimension",
     labels = function(x) str_wrap(x, width = 35)
  ) +
  scale_x_continuous(
    breaks = seq(2010, 2025, by = 1)
  ) +
  guides(
    color = guide_legend(nrow = 2, byrow = TRUE)
  ) +
  # facet_wrap(
  #   vars(indicator),
  #   labeller = labeller(indicator = label_wrap_gen(width = 35))
  # ) +
  theme_bw(
    base_size = 14
  ) +
  theme(
    legend.position = "bottom",
    panel.grid.minor = element_blank(),
    strip.text = element_text(size = 12, face = "bold")
  )

ggsave(
  here::here("analysis", "figures", "cpia_score_by_year.png"),
  width = 10,
  height = 8,
  bg = "white"
)
