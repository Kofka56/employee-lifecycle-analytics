-- ============================================================================
-- Employee Lifecycle Analytics
-- Data Quality Audit
-- Database: employee_lifecycle_analytics
-- SQL dialect: MySQL
--
-- Purpose:
-- Validate source data before Power Query transformations and Power BI modeling.
--
-- RAW tables:
--   employee_raw
--   engagement_raw
--   training_raw
--   recruitment_raw
--
-- The script preserves RAW data and performs read-only validation queries.
-- ============================================================================

USE employee_lifecycle_analytics;


-- ============================================================================
-- 1. ROW COUNTS AND UNIQUE IDENTIFIERS
-- Expected: 3000 rows and 3000 unique IDs in each table
-- ============================================================================

SELECT
    'employee' AS table_name,
    COUNT(*) AS rows_count,
    COUNT(DISTINCT EmpID) AS unique_ids
FROM employee_raw;

SELECT
    'engagement' AS table_name,
    COUNT(*) AS rows_count,
    COUNT(DISTINCT `Employee ID`) AS unique_ids
FROM engagement_raw;

SELECT
    'training' AS table_name,
    COUNT(*) AS rows_count,
    COUNT(DISTINCT `Employee ID`) AS unique_ids
FROM training_raw;

SELECT
    'recruitment' AS table_name,
    COUNT(*) AS rows_count,
    COUNT(DISTINCT `Applicant ID`) AS unique_ids
FROM recruitment_raw;


-- ============================================================================
-- 2. FULL DUPLICATE CHECKS
-- Expected: 0 duplicate groups in all four tables
-- ============================================================================

SELECT COUNT(*) AS duplicate_groups
FROM (
    SELECT
        EmpID,
        FirstName,
        LastName,
        StartDate,
        ExitDate,
        Title,
        Supervisor,
        ADEmail,
        BusinessUnit,
        EmployeeStatus,
        EmployeeType,
        PayZone,
        EmployeeClassificationType,
        TerminationType,
        TerminationDescription,
        DepartmentType,
        Division,
        DOB,
        State,
        JobFunctionDescription,
        GenderCode,
        LocationCode,
        RaceDesc,
        MaritalDesc,
        `Performance Score`,
        `Current Employee Rating`,
        COUNT(*) AS cnt
    FROM employee_raw
    GROUP BY
        EmpID,
        FirstName,
        LastName,
        StartDate,
        ExitDate,
        Title,
        Supervisor,
        ADEmail,
        BusinessUnit,
        EmployeeStatus,
        EmployeeType,
        PayZone,
        EmployeeClassificationType,
        TerminationType,
        TerminationDescription,
        DepartmentType,
        Division,
        DOB,
        State,
        JobFunctionDescription,
        GenderCode,
        LocationCode,
        RaceDesc,
        MaritalDesc,
        `Performance Score`,
        `Current Employee Rating`
    HAVING COUNT(*) > 1
) x;

SELECT COUNT(*) AS duplicate_groups
FROM (
    SELECT
        `Employee ID`,
        `Survey Date`,
        `Engagement Score`,
        `Satisfaction Score`,
        `Work-Life Balance Score`,
        COUNT(*) AS cnt
    FROM engagement_raw
    GROUP BY
        `Employee ID`,
        `Survey Date`,
        `Engagement Score`,
        `Satisfaction Score`,
        `Work-Life Balance Score`
    HAVING COUNT(*) > 1
) x;

SELECT COUNT(*) AS duplicate_groups
FROM (
    SELECT
        `Employee ID`,
        `Training Date`,
        `Training Program Name`,
        `Training Type`,
        `Training Outcome`,
        Location,
        Trainer,
        `Training Duration(Days)`,
        `Training Cost`,
        COUNT(*) AS cnt
    FROM training_raw
    GROUP BY
        `Employee ID`,
        `Training Date`,
        `Training Program Name`,
        `Training Type`,
        `Training Outcome`,
        Location,
        Trainer,
        `Training Duration(Days)`,
        `Training Cost`
    HAVING COUNT(*) > 1
) x;

