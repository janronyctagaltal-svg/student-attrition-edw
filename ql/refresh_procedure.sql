-- Data Warehouse Maintenance: Incremental Data Reload & Refresh Procedure
-- Database: edw_student_progression
USE edw_student_progression;

DELIMITER //

CREATE PROCEDURE sp_RefreshStudentProgressionFact()
BEGIN
    -- 1. Temporary Staging Table for Refresh
    CREATE TEMPORARY TABLE IF NOT EXISTS Temp_Fact_Refresh AS 
    SELECT * FROM Fact_Student_Progression WHERE 1=0;

    -- 2. Recalculate Derived Metrics for Active Students
    UPDATE Fact_Student_Progression
    SET 
        Total_Approved_Units = Sem1_Approved_Units + Sem2_Approved_Units,
        Credit_Completion_Ratio = COALESCE(
            ROUND(
                (Sem1_Approved_Units + Sem2_Approved_Units) / 
                NULLIF((Sem1_Enrolled_Units + Sem2_Enrolled_Units), 0), 4
            ),
            0.0
        )
    WHERE Fact_ID > 0;

    -- 3. Log Refresh Execution
    SELECT 
        COUNT(*) AS Total_Records_Refreshed, 
        NOW() AS Refresh_Timestamp,
        'Fact_Student_Progression metrics successfully re-calculated and refreshed.' AS Status_Message
    FROM Fact_Student_Progression;

    DROP TEMPORARY TABLE IF EXISTS Temp_Fact_Refresh;
END //

DELIMITER ;

-- Execute the Data Reload/Refresh Procedure
CALL sp_RefreshStudentProgressionFact();