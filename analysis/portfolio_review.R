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

wb_project_indicators <- portfolioreview::wb_project_indicators |> 
  distinct(proj_id) |>
  mutate(
    project_indicator_available = 1
  )

wb_project_themes <- portfolioreview::wb_project_themes |> 
  distinct(proj_id) |>
  mutate(
    project_theme_available = 1
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
wb_projects_ida <- portfolioreview::wb_projects |> 
  # only count active projects
  filter(
    proj_status == "Active"
  ) |> 
  # subset to IDA countries
  # worried about regional projects that include multiple countries, some of which are IDA
  inner_join(
    wb_country_ida,
    by = c("country_code")
  )

# check coverage
portfolioreview::wb_projects |> 
  filter(
    proj_status == "Active"
  ) |> 
  left_join(
    wb_project_components |> select(proj_id, project_component_available),
    by = "proj_id"
  ) |>
  left_join(
    wb_project_indicators |> select(proj_id, project_indicator_available),
    by = "proj_id"
  ) |> 
  left_join(
    wb_project_themes |> select(proj_id, project_theme_available),
    by = "proj_id"
  ) |> 
  group_by(lending_instrument) |> 
  summarise(
    rate_indicator = mean(proj_id %in% wb_project_indicators$proj_id),
    rate_theme = mean(proj_id %in% wb_project_themes$proj_id)
  )

# classify projects based on themes --------------------------------------
gov_pc_themes <- portfolioreview::wb_project_themes |> 
  mutate(
    across(
      c(theme_name, parent_theme_name),
      \(string) str_remove(string, "FY17 - ")
    )
  ) |> 
  distinct(theme_name) |> 
  # classify topics with theme level 3
  filter(
    theme_name %in% c(
      # Public Finance Management
      "Public Expenditure Management",
      "Debt Management",
      "Domestic Revenue Administration",
      "Budget and Treasury Management",
      "Public Assets and Investment Management",
      "Government Financial Reporting and Balance Sheets",
      "Oversight, Accountability, and Supreme Audit Institutions",
      # Public Procurement
      "Procurement",
      # Public Administration
      "Administrative and Civil Service Reform",
      "Govtech",
      "E-Government, incl. e-services",
      "Transparency, Accountability and Good Governance",
      # Institutional dimensions of social and environmental aspects
      "Adaptation",
      "Mitigation",
      "Disaster Risk Management Governance",
      "Citizen Engagement and Social Accountability Policy, Programs, and Capacity Building",
      "Community and Local Infrastructure and Service Delivery",
      "Community Livelihoods and Local Economic Development",
      "Community and Local Governance"
    )
  ) |> 
  # classify topics into broader categories
  mutate(
    theme_category = case_when(
      theme_name %in% c(
        "Public Expenditure Management",
        "Debt Management",
        "Domestic Revenue Administration",
        "Budget and Treasury Management",
        "Public Assets and Investment Management",
        "Government Financial Reporting and Balance Sheets",
        "Oversight, Accountability, and Supreme Audit Institutions"
      ) ~ "Public Finance Management",

      theme_name == "Procurement" ~ "Public Procurement",
      
      theme_name %in% c(
        "Administrative and Civil Service Reform",
        "Govtech",
        "E-Government, incl. e-services",
        "Transparency, Accountability and Good Governance"
      ) ~ "Public Administration",
      
      theme_name %in% c(
        "Adaptation",
        "Mitigation",
        "Disaster Risk Management Governance",
        "Citizen Engagement and Social Accountability Policy, Programs, and Capacity Building",
        "Community and Local Infrastructure and Service Delivery",
        "Community Livelihoods and Local Economic Development",
        "Community and Local Governance"
      ) ~ "Institutional dimensions of social and environmental aspects",
      
      TRUE ~ NA_character_
    )
  )


wb_project_with_themes <- portfolioreview::wb_projects |> 
  left_join(
    portfolioreview::wb_project_themes |> 
      group_by(proj_id) |> 
      summarise(
        theme_name = paste(theme_name, collapse = ";")
      ),
    by = "proj_id"
  )

wb_project_with_themes |> 
  group_by(proj_id)

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
    count_pad = sum(pad_available),
    rate_pad = mean(pad_available)
  ) |> 
  ungroup() |> 
  ggplot(
    aes(proj_approval_fy, rate_pad, color = lending_instrument)
  ) +
  geom_point() +
  geom_line()

# the ones that are missing project components are the PForR
wb_projects |> 
  filter(
    lending_instrument %in% c("IPF", "PforR") &
      proj_status == "Active" &
      proj_approval_fy > 0
  ) |> 
  group_by(lending_instrument, proj_approval_fy) |> 
  summarise(
    rate_component = mean(project_component_available == 1),
    rate_indicator = mean(project_indicator_available == 1)
  ) |> 
  ungroup() |> 
  ggplot(
    aes(proj_approval_fy, rate_indicator, color = lending_instrument)
  ) +
  geom_point() +
  geom_line()