SELECT COUNT(*) AS duplicate_groups
FROM (
    SELECT
        `Applicant ID`,
        `Application Date`,
        `First Name`,
        `Last Name`,
        Gender,
        `Date of Birth`,
        `Phone Number`,
        Email,
        Address,
        City,
        State,
        `Zip Code`,
        Country,
        `Education Level`,
        `Years of Experience`,
        `Desired Salary`,
        `Job Title`,
        Status,
        COUNT(*) AS cnt
    FROM recruitment_raw
    GROUP BY
        `Applicant ID`,
        `Application Date`,
        `First Name`,
        `Last Name`,
        Gender,
        `Date of Birth`,
        `Phone Number`,
        Email,
        Address,
        City,
        State,
        `Zip Code`,
        Country,
        `Education Level`,
        `Years of Experience`,
        `Desired Salary`,
        `Job Title`,
        Status
    HAVING COUNT(*) > 1
) x;


-- ============================================================================
-- 3. EMPLOYEE: MISSING VALUES
-- Expected:
--   ExitDate = 1467 empty
--   TerminationDescription = 1467 empty
--   key analytical fields = 0 empty
-- ============================================================================

SELECT
    SUM(ExitDate IS NULL OR TRIM(ExitDate) = '') AS exitdate_empty,
    SUM(TerminationDescription IS NULL OR TRIM(TerminationDescription) = '') AS termination_description_empty,
    SUM(Title IS NULL OR TRIM(Title) = '') AS title_empty,
    SUM(DepartmentType IS NULL OR TRIM(DepartmentType) = '') AS department_empty,
    SUM(`Performance Score` IS NULL OR TRIM(`Performance Score`) = '') AS performance_empty
FROM employee_raw;


-- ============================================================================
-- 4. EMPLOYEE: TRAILING SPACES / FALSE CATEGORIES
-- Expected:
--   Title with spaces = 8
--   DepartmentType with spaces = 2020
--   distinct Title: 32 before TRIM, 31 after TRIM
-- ============================================================================

SELECT
    SUM(Title <> TRIM(Title)) AS title_with_spaces,
    SUM(DepartmentType <> TRIM(DepartmentType)) AS department_with_spaces,
    COUNT(DISTINCT Title) AS title_before_trim,
    COUNT(DISTINCT TRIM(Title)) AS title_after_trim
FROM employee_raw;

SELECT
    CONCAT('[', Title, ']') AS original_title,
    CONCAT('[', TRIM(Title), ']') AS trimmed_title,
    COUNT(*) AS rows_count
FROM employee_raw
WHERE Title <> TRIM(Title)
GROUP BY Title, TRIM(Title);

SELECT
    CONCAT('[', DepartmentType, ']') AS original_department,
    CONCAT('[', TRIM(DepartmentType), ']') AS trimmed_department,
    COUNT(*) AS rows_count
FROM employee_raw
WHERE DepartmentType <> TRIM(DepartmentType)
GROUP BY DepartmentType, TRIM(DepartmentType);


-- ============================================================================
-- 5. EMPLOYEE: STATUS VS EXIT DATE
-- Key finding:
--   991 employees labelled Active have an ExitDate
-- ============================================================================

SELECT
    EmployeeStatus,
    COUNT(*) AS employees,
    SUM(NULLIF(TRIM(ExitDate), '') IS NOT NULL) AS employees_with_exit_date
FROM employee_raw
GROUP BY EmployeeStatus
ORDER BY employees DESC;


-- ============================================================================
-- 6. EMPLOYEE: TERMINATION LOGIC
-- Expected:
--   Unk = 1467 and all 1467 have no ExitDate
--   Specific termination types all have ExitDate
-- ============================================================================

SELECT
    TerminationType,
    COUNT(*) AS employees,
    SUM(NULLIF(TRIM(ExitDate), '') IS NULL) AS without_exit_date
FROM employee_raw
GROUP BY TerminationType
ORDER BY employees DESC;

SELECT
    COUNT(*) AS filled_descriptions,
    COUNT(DISTINCT TerminationDescription) AS unique_descriptions
FROM employee_raw
WHERE NULLIF(TRIM(TerminationDescription), '') IS NOT NULL;


-- ============================================================================
-- 7. DATE PARSING AND EMPLOYEE DATE LOGIC
-- Expected: 0 invalid dates and 0 cases where ExitDate < StartDate
-- ============================================================================

SELECT COUNT(*) AS invalid_start_dates
FROM employee_raw
WHERE StartDate IS NOT NULL
  AND TRIM(StartDate) <> ''
  AND STR_TO_DATE(StartDate, '%d-%b-%y') IS NULL;

SELECT COUNT(*) AS invalid_exit_dates
FROM employee_raw
WHERE ExitDate IS NOT NULL
  AND TRIM(ExitDate) <> ''
  AND STR_TO_DATE(ExitDate, '%d-%b-%y') IS NULL;

