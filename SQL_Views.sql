
Use CollegeDB;

CREATE TABLE Students (
    student_id INT PRIMARY KEY,
    student_name VARCHAR(50),
    email VARCHAR(50),
    major VARCHAR(50),
    enrollment_year INT
);

-- Create Courses table
CREATE TABLE Courses (
    course_id INT PRIMARY KEY,
    course_name VARCHAR(50),
    credit_hours INT,
    department VARCHAR(50)
);

-- Create StudentCourses table for enrollment
CREATE TABLE StudentCourses (
    enrollment_id INT PRIMARY KEY,
    student_id INT,
    course_id INT,
    semester VARCHAR(20),
    grade CHAR(2),
    FOREIGN KEY (student_id) REFERENCES Students(student_id),
    FOREIGN KEY (course_id) REFERENCES Courses(course_id)
);

-- Insert sample data
INSERT INTO Students VALUES 
(1, 'John Doe', 'john@example.com', 'Computer Science', 2020),
(2, 'Jane Smith', 'jane@example.com', 'Mathematics', 2021),
(3, 'Mike Johnson', 'mike@example.com', 'Physics', 2020);

INSERT INTO Courses VALUES
(101, 'Database Systems', 3, 'CS'),
(102, 'Calculus II', 4, 'MATH'),
(103, 'Quantum Physics', 4, 'PHYSICS');

INSERT INTO StudentCourses VALUES
(1, 1, 101, 'Fall 2023', 'A'),
(2, 1, 102, 'Spring 2024', 'B'),
(3, 2, 102, 'Fall 2023', 'A'),
(4, 3, 103, 'Spring 2024', 'B+');

Select * FRom Students, Courses,StudentCourses;

--Simple View

CREATE VIEW CS_Students AS
SELECT student_id,student_name,email
FROM Students
WHERE major='Computer Science';

Select * from CS_Students; 

--Complex View from Multiple table with joins

Create View dbo.StudentEnrollments AS
SELECT s.student_name,c.course_name,sc.semester,sc.grade
From dbo.Students s
Inner join dbo.StudentCourses sc on s.student_id=sc.student_id
Inner join dbo.Courses c on sc.course_id=c.course_id;
select * from dbo.StudentEnrollments;

--Join and inner join they are exactly same, So inner is used for clarity
--updating and modifying views

SELECT * FROM dbo.StudentEnrollments;

SELECT TOP 3 * FROM dbo.CS_Students;
SELECT TOP 10 * FROM dbo.StudentEnrollments;

SELECt * from dbo.StudentEnrollments where grade='A';

--updating data throw a view

UPDATE StudentCourses
SET grade = 'A'
WHERE student_id = 3 AND course_id = 103;

select * from CS_Students;

BEGIN Transaction;
update dbo.CS_Students
set email='john_deo_university.edu'
where student_id=1;

--verifying the update operation
SELECT * from dbo.CS_Students where student_id=1;
Rollback Transaction --undoing the changes

--IRCTIC Servers,Instead of doing every small changes in my main system, we have views that works as data
--where we can make local changes and later on when they are permanent they are updated in the MAIN DB
---limitation wuth view:(V:IMP)

--attempting to update complex view using error handling(will fail)
BEGIN TRY
BEgin Transaction;
update dbo.StudentEnrollments
set  grade='A+'
where student_name='John Doe' AND course_name='Database System';
commit transaction;
end try
begin catch
rollback transaction;
print 'Error Occured..!!'+Error_message();
end catch;

--altering a view (MSSqL uses creatw or alter in newer version)
--for older versioons , we need to DROP and CREATE

if EXISTs (select * from sys.views where name='CS_Students' AND schema_id=SCHEMA_ID('dbo'))
drop view dbo.CS_Students;

--simple view
Create view dbo.CS_Students_New as
select student_id, student_name,email,enrollment_year
from dbo.Students
where major ='Computer SCience';

select*from dbo.CS_Students_New;

--view Metadata in MS SQL
--Get View Definition

