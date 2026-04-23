# set-up -----------------------------------------------------------------
library(dplyr)
library(ggplot2)

theme_set(
  theme_minimal()
)

# read-in data -----------------------------------------------------------
# investigate why projects have more than a PAD
wb_documents <- portfolioreview::wb_documents |> 
  distinct(proj_id, .keep_all = TRUE) |>
  transmute(
    proj_id,
    doc_month,
    owner_label,
    pad_available = 1
  )

wb_project_components <- portfolioreview::wb_project_components |> 
  distinct(proj_id) |>
  mutate(
    project_component_available = 1
  )

wb_country_ida <- portfolioreview::wb_country_list |> 
  distinct(country_code, country_name) |> 
  left_join(
    portfolioreview::wb_income_and_region |> select(country_code, lending_category),
    by = "country_code"
  ) |> 
  filter(
    lending_category %in% c("IDA", "Blend")
  ) |> 
  select(country_code, lending_category)

# note: 72.2 percent of lending projects have components available
wb_projects <- portfolioreview::wb_projects |> 
  # only count active projects
  filter(
    proj_status == "Active"
  ) |> 
  left_join(
    wb_documents,
    by = c("proj_id")
  ) |> 
  left_join(
    wb_project_components,
    by = c("proj_id")
  ) |>
  # subset to IDA countries
  # worried about regional projects that include multiple countries, some of which are IDA
  inner_join(
    wb_country_ida,
    by = c("country_code")
  ) |>
  mutate(
    pad_available = if_else(is.na(pad_available), 0, pad_available),
    project_component_available = if_else(
      is.na(project_component_available), 0, project_component_available
    )
  )

# analyze ----------------------------------------------------------------
# first stylized fact: PADs are missing for multiple active GOV operations,
# especially in IPF
wb_projects |> 
  filter(
    product_line_type == "Lending Product" &
      lending_instrument %in% c("IPF", "PforR") &
      proj_status == "Active" &
      proj_approval_fy > 0
  ) |>
  group_by(lending_instrument, proj_approval_fy) |>
  summarise(
    count = sum(pad_available),
    rate = mean(pad_available)
  ) |> 
  ungroup() |> 
  ggplot(
    aes(proj_approval_fy, rate, color = lending_instrument)
  ) +
  geom_point() +
  geom_line()

# the ones that are missing project components are the PForR
wb_projects |> 
  group_by(lending_instrument) |> 
  summarise(
    mean(project_component_available == 1)
  )