SELECT COUNT(*) AS invalid_employee_dob
FROM employee_raw
WHERE DOB IS NOT NULL
  AND TRIM(DOB) <> ''
  AND STR_TO_DATE(DOB, '%d-%m-%Y') IS NULL;

SELECT COUNT(*) AS exit_before_start
FROM employee_raw
WHERE NULLIF(TRIM(ExitDate), '') IS NOT NULL
  AND STR_TO_DATE(ExitDate, '%d-%b-%y')
      < STR_TO_DATE(StartDate, '%d-%b-%y');

SELECT COUNT(*) AS invalid_survey_dates
FROM engagement_raw
WHERE `Survey Date` IS NOT NULL
  AND TRIM(`Survey Date`) <> ''
  AND STR_TO_DATE(`Survey Date`, '%d-%m-%Y') IS NULL;

SELECT COUNT(*) AS invalid_training_dates
FROM training_raw
WHERE `Training Date` IS NOT NULL
  AND TRIM(`Training Date`) <> ''
  AND STR_TO_DATE(`Training Date`, '%d-%b-%y') IS NULL;

SELECT COUNT(*) AS invalid_application_dates
FROM recruitment_raw
WHERE `Application Date` IS NOT NULL
  AND TRIM(`Application Date`) <> ''
  AND STR_TO_DATE(`Application Date`, '%d-%b-%y') IS NULL;

SELECT COUNT(*) AS invalid_candidate_dob
FROM recruitment_raw
WHERE `Date of Birth` IS NOT NULL
  AND TRIM(`Date of Birth`) <> ''
  AND STR_TO_DATE(`Date of Birth`, '%d-%m-%Y') IS NULL;


-- ============================================================================
-- 8. ENGAGEMENT: MISSING VALUES AND SCORE RANGES
-- Expected: no NULLs; all three scores range from 1 to 5
-- ============================================================================

SELECT
    SUM(`Engagement Score` IS NULL) AS engagement_nulls,
    SUM(`Satisfaction Score` IS NULL) AS satisfaction_nulls,
    SUM(`Work-Life Balance Score` IS NULL) AS work_life_balance_nulls
FROM engagement_raw;

SELECT
    MIN(`Engagement Score`) AS min_engagement,
    MAX(`Engagement Score`) AS max_engagement,
    MIN(`Satisfaction Score`) AS min_satisfaction,
    MAX(`Satisfaction Score`) AS max_satisfaction,
    MIN(`Work-Life Balance Score`) AS min_work_life_balance,
    MAX(`Work-Life Balance Score`) AS max_work_life_balance
FROM engagement_raw;


-- ============================================================================
-- 9. ENGAGEMENT: SURVEY TIMING VS EMPLOYMENT PERIOD
-- Expected:
--   before hire = 287
--   after exit  = 1051
--   valid       = 1662
--   invalid share = 1338 / 3000 = 44.60%
-- ============================================================================

SELECT COUNT(*) AS survey_before_start
FROM employee_raw e
JOIN engagement_raw s
    ON e.EmpID = s.`Employee ID`
WHERE STR_TO_DATE(s.`Survey Date`, '%d-%m-%Y')
    < STR_TO_DATE(e.StartDate, '%d-%b-%y');

SELECT COUNT(*) AS survey_after_exit
FROM employee_raw e
JOIN engagement_raw s
    ON e.EmpID = s.`Employee ID`
WHERE NULLIF(TRIM(e.ExitDate), '') IS NOT NULL
  AND STR_TO_DATE(s.`Survey Date`, '%d-%m-%Y')
      > STR_TO_DATE(e.ExitDate, '%d-%b-%y');

SELECT COUNT(*) AS valid_survey
FROM employee_raw e
JOIN engagement_raw s
    ON e.EmpID = s.`Employee ID`
WHERE STR_TO_DATE(s.`Survey Date`, '%d-%m-%Y')
      >= STR_TO_DATE(e.StartDate, '%d-%b-%y')
  AND (
        NULLIF(TRIM(e.ExitDate), '') IS NULL
        OR STR_TO_DATE(s.`Survey Date`, '%d-%m-%Y')
           <= STR_TO_DATE(e.ExitDate, '%d-%b-%y')
      );


-- ============================================================================
-- 10. TRAINING: MISSING VALUES, CATEGORIES AND NUMERIC RANGES
-- ============================================================================

