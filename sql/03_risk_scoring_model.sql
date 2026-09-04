-- ============================================================
-- FILE: 03_risk_scoring_model.sql
-- PROJECT: Diabetes Clinical Risk Analysis
-- DESCRIPTION: 4-tier patient risk stratification model
--              based on clinical thresholds (HbA1c, glucose, BMI)
--              to assist clinical triage and patient prioritization
-- TOOL: PostgreSQL
-- ============================================================


-- ------------------------------------------------------------
-- 1.5 Patient Risk Group Segmentation
-- Goal: classify all patients into 4 clinical risk tiers
--       using evidence-based thresholds and validate model
--       performance against actual diabetes diagnoses
--
-- Risk Tier Logic:
--   Tier 4 (High):     HbA1c >= 6.5% OR glucose >= 200 mg/dL
--   Tier 3 (Moderate): HbA1c 5.7-6.4% OR glucose 140-199 mg/dL
--   Tier 2 (Elevated): BMI >= 30 (obesity without glycemic flag)
--   Tier 1 (Low):      None of the above criteria met
-- ------------------------------------------------------------

SELECT 
    patient_risk_group,
    COUNT(*)                                                    AS patient_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2)        AS percentage_share,
    SUM(diabetes)                                               AS actual_diabetic_cases,
    ROUND(SUM(diabetes) * 100.0 / COUNT(*), 2)                AS diabetes_prevalence_pct
FROM (
    SELECT 
        diabetes,
        CASE 
            WHEN HbA1c_level >= 6.5 OR blood_glucose_level >= 200 
                THEN '4. High Risk / Diabetic'
            WHEN HbA1c_level BETWEEN 5.7 AND 6.4 OR blood_glucose_level BETWEEN 140 AND 199 
                THEN '3. Moderate Risk / Pre-diabetic'
            WHEN bmi >= 30 
                THEN '2. Elevated Risk / Obesity-Driven'
            ELSE '1. Low Risk / Normal'
        END AS patient_risk_group
    FROM diabetes_prediction_dataset
) sub
GROUP BY patient_risk_group
ORDER BY patient_risk_group ASC;

-- Results:
-- Tier 1 (Low Risk):      13,790 patients (13.79%) | 0 diabetic | 0.00%
-- Tier 2 (Elevated Risk):  3,706 patients ( 3.71%) | 0 diabetic | 0.00%
-- Tier 3 (Moderate Risk): 54,465 patients (54.47%) | 1,796 diabetic | 3.30%
-- Tier 4 (High Risk):     28,039 patients (28.04%) | 6,704 diabetic | 23.91%
--
-- Model Validation:
--   Zero False Negatives in Tiers 1 & 2:
--     No confirmed diabetic patient misclassified as low risk
--   Tiers 3 + 4 capture 100% of all 8,500 diabetic cases
--   Tier 4 alone captures 78.9% of all true positives (6,704 / 8,500)