Select OBJECT_DEFINITION(OBJECT_ID('dbo.CS_Students_New')) As ViewDefinition;

--List all view in the database

Select name as ViewName,Create_Date,modify_Date
from sys.views
where is_ms_shipped=0
order by name;

ALTER VIEW dbo.StudentEnrollments AS
SELECT 
    s.student_id,
    s.student_name,
    c.course_id,
    c.course_name,
    sc.semester,
    sc.grade
FROM dbo.Students s
INNER JOIN dbo.StudentCourses sc ON s.student_id = sc.student_id
INNER JOIN dbo.Courses c ON sc.course_id = c.course_id;
select * from dbo.StudentEnrollments;

select * from Students,Courses,StudentCourses;

--Indexing on above table for faster lookups

create NONCLUSTERED INDEX IX_STUDENT_EMAIL on Students(email);--student email

--composite non clustered index on major and enrollment year
CReate NONCLUSTERED INDEX IX_StudentMajor_Year On Students(major,enrollment_year);

--creating a unique Index on email to prevent duplicates
create unique INDEX UQ_Students_Email on Students(email) where email is not null;

--Create a non clustered Index on StudentCourses for common Query Patterns
Create NONCLUSTERED INDEX IX_STudentCourses_Grade on StudentCourses(semester,grade)

--Analysising Index Usage
--Checking existing indexes in my system

select
t.name as TableName,
i.name as IndexName,
i.type_desc as IndexType,
i.is_unique as IsUnique
from sys.indexes i
Inner join sys.tables t on i.object_id=t.object_id
where i.name is not null;

--sample query based on indexing

select*from Students where email='john_deo_university.edu';

--using composite index
select * from Students where major='Computer Science' and enrollment_year=2020;

--listing all the tables in the database

select * from sys.tables;
select * from sys.schemas;

--Most views in MYSQL server are read only by design? justify how?
--Only simple views meeting strict criteria can be update directly?how?

select * from CS_Students_New;--simple updatable view(meets all criteria)

Select * from StudentEnrollments;--view with join(not directly updatable))

select OBJECT_DEFINITION(OBJECT_ID('dbo.StudentEnrollments')) as ViewDefinition;

--View with distinct(not updatable)
select * from CS_Students_New;--simple update view(Meets all criteria)
select * from StudentEnrollments;--View with join(not directly updatable)
select OBJECT_DEFINITION(OBJECT_ID('dbo.StudentEntrollmentS') ) AS VIEWDEFINATION;

SELECT OBJECT_DEFINITION(OBJECT_ID('DBO.StudentEnrollments')) AS ViewDefinition;

-- View with DISTINCT(not updatable)
CREATE VIEW UniqueMajors AS
SELECT DISTINCT major FROM Students;
SELECT * FROM UniqueMajors;

-- Below operatioj is failing because 
-- DISTINCT create a derived result set
-- SQL SERVER can't map updates back to the base table 
BEGIN TRY 
	PRINT 'Attempting to update DISTINCT view..'
	UPDATE UniqueMajors
	SET major = 'Computer Sciences'
	Where Major = 'Computer Science'
END TRY

BEGIN CATCH
	PRINT 'update failed(as Expected)';
	PRINT 'ERROR: ' +ERROR_MESSAGE();
END CATCH;


-- View with computed column ( non updatable)
Create VIEW StudentNameLengths1 AS
SELECT student_id,student_name, LEN(student_name) AS name_length
FROM Students;
SELECT * FROM StudentNameLengths;
SELECT * FROM StudentNameLengths1;


-- Thi will fail because :
-- Contain a derived column( name_length)
-- SQL Server can't update calculated values 

BEGIN TRY
	PRINT'Attempting to updated computed column';
	UPDATE StudentNameLengths
	SET student_name = 'John Travolta'
	Where name_length = 6;
END TRY

BEGIN CATCH
	PRINT 'Update Failed( a expected)';
	PRINT 'Error' + Error_Message();
END CATCH;