# portfolioreview

An R data package for identifying and analysing World Bank Governance operations that contribute to the **IDA21 Governance Policy Commitment**. The portfolio covers active lending operations (IPF, PforR) and Advisory Services & Analytics (ASA) led by the Governance Global Practice (GOV) in IDA-eligible and Blend countries.

---

## Objective

Map the active Governance portfolio against four thematic pillars of the IDA21 Governance Policy Commitment:

| Flag | Theme |
|---|---|
| `theme_pfm` | Public Financial Management |
| `theme_procurement` | Public Procurement |
| `theme_public_admin` | Public Administration |
| `theme_env_social` | Environmental & Social Governance |

---

## Folder structure

```
portfolioreview/
├── R/                      # Package functions and data documentation (data.R)
├── data/                   # Binary .rda datasets (auto-generated)
├── data-raw/               # Data preparation scripts and raw inputs
│   ├── input/              # Source CSVs from WB Data Explorer (not tracked in git)
│   └── *.R                 # One script per dataset
├── analysis/               # Exploratory analysis and portfolio review scripts
├── inst/
│   ├── extdata/            # Regional Excel outputs (one .xlsx per region)
│   └── methodology/        # Methodology note and portfolio review Rmd/Word
└── man/                    # Auto-generated documentation
```

---

## Workflow

1. **Download source data** from the [World Bank Data Explorer](https://dataexplorer.worldbank.org/) into `data-raw/input/wb-data-explorer/`
2. **Run the pipeline** via `targets`:
   ```r
   targets::tar_make()
   ```
   This executes all `data-raw/*.R` scripts in dependency order and writes `.rda` files to `data/`
3. **Load the package** to access the datasets:
   ```r
   devtools::load_all()
   portfolioreview::wb_projects_gov
   ```
4. **Render the portfolio review** report:
   ```r
   rmarkdown::render("inst/methodology/portfolio_review.Rmd")
   ```

---

## Key datasets

| Dataset | Description |
|---|---|
| `wb_projects` | All active/pipeline GOV operations |
| `wb_projects_gov` | Filtered IDA/Blend portfolio with thematic flags |
| `wb_project_components` | Project components with implementation ratings |
| `wb_project_themes` | Project theme assignments with hierarchy |
| `wb_project_indicators` | Results indicators with baseline and progress values |
| `wb_documents` | Project documents (PAD, PID, ISR) from the WB API |
| `wb_income_and_region` | Country income group and lending category reference |
