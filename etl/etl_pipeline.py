import pandas as pd
import numpy as np
from sqlalchemy import create_engine, text


# 1. DATABASE CONNECTION CONFIGURATION

DB_USER = "root"
DB_PASS = ""  # Replace with your MySQL password if set
DB_HOST = "127.0.0.1"
DB_PORT = "3306"
DB_NAME = "edw_student_progression"

# Create SQLAlchemy Database Engine
engine = create_engine(f"mysql+pymysql://{DB_USER}:{DB_PASS}@{DB_HOST}:{DB_PORT}/{DB_NAME}")

print("Connecting to MySQL Data Warehouse database...")

# Clear existing records before loading to prevent Primary Key duplicate errors
print("Clearing existing database tables for a clean ETL load...")
with engine.begin() as conn:
    conn.execute(text("SET FOREIGN_KEY_CHECKS = 0;"))
    conn.execute(text("TRUNCATE TABLE Fact_Student_Progression;"))
    conn.execute(text("TRUNCATE TABLE Dim_Student;"))
    conn.execute(text("TRUNCATE TABLE Dim_Course;"))
    conn.execute(text("TRUNCATE TABLE Dim_Academic_Term;"))
    conn.execute(text("TRUNCATE TABLE Dim_Progression_Status;"))
    conn.execute(text("SET FOREIGN_KEY_CHECKS = 1;"))


# 2. EXTRACT MULTIPLE DATA SOURCES (SOURCE A + SOURCE B)

SOURCE_A_PATH = "student_academic_records.csv"
SOURCE_B_PATH = "macroeconomic_lookup.csv"

print(f"Extracting Source A from '{SOURCE_A_PATH}'...")
df_student = pd.read_csv(SOURCE_A_PATH, sep=None, engine='python')

print(f"Extracting Source B from '{SOURCE_B_PATH}'...")
df_macro = pd.read_csv(SOURCE_B_PATH, sep=None, engine='python')

# Assign Term_ID dynamically across the 10 term periods (e.g., modulo mapping across 10 terms)
df_student['Term_ID'] = (df_student.index % len(df_macro)) + 1

# Relational Join: Merge Source A and Source B using Term_ID
print("Merging Source A and Source B on 'Term_ID'...")
df = df_student.merge(df_macro, on="Term_ID", how="left")

# Clean column headers
df.columns = df.columns.str.strip().str.replace('\t', '')
print(f"Successfully integrated {len(df)} records across all 37 attributes.")


# 3. SCHEMA MAPPING & COLUMN STANDARDIZATION

column_mapping = {
    # Demographics & Background
    'Marital status': 'Marital_Status',
    'Nacionality': 'Nacionality',
    'Displaced': 'Displaced_Flag',
    'Educational special needs': 'Educational_Special_Needs',
    'Debtor': 'Debtor_Flag',
    'Tuition fees up to date': 'Tuition_Fees_Up_To_Date_Flag',
    'Gender': 'Gender',
    'Scholarship holder': 'Scholarship_Holder_Flag',
    'Age at enrollment': 'Age_At_Enrollment',
    'International': 'International_Flag',
    "Mother's qualification": 'Mother_Qualification',
    "Father's qualification": 'Father_Qualification',
    "Mother's occupation": 'Mother_Occupation',
    "Father's occupation": 'Father_Occupation',
    'Previous qualification': 'Previous_Qualification',
    'Previous qualification (grade)': 'Previous_Qual_Grade',
    'Admission grade': 'Admission_Grade',

    # Course & Program attributes
    'Course': 'Course_Code',
    'Application mode': 'Application_Mode',
    'Application order': 'Application_Order',
    'Daytime/evening attendance': 'Daytime_Evening_Attendance',

    # Semester 1 Performance Metrics
    'Curricular units 1st sem (credited)': 'Sem1_Credited_Units',
    'Curricular units 1st sem (enrolled)': 'Sem1_Enrolled_Units',
    'Curricular units 1st sem (evaluations)': 'Sem1_Evaluations',
    'Curricular units 1st sem (approved)': 'Sem1_Approved_Units',
    'Curricular units 1st sem (grade)': 'Sem1_Grade',
    'Curricular units 1st sem (without evaluations)': 'Sem1_Without_Evaluations',

    # Semester 2 Performance Metrics
    'Curricular units 2nd sem (credited)': 'Sem2_Credited_Units',
    'Curricular units 2nd sem (enrolled)': 'Sem2_Enrolled_Units',
    'Curricular units 2nd sem (evaluations)': 'Sem2_Evaluations',
    'Curricular units 2nd sem (approved)': 'Sem2_Approved_Units',
    'Curricular units 2nd sem (grade)': 'Sem2_Grade',
    'Curricular units 2nd sem (without evaluations)': 'Sem2_Without_Evaluations',

    # Macroeconomic & Outcome Target
    'Unemployment rate': 'Unemployment_Rate',
    'Inflation rate': 'Inflation_Rate',
    'GDP': 'GDP',
    'Target': 'Status_Description'
}

# Rename dataset columns to match SQL EDW schema
df = df.rename(columns=column_mapping)

