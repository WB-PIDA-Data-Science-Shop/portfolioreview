# set-up -----------------------------------------------------------------
library(dplyr)
library(ggplot2)

theme_set(
  theme_minimal()
)

# read-in data -----------------------------------------------------------
wb_documents <- portfolioreview::wb_documents |> 
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

wb_projects <- portfolioreview::wb_projects |> 
  left_join(
    wb_documents,
    by = c("proj_id")
  ) |> 
  left_join(
    wb_project_components,
    by = c("proj_id")
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
    count = sum(!is.na(pad_available)),
    rate = mean(!is.na(pad_available))
  ) |> 
  ungroup() |> 
  ggplot(
    aes(proj_approval_fy, rate, color = lending_instrument)
  ) +
  geom_point() +
  geom_line()

# 67.4 percent of projects have missing components
wb_projects |> 
  filter(
    proj_status == "Active" 
  ) |> 
  summarise(
    mean(is.na(project_component_available)),
  )