SELECT
    SUM(`Training Program Name` IS NULL) AS program_nulls,
    SUM(`Training Type` IS NULL) AS type_nulls,
    SUM(`Training Outcome` IS NULL) AS outcome_nulls,
    SUM(`Training Duration(Days)` IS NULL) AS duration_nulls,
    SUM(`Training Cost` IS NULL) AS cost_nulls
FROM training_raw;

SELECT
    MIN(`Training Duration(Days)`) AS min_duration,
    MAX(`Training Duration(Days)`) AS max_duration,
    MIN(`Training Cost`) AS min_cost,
    MAX(`Training Cost`) AS max_cost
FROM training_raw;

SELECT
    SUM(`Training Program Name` <> TRIM(`Training Program Name`)) AS program_spaces,
    SUM(`Training Type` <> TRIM(`Training Type`)) AS type_spaces,
    SUM(`Training Outcome` <> TRIM(`Training Outcome`)) AS outcome_spaces
FROM training_raw;

SELECT
    `Training Program Name`,
    COUNT(*) AS rows_count
FROM training_raw
GROUP BY `Training Program Name`
ORDER BY rows_count DESC;

SELECT
    `Training Type`,
    COUNT(*) AS rows_count
FROM training_raw
GROUP BY `Training Type`
ORDER BY rows_count DESC;

SELECT
    `Training Outcome`,
    COUNT(*) AS rows_count
FROM training_raw
GROUP BY `Training Outcome`
ORDER BY rows_count DESC;


-- ============================================================================
-- 11. TRAINING: TRAINING TIMING VS EMPLOYMENT PERIOD
-- Expected:
--   before hire = 288
--   after exit  = 1029
--   valid       = 1683
--   invalid share = 1317 / 3000 = 43.90%
-- ============================================================================

SELECT COUNT(*) AS training_before_start
FROM employee_raw e
JOIN training_raw t
    ON e.EmpID = t.`Employee ID`
WHERE STR_TO_DATE(t.`Training Date`, '%d-%b-%y')
      < STR_TO_DATE(e.StartDate, '%d-%b-%y');

SELECT COUNT(*) AS training_after_exit
FROM employee_raw e
JOIN training_raw t
    ON e.EmpID = t.`Employee ID`
WHERE NULLIF(TRIM(e.ExitDate), '') IS NOT NULL
  AND STR_TO_DATE(t.`Training Date`, '%d-%b-%y')
      > STR_TO_DATE(e.ExitDate, '%d-%b-%y');

SELECT COUNT(*) AS valid_training
FROM employee_raw e
JOIN training_raw t
    ON e.EmpID = t.`Employee ID`
WHERE STR_TO_DATE(t.`Training Date`, '%d-%b-%y')
      >= STR_TO_DATE(e.StartDate, '%d-%b-%y')
  AND (
        NULLIF(TRIM(e.ExitDate), '') IS NULL
        OR STR_TO_DATE(t.`Training Date`, '%d-%b-%y')
           <= STR_TO_DATE(e.ExitDate, '%d-%b-%y')
      );


-- ============================================================================
-- 12. EMPLOYEE PERFORMANCE AND RATING VALIDATION
-- ============================================================================

SELECT
    MIN(`Current Employee Rating`) AS min_rating,
    MAX(`Current Employee Rating`) AS max_rating
FROM employee_raw;

SELECT
    `Performance Score`,
    COUNT(*) AS employees
FROM employee_raw
GROUP BY `Performance Score`
ORDER BY employees DESC;


-- ============================================================================
-- 13. EMPLOYEE AGE OUTLIER CHECKS
-- Age calculated at StartDate
-- Expected:
--   min = 17
--   max = 81
--   under 18 = 5
--   over 80 completed years = 2
-- ============================================================================

SELECT MIN(
    TIMESTAMPDIFF(
        YEAR,
        STR_TO_DATE(DOB, '%d-%m-%Y'),
        STR_TO_DATE(StartDate, '%d-%b-%y')
    )
) AS min_age
FROM employee_raw;

SELECT MAX(
    TIMESTAMPDIFF(
        YEAR,
        STR_TO_DATE(DOB, '%d-%m-%Y'),
        STR_TO_DATE(StartDate, '%d-%b-%y')
    )
) AS max_age
FROM employee_raw;

SELECT COUNT(*) AS under_18
FROM employee_raw
WHERE TIMESTAMPDIFF(
        YEAR,
        STR_TO_DATE(DOB, '%d-%m-%Y'),
        STR_TO_DATE(StartDate, '%d-%b-%y')
      ) < 18;

