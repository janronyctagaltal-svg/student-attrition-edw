USE edw_student_progression;

SELECT 
    f.Fact_ID, 
    f.Student_Key,
    st.Gender, st.Age_At_Enrollment, st.Marital_Status, st.Nacionality,
    st.Displaced_Flag, st.Educational_Special_Needs, st.Debtor_Flag,
    st.Tuition_Fees_Up_To_Date_Flag, st.Scholarship_Holder_Flag, st.International_Flag,
    st.Mother_Qualification, st.Father_Qualification, st.Mother_Occupation, st.Father_Occupation,
    c.Course_Code, c.Application_Mode, c.Application_Order, c.Daytime_Evening_Attendance,
    t.Academic_Year, t.Unemployment_Rate, t.Inflation_Rate, t.GDP,
    f.Previous_Qual_Grade, f.Admission_Grade,
    f.Sem1_Credited_Units, f.Sem1_Enrolled_Units, f.Sem1_Evaluations, f.Sem1_Approved_Units, f.Sem1_Grade,
    f.Sem2_Credited_Units, f.Sem2_Enrolled_Units, f.Sem2_Evaluations, f.Sem2_Approved_Units, f.Sem2_Grade,
    f.Total_Approved_Units, f.Credit_Completion_Ratio,
    s.Status_Description AS Target
FROM Fact_Student_Progression f
JOIN Dim_Student st ON f.Student_Key = st.Student_Key
JOIN Dim_Course c ON f.Course_Key = c.Course_Key
JOIN Dim_Academic_Term t ON f.Term_Key = t.Term_Key
JOIN Dim_Progression_Status s ON f.Status_Key = s.Status_Key;