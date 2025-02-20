create table layoffs_stadging like layoffs; -- creating a table like layoffs
insert layoffs_stadging 
select * from layoffs; -- adding the data from layoffs to layoffs_stadging
With dublicate_cte AS 
(
select *, row_number() over(
partition by company, location, industry, total_laid_off, percentage_laid_off, `date`, 
stage, country, funds_raised_millions) AS row_num
from layoffs_stadging
) 
-- this cte determining dublicates by using the function row_number combined with partition by
-- all columns so when we have the rownumber = 2 that means the entire row is a dublicate

-- Because we can't change data in cte, we will copy it's content into a new tabel then
-- delete all the dublicate rows with row_number >1

-- creating our new table
select * from dublicate_cte where row_num > 1;
CREATE TABLE `layoffs_stadging_copy` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `rowNum` int
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- inserting the data into it
Insert into layoffs_stadging_copy
select *, row_number() over(
partition by company, location, industry, total_laid_off, percentage_laid_off, `date`, 
stage, country, funds_raised_millions) AS row_num
from layoffs_stadging;

-- deleting the dublicates
delete from layoffs_stadging_copy where rowNum > 1;

-- STANDRIZATION
-- trimming the company column
UPDATE layoffs_stadging_copy SET company = trim(company);

-- this one to see all the column elements and if they need any fix
select distinct industry from layoffs_stadging_copy
order by industry;
-- Here I found that I have fileds called crypto and other ones called crypto currency so I want to make them all just crypto

update layoffs_stadging_copy set industry = 'Crypto'
where industry like 'crypto%';

select distinct country from layoffs_stadging_copy
order by country;
-- I found that unided states is repeated with a period so I want to merge it

-- this one removes the dot from united states
update layoffs_stadging_copy set country = trim(trailing '.' from country);

-- now we have to update the date column to be at the standard date format
-- note that the date in the parantheses is the same formate in the table and the function transfrom it into the
-- standerd format
update layoffs_stadging_copy SET `date` =str_to_date(`date`,'%m/%d/%Y');
select `date` from layoffs_stadging_copy;

-- now we transfrom the column from text format to the date format
Alter table layoffs_stadging_copy modify column `date` date;

-- here we make all blanc values to null to update them later
UPDATE layoffs_stadging_copy 
SET industry = NULL WHERE industry = '';

select distinct industry from layoffs_stadging_copy;

-- here we use self join to join the table with himself to comapre each row with the condition with every other row 
-- with the condition so we baiscly comparing the row with other rows of the same company then we copy the values
-- where it exist and paste it instead of null values
-- the entire opration to copy data from it's rows where it exists to null rows
UPDATE layoffs_stadging_copy tl
JOIN layoffs_stadging_copy t2
ON tl. company = t2.company
SET tl.industry = t2.industry
WHERE (tl.industry IS NULL
AND t2.industry IS NOT NULL);

-- next stage is for deleting rows that we don't need
SELECT *
FROM layoffs_stadging_copy
WHERE total_laid_off IS NULL
AND percentage_laid_off is NULL;

-- we deided that we don't need rows that has nulls in those two columns
DELETE
FROM layoffs_stadging_copy
WHERE total_laid_off IS NULL
AND percentage_laid_off is NULL;

-- THE LAST STEP IS TO REMOVE THE rowNum column because we don't need it in our data analysis
ALTER TABLE layoffs_stadging_copy
DROP COLUMN rowNum;

select * from layoffs_stadging_copy
-- Done :)