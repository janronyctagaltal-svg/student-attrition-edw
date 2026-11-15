-- ============================================================================
-- Enterprise Data Warehouse: Analytical SQL Queries
-- Database: edw_student_progression
-- ============================================================================

USE edw_student_progression;


-- QUERY 1: Program-Level Attrition Analysis

SELECT 
    c.Course_Code,
    c.Daytime_Evening_Attendance,
    COUNT(f.Fact_ID) AS Total_Students,
    SUM(CASE WHEN s.Status_Description = 'Dropout' THEN 1 ELSE 0 END) AS Total_Dropouts,
    ROUND(SUM(CASE WHEN s.Status_Description = 'Dropout' THEN 1 ELSE 0 END) * 100.0 / COUNT(f.Fact_ID), 2) AS Attrition_Rate_Pct
FROM Fact_Student_Progression f
JOIN Dim_Course c ON f.Course_Key = c.Course_Key
JOIN Dim_Progression_Status s ON f.Status_Key = s.Status_Key
GROUP BY c.Course_Code, c.Daytime_Evening_Attendance
ORDER BY Attrition_Rate_Pct DESC;


-- QUERY 2: Financial Constraints & Tuition Debt Impact

SELECT 
    st.Debtor_Flag,
    st.Tuition_Fees_Up_To_Date_Flag,
    COUNT(f.Fact_ID) AS Total_Students,
    SUM(CASE WHEN s.Status_Description = 'Dropout' THEN 1 ELSE 0 END) AS Dropout_Count,
    ROUND(SUM(CASE WHEN s.Status_Description = 'Dropout' THEN 1 ELSE 0 END) * 100.0 / COUNT(f.Fact_ID), 2) AS Attrition_Rate_Pct
FROM Fact_Student_Progression f
JOIN Dim_Student st ON f.Student_Key = st.Student_Key
JOIN Dim_Progression_Status s ON f.Status_Key = s.Status_Key
GROUP BY st.Debtor_Flag, st.Tuition_Fees_Up_To_Date_Flag
ORDER BY Attrition_Rate_Pct DESC;


-- QUERY 3: First-Year Academic Bottleneck & Completion Ratios

SELECT 
    s.Status_Description,
    COUNT(f.Fact_ID) AS Student_Count,
    ROUND(AVG(f.Sem1_Approved_Units), 2) AS Avg_Sem1_Approved_Units,
    ROUND(AVG(f.Sem2_Approved_Units), 2) AS Avg_Sem2_Approved_Units,
    ROUND(AVG(f.Total_Approved_Units), 2) AS Avg_Total_Approved_Units,
    ROUND(AVG(f.Credit_Completion_Ratio), 4) AS Avg_Credit_Completion_Ratio
FROM Fact_Student_Progression f
JOIN Dim_Progression_Status s ON f.Status_Key = s.Status_Key
GROUP BY s.Status_Description, s.Status_Key
ORDER BY Avg_Credit_Completion_Ratio ASC;


-- QUERY 4: Scholarship Protection Effect

SELECT 
    st.Scholarship_Holder_Flag,
    COUNT(f.Fact_ID) AS Total_Students,
    SUM(CASE WHEN s.Status_Description = 'Graduate' THEN 1 ELSE 0 END) AS Total_Graduates,
    SUM(CASE WHEN s.Status_Description = 'Dropout' THEN 1 ELSE 0 END) AS Total_Dropouts,
    ROUND(SUM(CASE WHEN s.Status_Description = 'Graduate' THEN 1 ELSE 0 END) * 100.0 / COUNT(f.Fact_ID), 2) AS Graduation_Rate_Pct,
    ROUND(SUM(CASE WHEN s.Status_Description = 'Dropout' THEN 1 ELSE 0 END) * 100.0 / COUNT(f.Fact_ID), 2) AS Attrition_Rate_Pct
FROM Fact_Student_Progression f
JOIN Dim_Student st ON f.Student_Key = st.Student_Key
JOIN Dim_Progression_Status s ON f.Status_Key = s.Status_Key
GROUP BY st.Scholarship_Holder_Flag;


-- QUERY 5: Macroeconomic Pressure on Cohort Attrition

SELECT 
    t.Academic_Year,
    t.Unemployment_Rate,
    t.Inflation_Rate,
    t.GDP,
    COUNT(f.Fact_ID) AS Cohort_Size,
    SUM(CASE WHEN s.Status_Description = 'Dropout' THEN 1 ELSE 0 END) AS Total_Dropouts,
    ROUND(SUM(CASE WHEN s.Status_Description = 'Dropout' THEN 1 ELSE 0 END) * 100.0 / COUNT(f.Fact_ID), 2) AS Attrition_Rate_Pct
FROM Fact_Student_Progression f
JOIN Dim_Academic_Term t ON f.Term_Key = t.Term_Key
JOIN Dim_Progression_Status s ON f.Status_Key = s.Status_Key
GROUP BY t.Academic_Year, t.Unemployment_Rate, t.Inflation_Rate, t.GDP
ORDER BY t.Unemployment_Rate DESC;