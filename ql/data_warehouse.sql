
-- CREATE AND SELECT DATA WAREHOUSE DATABASE
CREATE DATABASE IF NOT EXISTS edw_student_progression;
USE edw_student_progression;

-- DIMENSION TABLES (1-side of 1:N Relationships)
-- Dimension: Student Demographics and Socio-Economic Background
CREATE TABLE Dim_Student (
    Student_Key                  INT NOT NULL,
    Gender                       INT NULL,
    Age_At_Enrollment            INT NULL,
    Marital_Status               INT NULL,
    Nacionality                  INT NULL,
    Displaced_Flag               INT NULL,
    Educational_Special_Needs    INT NULL,
    Debtor_Flag                  INT NULL,
    Tuition_Fees_Up_To_Date_Flag INT NULL,
    Scholarship_Holder_Flag      INT NULL,
    International_Flag           INT NULL,
    Mother_Qualification         INT NULL,
    Father_Qualification         INT NULL,
    Mother_Occupation            INT NULL,
    Father_Occupation            INT NULL,
    Previous_Qualification       INT NULL,
    PRIMARY KEY (Student_Key)
);

-- Dimension: Degree Program & Application Entry
CREATE TABLE Dim_Course (
    Course_Key                 INT NOT NULL,
    Course_Code                INT NULL,
    Application_Mode           INT NULL,
    Application_Order          INT NULL,
    Daytime_Evening_Attendance INT NULL,
    PRIMARY KEY (Course_Key)
);

-- Dimension: Academic Term & Regional Macroeconomic Environment
CREATE TABLE Dim_Academic_Term (
    Term_Key          INT NOT NULL,
    Academic_Year     VARCHAR(20) NULL,
    Unemployment_Rate FLOAT NULL,
    Inflation_Rate    FLOAT NULL,
    GDP               FLOAT NULL,
    PRIMARY KEY (Term_Key)
);

-- Dimension: Outcome Lookup Status
CREATE TABLE Dim_Progression_Status (
    Status_Key         INT NOT NULL,
    Status_Code        INT NULL,
    Status_Description VARCHAR(50) NULL,
    PRIMARY KEY (Status_Key)
);

-- CENTRAL FACT TABLE (N-side of 1:N Relationships)


-- Fact: Academic Performance and Student Progression Tracking
CREATE TABLE Fact_Student_Progression (
    Fact_ID                   BIGINT NOT NULL AUTO_INCREMENT,
    
    -- Foreign Keys propagated from Dimension Tables
    Student_Key               INT NOT NULL,
    Course_Key                INT NOT NULL,
    Term_Key                  INT NOT NULL,
    Status_Key                INT NOT NULL,
    
    -- Quantitative Performance Metrics and Evaluations
    Previous_Qual_Grade       FLOAT NULL,
    Admission_Grade          FLOAT NULL,
    Sem1_Credited_Units       INT NULL,
    Sem1_Enrolled_Units       INT NULL,
    Sem1_Evaluations          INT NULL,
    Sem1_Approved_Units       INT NULL,
    Sem1_Grade                FLOAT NULL,
    Sem1_Without_Evaluations  INT NULL,
    Sem2_Credited_Units       INT NULL,
    Sem2_Enrolled_Units       INT NULL,
    Sem2_Evaluations          INT NULL,
    Sem2_Approved_Units       INT NULL,
    Sem2_Grade                FLOAT NULL,
    Sem2_Without_Evaluations  INT NULL,
    
    -- Derived Ratios and Feature Engineering Metrics
    Total_Approved_Units      INT NULL,
    Credit_Completion_Ratio   FLOAT NULL,
    
    -- Primary and Foreign Key Constraints
    PRIMARY KEY (Fact_ID),
    CONSTRAINT FK_Fact_Student FOREIGN KEY (Student_Key) REFERENCES Dim_Student(Student_Key),
    CONSTRAINT FK_Fact_Course  FOREIGN KEY (Course_Key)  REFERENCES Dim_Course(Course_Key),
    CONSTRAINT FK_Fact_Term    FOREIGN KEY (Term_Key)    REFERENCES Dim_Academic_Term(Term_Key),
    CONSTRAINT FK_Fact_Status  FOREIGN KEY (Status_Key)  REFERENCES Dim_Progression_Status(Status_Key)
);
