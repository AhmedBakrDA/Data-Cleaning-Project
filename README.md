# 🛠️ **Layoffs Data Cleaning Project**  

## 🔍 **Overview**  
This project demonstrates the step-by-step process of cleaning and standardizing data in a database. The dataset used here consists of layoffs information, and the goal is to remove duplicates, standardize text values, handle missing data, and format date fields to ensure high-quality, clean data for analysis.  

---

## 🚀 **Key Objectives**  
- Remove duplicate records to ensure data integrity.  
- Standardize column values (e.g., industry names, countries) for consistency.  
- Handle missing or blank values by filling or removing them.  
- Convert text-based date formats to a standardized `DATE` format for accurate analysis.  

---

## 🛠️ **Key SQL Steps**  

### 1. **Creating and Populating Tables**  
A new table is created to hold a staging copy of the layoffs data. Data is copied from the original table to the staging table for processing.  

```sql
CREATE TABLE layoffs_stadging LIKE layoffs; -- creating a table like layoffs
INSERT INTO layoffs_stadging SELECT * FROM layoffs; -- copying data into layoffs_stadging
```
### 2. **Removing Duplicates** 
We identify duplicate records using ROW_NUMBER by partitioning over all columns. Any row with row_num > 1 is considered a duplicate and removed.

```sql

WITH duplicate_cte AS 
(
  SELECT *, ROW_NUMBER() OVER (
    PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions
  ) AS row_num 
  FROM layoffs_stadging
)
SELECT * FROM duplicate_cte WHERE row_num > 1;

-- Creating a new table to store data without duplicates
CREATE TABLE layoffs_stadging_copy (
  company TEXT,
  location TEXT,
  industry TEXT,
  total_laid_off INT DEFAULT NULL,
  percentage_laid_off TEXT,
  date TEXT,
  stage TEXT,
  country TEXT,
  funds_raised_millions INT DEFAULT NULL,
  rowNum INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
```
## **Inserting cleaned data into the new table**
```sql
INSERT INTO layoffs_stadging_copy
SELECT *, ROW_NUMBER() OVER (
  PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions
) AS row_num
FROM layoffs_stadging;

-- Deleting duplicates with rowNum > 1
DELETE FROM layoffs_stadging_copy WHERE rowNum > 1;
```
## 3. **Standardizing Text Values**
Industry names and country names are cleaned for consistency. For example, "crypto currency" is renamed to "Crypto," and any trailing dots in country names are removed.

```sql
-- Trimming company names to remove unnecessary spaces
UPDATE layoffs_stadging_copy SET company = TRIM(company);

-- Standardizing industry names
UPDATE layoffs_stadging_copy SET industry = 'Crypto'
WHERE industry LIKE 'crypto%';

-- Removing dots from country names
UPDATE layoffs_stadging_copy SET country = TRIM(TRAILING '.' FROM country);
```
## 4. **Formatting Date Columns**
Dates stored as text are converted to the DATE format for proper sorting and filtering.

```sql

-- Converting date format from text to standard date format
UPDATE layoffs_stadging_copy SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

-- Changing the column type from text to date
ALTER TABLE layoffs_stadging_copy MODIFY COLUMN `date` DATE;
```
## 5. Handling Missing Data
Missing industry values are populated using self-joins to copy data from rows with the same company name. Rows with essential columns (total_laid_off, percentage_laid_off) missing are deleted.

```sql

-- Replacing blank industry values with NULL
UPDATE layoffs_stadging_copy SET industry = NULL WHERE industry = '';

-- Using self-join to fill missing industry values
UPDATE layoffs_stadging_copy tl
JOIN layoffs_stadging_copy t2
ON tl.company = t2.company
SET tl.industry = t2.industry
WHERE (tl.industry IS NULL AND t2.industry IS NOT NULL);

-- Deleting rows with NULL values in essential columns
DELETE FROM layoffs_stadging_copy
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;
```
## 6. **Final Cleaning**
The helper column rowNum is dropped from the table after all cleaning operations are completed.
```sql

-- Dropping the rowNum column
ALTER TABLE layoffs_stadging_copy DROP COLUMN rowNum;
```
