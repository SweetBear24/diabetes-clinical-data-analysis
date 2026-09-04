-- ============================================================
-- FILE: 02_cohort_comparison.sql
-- PROJECT: Diabetes Clinical Risk Analysis
-- DESCRIPTION: Multivariate cohort profiling — comparing
--              clinical biomarkers between diabetic and
--              non-diabetic patient groups
-- TOOL: PostgreSQL
-- ============================================================


-- ------------------------------------------------------------
-- 1.4 Multivariate Cohort Comparison
-- Goal: quantify clinical divergence between healthy (0)
--       and diabetic (1) cohorts across key biomarkers
-- ------------------------------------------------------------

SELECT 
    diabetes,
    COUNT(*)                                                                          AS total_patients,
    ROUND(AVG(bmi)::numeric, 2)                                                      AS avg_bmi,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY bmi)::numeric, 2)             AS median_bmi,
    ROUND(AVG(blood_glucose_level)::numeric, 2)                                      AS avg_glucose,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY blood_glucose_level)::numeric, 2) AS median_glucose,
    ROUND(AVG(HbA1c_level)::numeric, 2)                                             AS avg_hba1c,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY HbA1c_level)::numeric, 2)    AS median_hba1c
FROM diabetes_prediction_dataset
GROUP BY diabetes;

-- Results:
-- Non-Diabetic (0): 91,500 patients
--   avg_bmi=26.89 | median_bmi=27.32 | avg_glucose=132.85
--   median_glucose=140.00 | avg_hba1c=5.40 | median_hba1c=5.80
--
-- Diabetic (1): 8,500 patients
--   avg_bmi=31.99 | median_bmi=29.97 | avg_glucose=194.09
--   median_glucose=160.00 | avg_hba1c=6.93 | median_hba1c=6.60
--
-- Key Findings:
--   HbA1c: +28.3% higher in diabetic cohort (6.93 vs 5.40)
--           breaches ADA diagnostic threshold of 6.5%
--   Blood Glucose: +46.1% higher (194.09 vs 132.85 mg/dL)
--           largest divergence — strongest acute biomarker
--   BMI: +19.0% higher (31.99 vs 26.89)
--           diabetic cohort crosses into Class I Obesity (>= 30)
