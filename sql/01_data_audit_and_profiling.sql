-- ============================================================
-- FILE: 01_data_audit_and_profiling.sql
-- PROJECT: Diabetes Clinical Risk Analysis
-- DESCRIPTION: Data quality audit, duplicate detection,
--              infant screening, and summary statistics
-- TOOL: PostgreSQL
-- ============================================================


-- ------------------------------------------------------------
-- 1.1 Duplicate Records Identification
-- Goal: detect exact multi-column duplicates that may indicate
--       data ingestion errors in the clinical registry
-- ------------------------------------------------------------

SELECT 
    gender, age, hypertension, heart_disease, 
    smoking_history, bmi, HbA1c_level, blood_glucose_level, diabetes,
    COUNT(*) AS duplicate_count
FROM diabetes_prediction_dataset
GROUP BY 
    gender, age, hypertension, heart_disease, 
    smoking_history, bmi, HbA1c_level, blood_glucose_level, diabetes
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

-- Result: 3,857 duplicate records (3.86% of total dataset)


-- ------------------------------------------------------------
-- 1.2 Infant Screening Control (age < 2)
-- Goal: isolate pediatric records to check whether infant BMI
--       metrics skew adult percentile calculations
-- ------------------------------------------------------------

SELECT 
    COUNT(*) AS total_infants,
    ROUND(AVG(bmi)::numeric, 2) AS avg_infant_bmi,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY bmi)::numeric, 2) AS median_infant_bmi
FROM diabetes_prediction_dataset
WHERE age < 2;

-- Result: 2,101 infants | Avg BMI: 17.97 | Median BMI: 17.09
-- Finding: infant metrics within normal pediatric range,
--           no significant skew introduced into adult calculations


-- ------------------------------------------------------------
-- 1.3 Parametric & Non-Parametric Summary Statistics
-- Goal: calculate min/mean/median/max for key clinical metrics
--       to detect distributional skewness and imputation artifacts
-- ------------------------------------------------------------

SELECT 
    'BMI' AS metric,
    ROUND(MIN(bmi)::numeric, 2) AS min_val,
    ROUND(AVG(bmi)::numeric, 2) AS avg_val,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY bmi)::numeric, 2) AS median_val,
    ROUND(MAX(bmi)::numeric, 2) AS max_val
FROM diabetes_prediction_dataset

UNION ALL

SELECT 
    'Blood Glucose Level' AS metric,
    ROUND(MIN(blood_glucose_level)::numeric, 2) AS min_val,
    ROUND(AVG(blood_glucose_level)::numeric, 2) AS avg_val,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY blood_glucose_level)::numeric, 2) AS median_val,
    ROUND(MAX(blood_glucose_level)::numeric, 2) AS max_val
FROM diabetes_prediction_dataset

UNION ALL

SELECT 
    'HbA1c Level' AS metric,
    ROUND(MIN(HbA1c_level)::numeric, 2) AS min_val,
    ROUND(AVG(HbA1c_level)::numeric, 2) AS avg_val,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY HbA1c_level)::numeric, 2) AS median_val,
    ROUND(MAX(HbA1c_level)::numeric, 2) AS max_val
FROM diabetes_prediction_dataset;

-- Results:
-- BMI:               min=10.01 | avg=27.32 | median=27.32 | max=95.69
-- Blood Glucose:     min=80.00 | avg=138.06| median=140.00 | max=300.00
-- HbA1c Level:       min=3.50  | avg=5.53  | median=5.80  | max=9.00
--
-- Key Finding: BMI mean = median (27.32) — strong indicator of
--              median imputation for missing values in raw dataset