SELECT COUNT(*) AS over_80
FROM employee_raw
WHERE TIMESTAMPDIFF(
        YEAR,
        STR_TO_DATE(DOB, '%d-%m-%Y'),
        STR_TO_DATE(StartDate, '%d-%b-%y')
      ) > 80;


-- ============================================================================
-- 14. RECRUITMENT: MISSING VALUES, CATEGORIES AND NUMERIC RANGES
-- ============================================================================

SELECT
    SUM(`Application Date` IS NULL) AS application_date_nulls,
    SUM(`Education Level` IS NULL) AS education_nulls,
    SUM(`Years of Experience` IS NULL) AS experience_nulls,
    SUM(`Desired Salary` IS NULL) AS salary_nulls,
    SUM(`Job Title` IS NULL) AS job_title_nulls,
    SUM(Status IS NULL) AS status_nulls
FROM recruitment_raw;

SELECT
    MIN(`Years of Experience`) AS min_experience,
    MAX(`Years of Experience`) AS max_experience,
    MIN(`Desired Salary`) AS min_salary,
    MAX(`Desired Salary`) AS max_salary
FROM recruitment_raw;

SELECT
    SUM(`Education Level` <> TRIM(`Education Level`)) AS education_spaces,
    SUM(`Job Title` <> TRIM(`Job Title`)) AS job_title_spaces,
    SUM(Status <> TRIM(Status)) AS status_spaces
FROM recruitment_raw;

SELECT
    Status,
    COUNT(*) AS candidates
FROM recruitment_raw
GROUP BY Status
ORDER BY candidates DESC;

SELECT
    `Education Level`,
    COUNT(*) AS candidates
FROM recruitment_raw
GROUP BY `Education Level`
ORDER BY candidates DESC;

SELECT
    COUNT(DISTINCT `Job Title`) AS original_titles,
    COUNT(DISTINCT LOWER(TRIM(`Job Title`))) AS normalized_titles
FROM recruitment_raw;


-- ============================================================================
-- 15. RECRUITMENT: CANDIDATE AGE CHECKS
-- Age calculated at Application Date
-- Expected:
--   min = 17
--   max = 60
--   under 18 = 6
-- ============================================================================

SELECT MIN(
    TIMESTAMPDIFF(
        YEAR,
        STR_TO_DATE(`Date of Birth`, '%d-%m-%Y'),
        STR_TO_DATE(`Application Date`, '%d-%b-%y')
    )
) AS min_candidate_age
FROM recruitment_raw;

SELECT MAX(
    TIMESTAMPDIFF(
        YEAR,
        STR_TO_DATE(`Date of Birth`, '%d-%m-%Y'),
        STR_TO_DATE(`Application Date`, '%d-%b-%y')
    )
) AS max_candidate_age
FROM recruitment_raw;

SELECT COUNT(*) AS under_18_candidates
FROM recruitment_raw
WHERE TIMESTAMPDIFF(
        YEAR,
        STR_TO_DATE(`Date of Birth`, '%d-%m-%Y'),
        STR_TO_DATE(`Application Date`, '%d-%b-%y')
      ) < 18;


-- ============================================================================
-- 16. RECRUITMENT <-> EMPLOYEE RELATIONSHIP VALIDATION
--
-- Important:
-- Applicant ID and EmpID both use values 1001-4000, but they are NOT
-- the same identifier.
--
-- Expected:
--   same names where Applicant ID = EmpID: 0
--   Application Date after matched-ID employee StartDate: 2927
-- ============================================================================

SELECT COUNT(*) AS same_people_by_id_and_name
FROM employee_raw e
JOIN recruitment_raw r
    ON e.EmpID = r.`Applicant ID`
WHERE LOWER(TRIM(e.FirstName)) = LOWER(TRIM(r.`First Name`))
  AND LOWER(TRIM(e.LastName)) = LOWER(TRIM(r.`Last Name`));

SELECT COUNT(*) AS applications_after_employee_start
FROM employee_raw e
JOIN recruitment_raw r
    ON e.EmpID = r.`Applicant ID`
WHERE STR_TO_DATE(r.`Application Date`, '%d-%b-%y')
      > STR_TO_DATE(e.StartDate, '%d-%b-%y');

-- Additional name-based validation independent of IDs
-- Expected: 7 full-name matches, but none confirmed by Date of Birth.