# Synthesize missing Academic_Year if omitted in raw dataset
if 'Academic_Year' not in df.columns:
    df['Academic_Year'] = '2021-2022'

# Map Status_Description to integer Status_Code
status_code_map = {'Dropout': 1, 'Enrolled': 2, 'Graduate': 3}
df['Status_Code'] = df['Status_Description'].map(status_code_map).fillna(0).astype(int)


# 4. TRANSFORM & LOAD DIMENSION TABLES


# --- A. Dim_Student ---
print("Transforming & Loading 'Dim_Student'...")
student_cols = [
    'Gender', 'Age_At_Enrollment', 'Marital_Status', 'Nacionality',
    'Displaced_Flag', 'Educational_Special_Needs', 'Debtor_Flag',
    'Tuition_Fees_Up_To_Date_Flag', 'Scholarship_Holder_Flag',
    'International_Flag', 'Mother_Qualification', 'Father_Qualification',
    'Mother_Occupation', 'Father_Occupation', 'Previous_Qualification'
]
dim_student = df[student_cols].drop_duplicates().reset_index(drop=True)
dim_student['Student_Key'] = dim_student.index + 1
dim_student = dim_student[['Student_Key'] + student_cols]
dim_student.to_sql('Dim_Student', engine, if_exists='append', index=False)
print(f" -> Inserted {len(dim_student)} records into Dim_Student.")

# --- B. Dim_Course ---
print("Transforming & Loading 'Dim_Course'...")
course_cols = ['Course_Code', 'Application_Mode', 'Application_Order', 'Daytime_Evening_Attendance']
dim_course = df[course_cols].drop_duplicates().reset_index(drop=True)
dim_course['Course_Key'] = dim_course.index + 1
dim_course = dim_course[['Course_Key'] + course_cols]
dim_course.to_sql('Dim_Course', engine, if_exists='append', index=False)
print(f" -> Inserted {len(dim_course)} records into Dim_Course.")

# --- C. Dim_Academic_Term ---
print("Transforming & Loading 'Dim_Academic_Term'...")
term_cols = ['Academic_Year', 'Unemployment_Rate', 'Inflation_Rate', 'GDP']
dim_term = df[term_cols].drop_duplicates().reset_index(drop=True)
dim_term['Term_Key'] = dim_term.index + 1
dim_term = dim_term[['Term_Key'] + term_cols]
dim_term.to_sql('Dim_Academic_Term', engine, if_exists='append', index=False)
print(f" -> Inserted {len(dim_term)} records into Dim_Academic_Term.")

# --- D. Dim_Progression_Status ---
print("Transforming & Loading 'Dim_Progression_Status'...")
status_cols = ['Status_Code', 'Status_Description']
dim_status = df[status_cols].drop_duplicates().reset_index(drop=True)
dim_status['Status_Key'] = dim_status.index + 1
dim_status = dim_status[['Status_Key'] + status_cols]
dim_status.to_sql('Dim_Progression_Status', engine, if_exists='append', index=False)
print(f" -> Inserted {len(dim_status)} records into Dim_Progression_Status.")


# 5. TRANSFORM & LOAD CENTRAL FACT TABLE

print("Mapping Foreign Keys & Calculating Metrics for 'Fact_Student_Progression'...")

# Merge dataset back with dimension lookup tables to assign Foreign Surrogate Keys
fact_df = df.merge(dim_student, on=student_cols) \
            .merge(dim_course, on=course_cols) \
            .merge(dim_term, on=term_cols) \
            .merge(dim_status, on=status_cols)

# Feature Engineering
fact_df['Total_Approved_Units'] = fact_df['Sem1_Approved_Units'] + fact_df['Sem2_Approved_Units']
total_enrolled = fact_df['Sem1_Enrolled_Units'] + fact_df['Sem2_Enrolled_Units']

# Calculate Credit Completion Ratio (handling division by zero)
fact_df['Credit_Completion_Ratio'] = np.where(
    total_enrolled > 0,
    (fact_df['Total_Approved_Units'] / total_enrolled).round(4),
    0.0
)

# Fact table column alignment
fact_columns = [
    'Student_Key', 'Course_Key', 'Term_Key', 'Status_Key',
    'Previous_Qual_Grade', 'Admission_Grade',
    'Sem1_Credited_Units', 'Sem1_Enrolled_Units', 'Sem1_Evaluations', 'Sem1_Approved_Units', 'Sem1_Grade', 'Sem1_Without_Evaluations',
    'Sem2_Credited_Units', 'Sem2_Enrolled_Units', 'Sem2_Evaluations', 'Sem2_Approved_Units', 'Sem2_Grade', 'Sem2_Without_Evaluations',
    'Total_Approved_Units', 'Credit_Completion_Ratio'
]

fact_final = fact_df[fact_columns]

print("Loading Fact_Student_Progression into Data Warehouse...")
fact_final.to_sql('Fact_Student_Progression', engine, if_exists='append', index=False)

print(f"SUCCESS: Loaded {len(fact_final)} records into Fact_Student_Progression!")
print("ETL Pipeline execution completed successfully. Your DW is ready for SQL queries.")
