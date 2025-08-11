Select * from Pan_Number;
ALTER TABLE Pan_Number
ALTER COLUMN Pan_Numbers VARCHAR(50) COLLATE SQL_Latin1_General_CP1_CS_AS;



-- 1. Data Cleaning and Preprocessing:
--Identify and handle missing data:
Select * from Pan_Number
where Pan_numbers is null;

-- Check for duplicates:
Select Pan_Numbers from Pan_Number
group by Pan_Numbers
having count(*)>1;

--- Handle leading/trailing spaces: 
Select * from Pan_Number
Where Pan_Numbers <> Trim(Pan_Numbers);

--- Correct letter case:
Select * from Pan_Number
Where Pan_Numbers <> Upper(Pan_Numbers);

-----Cleaned Table
Create table cleaned_pan_number( Upper_Pan_Number nvarchar(50))
;
Insert into cleaned_pan_number (Upper_Pan_Number) 
select distinct Upper(trim(Pan_Numbers)) as Upper_Pan_No from Pan_Number
where pan_numbers is not null and trim(Pan_numbers)<>' ';

Select * from cleaned_pan_number;

---2. PAN Format Validation
--- It is exactly 10 characters long.

Select * from cleaned_pan_number
where Len(Upper_Pan_Number)='10';

---The first five characters should be alphabetic (uppercase letters).
--Adjacent characters(alphabets) cannot be the same (like AABCD is invalid; AXBCD is valid)
-- Adjacent characters(digits) cannot be the same (like 1123 is invalid; 1923 is valid)
--Fns to check adjacent characters are same - ZWDNW3493Z

CREATE OR ALTER FUNCTION dbo.fn_check_adj_char (@p_str NVARCHAR(MAX))
RETURNS BIT
AS
BEGIN
    DECLARE @i INT = 1;
    DECLARE @len INT = LEN(@p_str);

    WHILE @i < @len
    BEGIN
        IF SUBSTRING(@p_str, @i, 1) = SUBSTRING(@p_str, @i + 1, 1) ----Return 0 if  no adj duplicates character 
            RETURN 1; -- Adj duplicate character
			SET @i += 1;
    END

    RETURN 0; ---- no adj character
END;

Select dbo.fn_check_adj_char('AABCD')
Select dbo.fn_check_adj_char('AXBCD')
Select dbo.fn_check_adj_char('1123')
Select dbo.fn_check_adj_char('1923')

-----All five characters cannot form a sequence (like: ABCDE, BCDEF is invalid; ABCDX is valid)
-----All four characters cannot form a sequence (like: 1234, 2345)

CREATE OR ALTER FUNCTION dbo.fn_check_sequence_char (@p_str NVARCHAR(MAX))
Returns BIT
As
Begin
	Declare @i INT =1
	Declare @len INT = Len(@p_str)
	While @i < @len
		Begin
			if ascii(substring(@p_str,@i+1,1))-ascii(substring(@p_str,@i,1))<>1 --Return 1 if all consecutive character pairs have a difference of exactly 1
				Return 0;--not form a sequence
				Set @i += 1
		end
	Return 1 -- forms a sequence
end;
Select dbo.fn_check_sequence_char('ABCDE');
Select dbo.fn_check_sequence_char('ABCDX');
Select dbo.fn_check_sequence_char('1234');
Select dbo.fn_check_sequence_char('5319');

SELECT * 
FROM cleaned_pan_number
WHERE Upper_Pan_Number LIKE '[A-Z][A-Z][A-Z][A-Z][A-Z][0-9][0-9][0-9][0-9][A-Z]';


--- CATEGORIZATION

create or alter view vw_category_pans as 
with cte as ( select distinct Upper(trim(Pan_Numbers)) as Upper_Pan_Number from Pan_Number
where pan_numbers is not null and trim(Pan_numbers)<>' '),
cte_valid_pan as (SELECT * FROM cte
WHERE Upper_Pan_Number LIKE '[A-Z][A-Z][A-Z][A-Z][A-Z][0-9][0-9][0-9][0-9][A-Z]'
and dbo.fn_check_adj_char(Upper_Pan_Number)=0
and dbo.fn_check_sequence_char(substring(Upper_Pan_Number,1,5))=0
and dbo.fn_check_sequence_char(substring(Upper_Pan_Number,6,4))=0)
Select c.Upper_Pan_Number,case when v.Upper_Pan_Number is not null then 'Valid Pan' else 'Invalid Pan' end as status
from cte c left join cte_valid_pan v 
on c.Upper_Pan_Number=v.Upper_Pan_Number;


--Create a summary report
with cte as (Select (Select Count(*)  from Pan_Number) as  Total_records_processed,
sum (case when status='Valid Pan' then 1 else 0 end) as Total_Valid_pans,
sum (case when status='Invalid Pan' then 1 else 0 end) as Total_Invalid_pans from vw_category_pans
)
Select *,(Total_records_processed- Total_Valid_pans-Total_Invalid_Pans) as Missing_Pans from cte;