SELECT COUNT(*) AS matching_full_names
FROM recruitment_raw r
JOIN employee_raw e
    ON LOWER(TRIM(r.`First Name`)) = LOWER(TRIM(e.FirstName))
   AND LOWER(TRIM(r.`Last Name`)) = LOWER(TRIM(e.LastName));

SELECT COUNT(*) AS matching_full_name_and_dob
FROM recruitment_raw r
JOIN employee_raw e
    ON LOWER(TRIM(r.`First Name`)) = LOWER(TRIM(e.FirstName))
   AND LOWER(TRIM(r.`Last Name`)) = LOWER(TRIM(e.LastName))
   AND STR_TO_DATE(r.`Date of Birth`, '%d-%m-%Y')
       = STR_TO_DATE(e.DOB, '%d-%m-%Y');


-- ============================================================================
-- 17. RECRUITMENT: PHONE AND EMAIL QUALITY
-- Expected:
--   corrupted phone values = 400
--   unique emails = 2977
--   repeated email values beyond uniqueness = 23
-- ============================================================================

SELECT COUNT(*) AS corrupted_phones
FROM recruitment_raw
WHERE `Phone Number` REGEXP '^[#]+$';

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT Email) AS unique_emails,
    COUNT(*) - COUNT(DISTINCT Email) AS repeated_email_values
FROM recruitment_raw;


-- ============================================================================
-- 18. RECRUITMENT: GEOGRAPHIC CONSISTENCY
--
-- Key finding:
-- City, State, Zip Code and Country do not form a reliable geographic
-- hierarchy and should not be used for maps or location-based conclusions.
-- ============================================================================

SELECT
    COUNT(DISTINCT City) AS unique_cities,
    COUNT(DISTINCT State) AS unique_states,
    COUNT(DISTINCT `Zip Code`) AS unique_zip_codes,
    COUNT(DISTINCT Country) AS unique_countries,
    COUNT(DISTINCT CONCAT_WS('|', City, State, `Zip Code`, Country))
        AS unique_geo_combinations
FROM recruitment_raw;

SELECT COUNT(*) AS usa_rows
FROM recruitment_raw
WHERE Country = 'United States of America';

-- Examples of non-US countries paired with US-style state codes
SELECT
    Country,
    State,
    COUNT(*) AS rows_count
FROM recruitment_raw
WHERE Country <> 'United States of America'
GROUP BY Country, State
ORDER BY rows_count DESC
LIMIT 20;

-- Number of ZIP codes that appear more than once
-- Expected: 46
SELECT COUNT(*) AS repeated_zip_codes
FROM (
    SELECT `Zip Code`
    FROM recruitment_raw
    GROUP BY `Zip Code`
    HAVING COUNT(*) > 1
) x;

-- Repeated ZIP codes associated with inconsistent geography
-- Expected: all 46 repeated ZIP codes
SELECT COUNT(*) AS repeated_zip_codes_with_inconsistent_geography
FROM (
    SELECT `Zip Code`
    FROM recruitment_raw
    GROUP BY `Zip Code`
    HAVING COUNT(*) > 1
       AND (
            COUNT(DISTINCT City) > 1
            OR COUNT(DISTINCT State) > 1
            OR COUNT(DISTINCT Country) > 1
       )
) x;

-- Show examples of repeated ZIP codes with conflicting geography
SELECT
    `Zip Code`,
    City,
    State,
    Country
FROM recruitment_raw
WHERE `Zip Code` IN (
    SELECT `Zip Code`
    FROM recruitment_raw
    GROUP BY `Zip Code`
    HAVING COUNT(*) > 1
)
ORDER BY `Zip Code`, City;


-- ============================================================================
-- END OF DATA QUALITY AUDIT
--
-- Main analytical decisions derived from this audit:
--
-- 1. Preserve RAW source data unchanged.
-- 2. Clean Title and DepartmentType trailing spaces in Power Query.
-- 3. Do not use original EmployeeStatus as the primary exit indicator.
-- 4. Use ExitDate-derived HasExit / EmploymentStatus_Clean fields.
-- 5. Keep TerminationType for analysis; do not aggregate free-text
--    TerminationDescription.
-- 6. Flag, rather than delete, temporally invalid survey and training records.
-- 7. Do not join recruitment to employee using Applicant ID = EmpID.
-- 8. Do not use recruitment geography for maps or geographic conclusions.
-- 9. Treat age anomalies as potential outliers, not automatically as errors.
-- ============================================================================
