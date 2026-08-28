# Employee Lifecycle Analytics

A multi-table People Analytics portfolio project covering **workforce movement, employee experience, learning & development, recruitment, and data quality**.

The project was built to answer a broader question than simple attrition reporting:

> **What can we learn about the employee lifecycle when workforce, engagement, training, and recruitment data are analyzed together - and how much can we trust the underlying data?**

## Project Overview

This project uses four HR datasets with 3,000 records each:

- `employee_data.csv`
- `employee_engagement_survey_data.csv`
- `training_and_development_data.csv`
- `recruitment_data.csv`

The analysis combines:

- SQL-based data quality auditing
- Power Query cleaning and validation
- Power BI data modeling
- DAX measures and calculated columns
- Exploratory and visual analysis
- Decomposition Tree
- Key Influencers
- Heatmaps and segmentation

**Tools:** MySQL, DBeaver, Power Query, Power BI, DAX

**Public portfolio files:** README, SQL data-quality audit, dashboard screenshots, and an interactive HTML companion.

**Power BI source file (.pbix):** available upon request for recruitment or technical review.

**Dataset source:** [Employee/HR Dataset (All in One) - Kaggle](https://www.kaggle.com/datasets/ravindrasinghrana/employeedataset)

---

## Business Questions

The project explores six main areas:

1. **Data Trust** - Are employee, engagement, training, and recruitment records internally consistent?
2. **Workforce Movement** - How did hiring, exits, and active headcount change over time?
3. **Exit Exploration** - Which employee characteristics are associated with higher exit rates?
4. **Employee Experience** - How are engagement, satisfaction, and work-life balance related to exit?
5. **Learning & Development** - Do training program, outcome, cost, and participation show different retention patterns?
6. **Recruitment Market** - How do experience, salary expectations, and education relate to offer status?

---

## Data Quality Audit

Before building the dashboard, the raw tables were audited in MySQL.

### Employee data

- 3,000 employee records
- 1,533 employees have an Exit Date
- 1,467 employees have no Exit Date
- **991 employees are marked as `Active` in the source while also having an Exit Date**
- A derived employment status was therefore created from `ExitDate`
- Trailing spaces were found in fields such as `Title` and `DepartmentType`
- Date fields parsed successfully
- A small number of age-at-hire outliers were retained rather than silently removed

### Engagement data

- 3,000 survey records
- **1,662 valid surveys (55.4%)**
- 287 surveys occurred before employee start date
- 1,051 surveys occurred after employee exit
- Invalid records were retained but flagged

### Training data

- 3,000 training records
- **1,683 valid training records (56.1%)**
- 288 training records occurred before employee start date
- 1,029 occurred after employee exit
- Invalid records were retained but flagged

### Recruitment data

The recruitment table was audited separately and **not connected to the employee model** because a reliable candidate-to-employee key could not be established.

Additional issues included:

- ID ranges overlap with employee IDs but do not represent the same people
- ID + name matching produced no reliable employee links
- Job titles are highly granular
- Geography is internally inconsistent
- Phone values are not suitable for analysis
- Recruitment geography was therefore excluded from the dashboard

This was treated as a **data-model limitation**, not something to force into a relationship.

---

## Data Preparation

Power Query was used to create cleaned model tables while preserving the raw inputs.

### Employee transformations

- Trimmed `Title`
- Trimmed `DepartmentType`
- Parsed `StartDate`, `ExitDate`, and `DOB`
- Created:

```text
HasExit
EmploymentStatus_Clean
Tenure Years
Tenure Group
Age at Hire
Age Group
```

`EmploymentStatus_Clean` is based on whether `ExitDate` exists:

```text
No ExitDate -> Active
ExitDate    -> Exited
```

### Engagement validation

Each survey was compared with the employee's employment period and classified as:

- Valid
- Before Hire
- After Exit

Only valid survey records are used in employee-experience measures.

### Training validation

Training dates were validated against the same employment period and classified as:

- Valid
- Before Hire
- After Exit

Only valid training records are used in L&D measures.

### Recruitment preparation

Fields not suitable for analysis were removed, including:

- Phone
- Email
- Address
- City
- State
- ZIP
- Country

Analytical bands were created for:

- Years of Experience
- Desired Salary

---

## Data Model

The employee table is the central workforce table.

Relationships:

```text
employee_clean 1:1 engagement_clean
employee_clean 1:1 training_clean
```

The recruitment table remains disconnected because no reliable employee linkage exists.

A dedicated `DateTable` is connected to:

- `StartDate` - active relationship
- `ExitDate` - inactive relationship

The inactive exit-date relationship is activated in exit measures using `USERELATIONSHIP`.

Separate measure tables were used to keep the model organized:

```text
_Measures_Workforce
_Measures_Engagement
_Measures_Training
_Measures_Recruitment
_Measures_DataQuality
```

---

## Example DAX

### Exits

```DAX
Exits =
CALCULATE(
    [Exited Employees],
    CROSSFILTER(DateTable[Date], employee_clean[StartDate], NONE),
    USERELATIONSHIP(DateTable[Date], employee_clean[ExitDate])
)
```

### Active Headcount

```DAX
Active Headcount =
VAR SelectedDate = MAX(DateTable[Date])
RETURN
CALCULATE(
    [Employees],
    REMOVEFILTERS(DateTable),
    FILTER(
        ALL(employee_clean[StartDate], employee_clean[ExitDate]),
        employee_clean[StartDate] <= SelectedDate &&
        (
            ISBLANK(employee_clean[ExitDate]) ||
            employee_clean[ExitDate] > SelectedDate
        )
    )
)
```

### Exit Rate

```DAX
Exit Rate =
DIVIDE(
    [Exited Employees],
    [Employees],
    0
)
```

---

# Dashboard

The repository includes static dashboard screenshots and an **interactive HTML companion** for browser-based viewing.

**Interactive HTML companion:** AI-assisted browser version created from the completed Power BI project. The analytical logic, metrics, findings, page structure, and visual design are based on the original analysis. The original analytical model remains in Power BI.


## 1. Data Trust & Overview

![Data Trust & Overview](dashboard/01_data_trust_overview.png)

Key metrics:

- **Employees:** 3,000
- **Active Employees:** 1,467
- **Exited Employees:** 1,533
- **Exit Rate:** 51.1%
- **Status Inconsistency:** 991
- **Valid Survey Records:** 55.4%
- **Valid Training Records:** 56.1%

The original employee status field is compared with the derived status to make the source-data inconsistency visible rather than hiding it during cleaning.

---

## 2. Workforce Movement & Trends

![Workforce Movement & Trends](dashboard/02_workforce_movement.png)

The page tracks:

- Hires
- Exits
- Net workforce change
- Active headcount by year
- Annual hires vs exits

The dataset runs through **August 6, 2023**, so 2023 is a partial year and should not be interpreted as a full-year comparison.

---

## 3. Exit Exploration

![Exit Exploration](dashboard/03_exit_exploration.png)

A Decomposition Tree is used to explore exit rate by:

- Department
- Age group
- Performance score
- Tenure group

The analysis is exploratory: high percentages in small segments are treated as signals for investigation, not as standalone conclusions.

This page uses the **full employee population**. In the full workforce, employees with **< 1 year tenure have a 70.4% exit rate**.

---

## 4. Employee Experience

![Employee Experience](dashboard/04_employee_experience.png)

Only surveys that fall inside the employee's employment period are used.

### Main findings

- **Tenure below 1 year is the strongest exit signal identified by Key Influencers: 2.60x**
- **Work-Life Balance <= 2 is a secondary signal: 1.27x**
- Among employees with **valid survey records**, first-year exit rate reaches:
  - **50.0% outside Production**
  - **37.8% in Production**
  - **42.0% combined** across these first-year survey-valid employees

This page is intentionally restricted to employees with **valid survey records** - surveys that fall inside the employee's employment period. These first-year rates are therefore **not directly comparable** with the **70.4% company-wide first-year exit rate** shown on the Exit Exploration page, which uses the full employee population.

The 20.5% baseline on the Employee Experience page represents the exit rate within the valid-survey population (340 of 1,662 employees), not the 51.1% company-wide exit rate. This population is skewed toward retained employees because valid survey timing requires the survey to fall within the employment period: only 22.2% of exited employees have a valid survey, compared with 90.1% of active employees.

The engagement / work-life-balance heatmap does not show a clean linear relationship between engagement score and exit rate. Work-life balance provides a clearer secondary signal.

The **Top segments** view adds an important lifecycle pattern: risk is most concentrated during the first year, but it does not disappear afterward. A later-tenure **Production** segment with **Work-Life Balance <= 2** still shows an elevated **27.6% exit rate** across **192 employees**, compared with a **20.5% baseline** for the valid-survey population. This suggests that the relevant risk pattern changes with tenure: early tenure is the dominant signal first, while work-life balance becomes more informative in a narrower workforce context later.

---

## 5. Learning & Development

![Learning & Development](dashboard/05_learning_development.png)

The page combines:

- Average training cost
- Exit rate
- Training participation
- Training program
- Training outcome

### Examples

**Technical Skills**

- Passed: **15.8% exit rate**
- Incomplete: **29.4%**
- Difference: **13.6 percentage points**

**Leadership Development**

- Completed: **16.7%**
- Incomplete: **26.2%**
- Difference: **9.5 percentage points**

However, the direction is not consistent across all programs.

The takeaway is therefore **not** that incomplete training causes exit. Instead, training outcomes appear to interact with program context and may be useful as an additional diagnostic signal.

---

## 6. Recruitment Market

![Recruitment Market](dashboard/06_recruitment_market.png)

Recruitment is analyzed independently because it cannot be reliably linked to employee records.

### Main findings

Offer rates by education are tightly clustered:

- Master's Degree: **22.3%**
- Bachelor's Degree: **20.0%**
- PhD: **20.0%**
- High School: **19.1%**

Within candidates with **3-5 years of experience**, offered share ranges from:

- **8.7%** for desired salary of 30-45k
- **27.8%** for desired salary of 90k+

No strong standalone predictor of offer status was identified among the tested candidate characteristics. Differences appear mainly in specific combinations of experience and salary expectations.

---

# Key Insights

## 1. Early tenure is the strongest retention signal

In the **full employee population**, employees with less than one year of tenure have a **70.4% exit rate**.

In the separate **valid-survey subset** used for Employee Experience analysis, tenure below one year is also the strongest Key Influencers signal (**2.60x**).

This makes **first-year retention** the highest-priority area for further investigation.

## 2. First-year risk differs by workforce segment

Within the **valid-survey subset** used on the Employee Experience page:

- Non-Production + tenure < 1 year: **50.0%**
- Production + tenure < 1 year: **37.8%**
- Combined first-year exit rate in this subset: **42.0%**

These rates use a different analytical population from the **70.4% full-workforce first-year exit rate**, so they should not be compared as if they had the same denominator.

This suggests that a single organization-wide onboarding explanation may be too simplistic.

## 3. The risk pattern changes with tenure

Low work-life balance does not explain exit by itself, but **Work-Life Balance <= 2** becomes more useful when combined with tenure and workforce segment.

The valid-survey analysis suggests a lifecycle pattern:

- During the **first year**, tenure itself is the dominant signal.
- In a later-tenure **Production** segment, **Work-Life Balance <= 2** identifies an elevated-risk group with a **27.6% exit rate** across **192 employees**, versus a **20.5% baseline**.

This is more informative than treating tenure, work-life balance, or department as isolated drivers.

## 4. Training outcomes are context-dependent

Training results differ meaningfully by program, but not in one consistent direction across all programs.

L&D effectiveness should therefore be evaluated at **Program x Outcome x Retention** level rather than through one overall completion metric.

## 5. Recruitment data does not reveal a simple offer driver

Education, experience, gender, and salary expectations did not produce a strong standalone offer predictor.

The stronger differences appear in specific combinations rather than in one universal factor.

## 6. Data quality is itself a business finding

The project shows why HR analytics should not begin with visualization.

Examples:

- 991 source-status inconsistencies
- 44.6% invalid survey timing
- 43.9% invalid training timing
- recruitment data without a reliable hire linkage

Without validation, several dashboard metrics would have been misleading.

---

# Business Recommendations

### 1. Prioritize first-year retention analysis

Investigate the employee journey during the first 12 months:

- onboarding quality
- 30 / 60 / 90-day experience
- manager support
- expectation alignment
- early feedback
- probation-period exits
- structured termination reasons
- recruitment source for new hires

### 2. Investigate first-year Non-Production exits separately

Within the valid-survey subset, first-year exit is especially high outside Production. Analyze those roles independently rather than assuming the same drivers apply across the workforce.

### 3. Use work-life balance as a context-dependent risk signal

Low work-life balance should not be treated as a standalone prediction rule. Its value appears to depend on **where an employee is in the lifecycle and which workforce segment they belong to**.

Use it to prioritize deeper review when it appears alongside tenure and department patterns, rather than applying one organization-wide threshold.

### 4. Evaluate L&D at program-and-outcome level

Instead of monitoring only course completion, compare:

```text
Training Program
x Training Outcome
x Retention / Exit
```

This can help identify where training may be associated with different employee outcomes.

### 5. Improve HR data architecture

A production HR analytics environment should include:

- stable employee IDs
- stable candidate IDs
- candidate-to-hire mapping
- effective-dated employee status history
- standardized recruitment timestamps
- temporal validation rules
- standardized geography
- structured termination reasons

---

# Limitations

- The dataset contains substantial timing and consistency issues.
- Recruitment cannot be reliably linked to employees.
- Recruitment geography is unsuitable for geographic analysis.
- 2023 is a partial year ending August 6.
- Some employee segments are small and can produce visually high rates.
- Key Influencers and segmentation identify **associations**, not causation.
- Training and engagement analyses use only records validated against the employment period.
- Metrics shown on different dashboard pages can use different analytical populations. In particular, the **70.4% first-year exit rate** on Exit Exploration uses the full workforce, while the **50.0% / 37.8% first-year segment rates** on Employee Experience use only employees with valid survey records.

---

# Repository Structure

```text
employee-lifecycle-analytics/
|
|-- README.md
|-- data_quality_audit.sql
|-- Employee_Lifecycle_Interactive_Dashboard.html
|
`-- dashboard/
    |-- 01_data_trust_overview.png
    |-- 02_workforce_movement.png
    |-- 03_exit_exploration.png
    |-- 04_employee_experience.png
    |-- 05_learning_development.png
    `-- 06_recruitment_market.png
```

The public repository intentionally does **not** include the Power BI source file (`.pbix`).

**Power BI source file (.pbix) is available upon request for recruitment or technical review.**

The raw Kaggle CSV files are also not included. The original dataset is linked above.

---

# Skills Demonstrated

- HR / People Analytics
- Data Quality Assessment
- SQL
- MySQL
- DBeaver
- Power Query
- Power BI
- DAX
- Data Modeling
- Date Tables
- Active / Inactive Relationships
- Workforce Metrics
- Attrition / Retention Analysis
- Employee Experience Analysis
- Learning & Development Analytics
- Recruitment Analytics
- Segmentation
- Decomposition Tree
- Key Influencers
- Data Visualization
- Business Interpretation

---

## Final Note

This project is intentionally not built around one perfect dataset or one headline metric.

A large part of the work was deciding **which records could be trusted, which relationships could be modeled, which analyses required validation, and where the data did not support a stronger conclusion**.

That is also the main point of the project: useful People Analytics starts before the dashboard.
