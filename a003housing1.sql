--Bringing date to date format
----(1)creating new column 'sales_date'
ALTER TABLE a003housing.dbo.housing
ADD sales_date date;
----(2)inserting dates in correct format
UPDATE a003housing.dbo.housing
SET sales_date = CONVERT(date, SaleDate)
----(3)checking if the insert was performed correctly
SELECT 
	SaleDate,
	sales_date
FROM a003housing.dbo.housing



--Populating empty property address entries

----(1)finding the empty entries and the data for populating them
SELECT 
	a.ParcelID,
	a.PropertyAddress,
	b.ParcelID,
	b.PropertyAddress,
	ISNULL(a.PropertyAddress,b.PropertyAddress) populate
FROM a003housing.dbo.housing a
JOIN a003housing.dbo.housing b
	ON a.ParcelID = b.ParcelID AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL

----(2)populating the empty entries
UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM a003housing.dbo.housing a
JOIN a003housing.dbo.housing b
	ON a.ParcelID = b.ParcelID AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL

----(3)checking if the operation was successful
SELECT * FROM a003housing.dbo.housing WHERE PropertyAddress IS NULL



--Splitting 'PropertyAddress' fields into separate fields (street address, city, state) using SUBSTRING

SELECT
	PropertyAddress
FROM a003housing.dbo.housing
ORDER BY ParcelID

SELECT
	SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress)-1) AS address,
	SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress)+2, LEN(PropertyAddress)) AS city
FROM a003housing.dbo.housing

----(1)creating new columns 'PropertyAddress_street', 'PropertyAddress_city'
ALTER TABLE a003housing.dbo.housing
ADD 
	PropertyAddress_street NVARCHAR(255),
	PropertyAddress_city NVARCHAR(255)

----(2)inserting relevant parts of addresses into appropriate fields
UPDATE a003housing.dbo.housing
SET
	PropertyAddress_street = SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress)-1),
	PropertyAddress_city = SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress)+2, LEN(PropertyAddress))

----(3)checking if the insert was performed correctly
SELECT 
	PropertyAddress,
	PropertyAddress_street,
	PropertyAddress_city
FROM a003housing.dbo.housing



--Splitting 'OwnerAddress' field
SELECT
	TRIM(PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)) AS OwnerAddress_street,
	TRIM(PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)) AS OwnerAddress_city,
	TRIM(PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)) AS OwnerAddress_state
FROM a003housing.dbo.housing

----(1)creating new columns 'OwnerAddress_street', 'OwnerAddress_city', 'OwnerAddress_state'
ALTER TABLE a003housing.dbo.housing
ADD 
	OwnerAddress_street NVARCHAR(255),
	OwnerAddress_city NVARCHAR(255),
	OwnerAddress_state NVARCHAR(255)

----(2)inserting relevant parts of OwnerAddresses into appropriate fields
UPDATE a003housing.dbo.housing
SET
	OwnerAddress_street = TRIM(PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)),
	OwnerAddress_city = TRIM(PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)),
	OwnerAddress_state = TRIM(PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1))

----(3)checking if the insert was performed correctly
SELECT 
	OwnerAddress,
	OwnerAddress_street,
	OwnerAddress_city,
	OwnerAddress_state
FROM a003housing.dbo.housing



--Changing Y/N to Yes/No in 'Sold as Vacant' field

----(1)checking values in the ofield
SELECT DISTINCT 
	SoldAsVacant,
	COUNT(SoldAsVacant)
FROM a003housing.dbo.housing
GROUP BY SoldAsVacant
ORDER BY SoldAsVacant

----(2)designing the replacement
SELECT
	SoldAsVacant,
	CASE
		WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
	END 
FROM a003housing.dbo.housing

----(3) making the replacement
UPDATE a003housing.dbo.housing
SET SoldAsVacant =
	CASE
		WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
	END 



--Removing duplicates

----(1)creating CTE
WITH RowNumCTE AS (
SELECT 
	ROW_NUMBER() OVER(PARTITION BY 
		ParcelID,
		PropertyAddress_street,
		PropertyAddress_city,
		SalePrice,
		sales_date,
		LegalReference
		ORDER BY UniqueID
		) row_num, *
FROM a003housing.dbo.housing
					)
SELECT *
FROM RowNumCTE 
WHERE row_num > 1
ORDER BY PropertyAddress_street

----(2)Deleting duplicate records
WITH RowNumCTE AS (
SELECT 
	ROW_NUMBER() OVER(PARTITION BY 
		ParcelID,
		PropertyAddress_street,
		PropertyAddress_city,
		SalePrice,
		sales_date,
		LegalReference
		ORDER BY UniqueID
		) row_num, *
FROM a003housing.dbo.housing
					)
DELETE
FROM RowNumCTE 
WHERE row_num > 1



--Removing unused fields
ALTER TABLE a003housing.dbo.housing
DROP COLUMN SaleDate, PropertyAddress, OwnerAddress