categories <- list(
  PFM = c(
    "public finance", "pfm", "budget", "budgeting",
    "fiscal", "fiscal management", "fiscal sustainability",
    "treasury", "treasury single account", "tsa",
    "expenditure", "public expenditure",
    "tax", "taxation", "tax administration", "domestic revenue",
    "revenue mobilization", "revenue administration",
    "customs",
    "public investment management", "\\bpim\\b",
    "procurement", "public procurement", "e-procurement",
    "debt management", "public debt",
    "financial management information system", "\\bfmis\\b",
    "integrated financial management", "\\bifmis\\b",
    "medium-term expenditure", "mtef"
  ),
  
  HRM = c(
    "civil service", "civil servant",
    "public service reform",
    "government workforce",
    "human resource management", "\\bhrm\\b",
    "human resource information system", "\\bhrmis\\b",
    "payroll", "pay and grading",
    "wage bill",
    "personnel management",
    "staff management",
    "merit[- ]based",
    "performance management",
    "public employment"
  ),
  
  GovTech = c(
    "govtech",
    "digital government",
    "e-?government", "egovernment",
    "digital public", "digital transformation",
    "government platform",
    "digital platform",
    "interoperability",
    "information system",
    "management information system", "\\bmis\\b",
    "\\bict\\b",
    "digital id", "digital identity",
    "id system",
    "open data",
    "data governance",
    "data exchange",
    "digital service",
    "online service",
    "administrative digitization",
    "core government system"
  ),
  
  Anticorruption = c(
    "anti[- ]corruption",
    "corruption",
    "integrity",
    "transparency",
    "accountability",
    "asset declaration",
    "beneficial ownership",
    "financial disclosure",
    "aml", "anti[- ]money laundering",
    "cft",
    "money laundering",
    "illicit financial",
    "fraud prevention",
    "anticorruption commission",
    "oversight institution"
  ),
  
  Justice = c(
    "justice",
    "judicial",
    "judiciary",
    "court", "courts",
    "legal system",
    "rule of law",
    "dispute resolution",
    "commercial court",
    "case management system",
    "legal reform",
    "legal services",
    "insolvency",
    "bankruptcy",
    "access to justice"
  )
)

# classify ipf projects --------------------------------------------------
wb_gov_ipf <- wb_projects |> 
  filter(
    lending_instrument == "IPF" &
      proj_status == "Active" &
      proj_approval_fy > 0
  )

wb_gov_ipf_classification <- wb_ipf |> 
  left_join(
    portfolioreview::wb_project_components,
    by = c("proj_id"),
    relationship = "many-to-many"
  ) |> 
  mutate(
    comp_name = str_to_lower(comp_name)
  ) |> 
  group_by(proj_id) |>
  summarise(
    project_classification_pfm            = any(str_detect(comp_name, paste(categories$PFM,            collapse = "|")), na.rm = TRUE),
    project_classification_hrm            = any(str_detect(comp_name, paste(categories$HRM,            collapse = "|")), na.rm = TRUE),
    project_classification_govtech        = any(str_detect(comp_name, paste(categories$GovTech,        collapse = "|")), na.rm = TRUE),
    project_classification_anticorruption = any(str_detect(comp_name, paste(categories$Anticorruption, collapse = "|")), na.rm = TRUE),
    project_classification_justice        = any(str_detect(comp_name, paste(categories$Justice,        collapse = "|")), na.rm = TRUE),
    .groups = "drop"
  ) |>
  mutate(
    project_classification_other = !project_classification_pfm &
      !project_classification_hrm &
      !project_classification_govtech &
      !project_classification_anticorruption &
      !project_classification_justice
  )

wb_gov_ipf_classified <- wb_gov_ipf |> 
  left_join(
    wb_gov_ipf_classification,
    by = "proj_id"
  )

wb_gov_ipf_classified |> 
  filter(
    proj_approval_fy > 2015
  ) |>
  group_by(proj_approval_fy, region) |> 
  summarise(
    total_pfm = sum(project_classification_pfm),
    total_hrm = sum(project_classification_hrm),
    total_govtech = sum(project_classification_govtech),
    total_anticorruption = sum(project_classification_anticorruption),
    total_justice = sum(project_classification_justice),
    total_other = sum(project_classification_other)
  ) |> 
  ungroup() |>
  tidyr::pivot_longer(
    cols = starts_with("total_"),
    names_to = "classification",
    values_to = "total"
  ) |>
  # remove "rate_" prefix
  mutate(
    classification = str_remove(classification, "total_")
  ) |>
  ggplot(
    aes(proj_approval_fy, rate, color = classification)
  ) +
  geom_point() +
  geom_line() +
  facet_wrap(~region) +
  scale_color_solarized() +
  theme(
    legend.position = "bottom"
  )
