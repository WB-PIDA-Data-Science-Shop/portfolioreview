# Methodology Note: World Bank Governance IDA Portfolio Dataset

**Prepared:** May 1, 2026 
**Final sample:** 81 projects

---

## Data Sources

All underlying data were extracted from the [World Bank Data Explorer](https://dataexplorer.worldbank.org/) in late April 2026. Reference dates by dataset are as follows:

| Dataset | File | Extracted |
|---|---|---|
| Project Master V3 | `PROJECT_MASTER_V3` | April 21, 2026 |
| Country Reference | `COUNTRY` | April 22, 2026 |
| Project Component List V3 | `PROJECT_COMPONENT_LIST_V3` | April 22, 2026 |
| Project Theme V3 | `PROJECT_THEME_V3` | April 29, 2026 |
| Theme Reference | `THEME` | April 29, 2026 |
| Project Result Indicator Detail V2 | `PROJECT_RESULT_IND_DETAIL_V2` | April 29, 2026 |

World Bank lending category and income group classifications were sourced from the World Bank country classification file (List of Economies, FY2026).

---

## Sample Construction

Starting from the full Project Master V3 dataset, projects were selected using the following criteria:

1. **Lead Global Practice:** Projects where the Governance Global Practice (`GOV`) is the designated lead GP.
2. **Project status:** Active projects only (Pipeline and Closed projects excluded).
3. **Approval fiscal year:** Projects with a valid approval fiscal year recorded in the system.
4. **IDA eligibility:** Projects in IDA-eligible or Blend countries only, as classified in the World Bank FY2026 List of Economies. Regional or multi-country projects were matched on the primary country code recorded in the project record.
5. **Theme relevance:** At least one of the four thematic classification flags (see below) must be `TRUE`.

---

## Thematic Classification

Projects were classified into four thematic categories using two complementary sources: project-level theme assignments and project component names (for procurement, see note below). Multiple thematic categories can apply to the same project.

### Theme flags

Each theme flag takes a value of TRUE or FALSE, depending on whether the project is classified as one of the following theme categories.

| Flag | Theme category | Themes included (Level 3) |
|---|---|---|
| `theme_pfm` | Public Finance Management | Public Expenditure Management; Debt Management; Domestic Revenue Administration; Budget and Treasury Management; Public Assets and Investment Management; Government Financial Reporting and Balance Sheets; Oversight, Accountability, and Supreme Audit Institutions |
| `theme_procurement` | Public Procurement | "Procurement" theme; **or** any component name containing the keyword *procurement* |
| `theme_public_admin` | Public Administration | Administrative and Civil Service Reform; GovTech; E-Government incl. e-services; Transparency, Accountability and Good Governance |
| `theme_env_social` | Institutional dimensions of social & environmental aspects | Adaptation; Mitigation; Disaster Risk Management Governance; Citizen Engagement and Social Accountability; Community and Local Infrastructure and Service Delivery; Community Livelihoods and Local Economic Development; Community and Local Governance |

**Note on procurement:** The *Procurement* theme was introduced as a standalone World Bank thematic category only in 2025. For projects approved prior to FY2025, assignment to procurement was evaluated by identifying procurement as a keyword in one of the components (`PROJECT_COMPONENT_LIST_V3`).

---

## Final Dataset

The final dataset (`wb_projects_gov`) contains **81 active projects** across 9 World Bank regions, (including both lending operations and ASAs). Each row corresponds to one project, with additional project information. Considering only projects approved in FY2026, there are currently 12 projects active, including 9 lending operations and 3 ASAs.