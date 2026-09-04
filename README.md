# 🏥 Diabetes Clinical Risk Analysis
### SQL-Powered Patient Risk Stratification | PostgreSQL + Tableau

---

## 📋 Table of Contents
1. [Project Overview](#project-overview)
2. [Dataset](#dataset)
3. [Project Structure](#project-structure)
4. [Data Quality Audit & Artifact Detection](#data-quality-audit)
5. [Cohort Analysis: Healthy vs Diabetic](#cohort-analysis)
6. [Patient Risk Scoring & Stratification Model](#risk-model)
7. [How to Reproduce & Run](#how-to-run)

---

## 🎯 Project Overview

This project applies SQL-driven clinical analytics to a 100,000-patient diabetes dataset. The pipeline covers data quality auditing, multivariate cohort profiling, and a 4-tier patient risk stratification model — designed to assist clinical teams in prioritizing patient follow-ups.

**Core Business Question:** Who is at risk of diabetes, and how can we stratify patients by clinical risk tier?

---

## 📊 Dataset

| Parameter | Value |
|---|---|
| **Source** | [Diabetes Prediction Dataset — Kaggle](https://www.kaggle.com/datasets/iammustafatz/diabetes-prediction-dataset) |
| **Rows** | 100,000 patients |
| **Columns** | 9 |
| **Tool** | PostgreSQL |

| Column | Description |
|---|---|
| `gender` | Patient gender |
| `age` | Age in years |
| `hypertension` | Hypertension flag (0/1) |
| `heart_disease` | Heart disease flag (0/1) |
| `smoking_history` | Smoking history category |
| `bmi` | Body Mass Index |
| `HbA1c_level` | Glycated haemoglobin level (%) |
| `blood_glucose_level` | Fasting blood glucose (mg/dL) |
| `diabetes` | Diabetes diagnosis — target variable (0/1) |

---

## 📁 Project Structure

```
diabetes-clinical-risk-analysis/
│
├── sql/
│   ├── 01_data_audit_and_profiling.sql
│   ├── 02_cohort_comparison.sql
│   └── 03_risk_scoring_model.sql
│
├── images/
│   ├── duplicates_audit.png
│   ├── bmi_distribution.png
│   ├── bmi_distribution_log.png
│   ├── hba1c_distribution.png
│   ├── glucose_distribution.png
│   ├── cohort_comparison.png
│   └── risk_stratification.png
│
├── data/
│   └── sample_diabetes_dataset.csv
│
└── README.md
```

---

## 🔍 Data Quality Audit & Artifact Detection

### 4.1 Exact Duplicates Audit (SQL 1.1)

An exact multi-column row audit revealed duplicate patient records. In clinical registries, identical demographic and biometric profiles (identical age, gender, BMI, HbA1c, glucose, and medical history) indicate duplicate transmission during data ingestion.

```sql
-- 1.1 Duplicate Records Identification
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
```

![Data Quality & Duplicates Audit](images/duplicates_audit.png)
> 96.14% of records are clean (96,143 unique) · 3.86% are duplicates (3,857 records)

---

### 4.2 Infant Subgroup Screening — age < 2 (SQL 1.2)

To ensure pediatric physiological metrics do not skew overall adult percentile calculations, an isolated screening was performed for infants under 2 years old.

```sql
-- 1.2 Infant Screening Control (age < 2)
SELECT 
    COUNT(*) AS total_infants,
    ROUND(AVG(bmi)::numeric, 2) AS avg_infant_bmi,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY bmi)::numeric, 2) AS median_infant_bmi
FROM diabetes_prediction_dataset
WHERE age < 2;
```

| Total Infants | Avg Infant BMI | Median Infant BMI |
|---|---|---|
| 2,101 | 17.97 | 17.09 |

> **Analytical Finding:** Infant BMI metrics (Mean = 17.97 kg/m²) remain within expected pediatric growth curves and do not introduce severe skewness into adult obesity metrics.

---

### 4.3 Summary Statistics & Imputation Artifact Detection (SQL 1.3)

Both parametric (AVG) and non-parametric (MEDIAN via PERCENTILE_CONT) aggregates were calculated to detect distributional skewness and data artifacts.

```sql
-- 1.3 Parametric & Non-Parametric Summary Statistics
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
```

**Statistical Baseline Table:**

| Metric | Minimum | Mean | Median | Maximum | Artifact Note |
|---|---|---|---|---|---|
| BMI (kg/m²) | 10.01 | 27.32 | 27.32 | 95.69 | Synthetic cluster at 27.32 (Median Imputation) |
| HbA1c Level (%) | 3.50 | 5.53 | 5.80 | 9.00 | Concentrated at clinical testing intervals |
| Blood Glucose (mg/dL) | 80.00 | 138.06 | 140.00 | 300.00 | Discrete clinical measurement bands |

> **Analytical Finding:** The identical Mean and Median values for BMI (27.32) reveal that missing BMI entries in the raw dataset were imputed using the dataset median. A logarithmic scale was applied in Tableau to make this artifact visible.

**BMI Distribution (linear scale):**
![BMI Distribution](images/bmi_distribution.png)
> 🟢 Green = Normal/Overweight (BMI < 30) · 🟠 Orange = Obesity (BMI ≥ 30)

**BMI Distribution (log scale — reveals imputation spike at 27.32):**
![BMI Distribution Log Scale](images/bmi_distribution_log.png)
> The dark spike at BMI = 27.32 confirms median imputation artifact — 33,884 patients clustered at exactly the same value

**HbA1c Level Distribution:**
![HbA1c Distribution](images/hba1c_distribution.png)
> Bimodal distribution — concentration at 6.0–6.5% confirms the ADA pre-diabetic diagnostic band

**Blood Glucose Level Distribution:**
![Blood Glucose Distribution](images/glucose_distribution.png)
> Discrete measurement bands (80–160 mg/dL normal range, 200+ mg/dL diabetic range) confirm clinical testing protocols

---

## 📊 Cohort Analysis: Healthy vs Diabetic

Multivariate profiling was executed to evaluate clinical divergence across healthy (diabetes = 0) and diabetic (diabetes = 1) cohorts.

```sql
-- 1.4 Multivariate Cohort Comparison
SELECT 
    diabetes,
    COUNT(*) AS total_patients,
    ROUND(AVG(bmi)::numeric, 2) AS avg_bmi,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY bmi)::numeric, 2) AS median_bmi,
    ROUND(AVG(blood_glucose_level)::numeric, 2) AS avg_glucose,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY blood_glucose_level)::numeric, 2) AS median_glucose,
    ROUND(AVG(HbA1c_level)::numeric, 2) AS avg_hba1c,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY HbA1c_level)::numeric, 2) AS median_hba1c
FROM diabetes_prediction_dataset
GROUP BY diabetes;
```

**Cohort Biomarker Comparison Table:**

| Metric | Non-Diabetic (0) | Diabetic (1) | Delta (%) | Clinical Implication |
|---|---|---|---|---|
| Patient Population | 91,500 (91.5%) | 8,500 (8.5%) | — | Base dataset prevalence rate: 8.5% |
| Mean HbA1c (%) | 5.40% | 6.93% | +28.3% | Exceeds ADA diagnostic threshold (≥ 6.5%) |
| Median HbA1c (%) | 5.80% | 6.60% | +13.8% | Confirms sustained glycemic elevation |
| Mean Blood Glucose (mg/dL) | 132.85 | 194.09 | +46.1% | Pronounced acute fasting hyperglycemia |
| Median Blood Glucose (mg/dL) | 140.00 | 160.00 | +14.3% | Shift toward upper clinical diagnostic boundaries |
| Mean BMI (kg/m²) | 26.89 | 31.99 | +19.0% | Diabetic cohort shifts into Class I Obesity (≥ 30.0) |
| Median BMI (kg/m²) | 27.32 | 29.97 | +9.7% | Confirms obesity co-factor in diabetic cohort |

![Cohort Comparison](images/cohort_comparison.png)
> HbA1c: 5.4% (healthy) vs 6.9% (diabetic) · Blood Glucose: 132.9 vs 194.1 mg/dL · BMI: 26.9 vs 32.0

**Key Clinical Insights:**

- **HbA1c Threshold Breach:** Diabetic patients exhibit a mean HbA1c of 6.93%, breaching the ADA diagnostic threshold of 6.5%, whereas healthy patients remain well within normal limits (5.40%)
- **Acute Hyperglycemia:** Fasting blood glucose demonstrates the largest mean divergence — +46.1% (194.09 vs 132.85 mg/dL), confirming glucose as the most immediate acute biomarker
- **Obesity Co-factor:** Mean BMI shifts from overweight status (26.89 kg/m²) in healthy individuals to Class I Obesity (31.99 kg/m²) in diabetic patients, underscoring metabolic syndrome coupling

---

## 🎯 Patient Risk Scoring & Stratification Model

To assist clinical teams in prioritizing patient follow-ups, a 4-tier risk stratification query was implemented in SQL, relying on clinical risk triggers.

```sql
-- 1.5 Patient Risk Group Segmentation Query
SELECT 
    patient_risk_group,
    COUNT(*) AS patient_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS percentage_share,
    SUM(diabetes) AS actual_diabetic_cases,
    ROUND(SUM(diabetes) * 100.0 / COUNT(*), 2) AS diabetes_prevalence_pct
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
```

**Risk Stratification Performance Summary:**

| Risk Tier | Total Cohort Share | Total Patients | Actual Diabetic Cases | Tier Prevalence | Model Safety |
|---|---|---|---|---|---|
| 1. Low Risk / Normal | 13.79% | 13,790 | 0 | 0.00% | 100% Specificity (0 False Negatives) |
| 2. Elevated Risk / Obesity-Driven | 3.71% | 3,706 | 0 | 0.00% | Isolated obesity without glycemic elevation |
| 3. Moderate Risk / Pre-diabetic | 54.47% | 54,465 | 1,796 | 3.30% | Captures early pre-diabetic manifestation |
| 4. High Risk / Diabetic | 28.04% | 28,039 | 6,704 | 23.91% | Captures 78.9% of all true positives |

![Risk Scoring & Stratification](images/risk_stratification.png)
> 🔴 Red = Diabetic · ⬜ Grey = Non-Diabetic · Tiers 1 & 2: zero false negatives

**Model Validation Insights:**

- **Zero False Negatives in Tiers 1 & 2:** The model achieves complete safety for baseline patient screening — zero confirmed diabetic patients are misclassified into the Low or Elevated Risk categories
- **Effective Triage Isolation:** Tiers 3 and 4 together isolate 100% of all diagnosed diabetic cases (8,500 out of 8,500), concentrating clinical attention on the top 82.5% of screened individuals

---

## 🚀 How to Reproduce & Run

### Step 1: Clone Repository

```bash
git clone https://github.com/your-username/diabetes-clinical-risk-analysis.git
cd diabetes-clinical-risk-analysis
```

### Step 2: Database Initialization (PostgreSQL)

```sql
CREATE DATABASE clinical_analytics;
```

Import dataset from `data/sample_diabetes_dataset.csv` into table `diabetes_prediction_dataset`.

### Step 3: Execute SQL Analytics Pipelines

```bash
psql -d clinical_analytics -f sql/01_data_audit_and_profiling.sql
psql -d clinical_analytics -f sql/02_cohort_comparison.sql
psql -d clinical_analytics -f sql/03_risk_scoring_model.sql
```

### Step 4: Open Tableau Dashboard

1. Launch Tableau Desktop or Tableau Reader
2. Open `tableau/clinical_diabetes_dashboard.twbx`
3. If connecting to a live PostgreSQL instance, edit the Data Source connection parameters

---

## 🛠 Stack

![PostgreSQL](https://img.shields.io/badge/PostgreSQL-316192?style=flat&logo=postgresql&logoColor=white)
![SQL](https://img.shields.io/badge/SQL-4479A1?style=flat&logo=mysql&logoColor=white)
![Tableau](https://img.shields.io/badge/Tableau-E97627?style=flat&logo=tableau&logoColor=white)

---

## 👤 Author

**[Твоё имя]**  
Data Analyst Intern  
[LinkedIn](#) · [GitHub](#) · [Tableau Public](#)

---

*Project completed as part of SQL learning path — Alan Beaulieu "Learning SQL"*
