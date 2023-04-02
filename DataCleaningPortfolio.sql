
/*
Cleaning Data in SQL Queries
*/

select * from Nashville$


--------------------------------------------------------------------------------------------------------------------------

-- Standardize Date Format

select saledate, convert(date,saledate)
from Nashville$

update Nashville$ 
set saledate = convert(date,saledate)


-- If it doesn't Update properly

alter table nashville$ 
add SaleConvertedDate Date

update Nashville$ 
set SaleConvertedDate = convert(date,saledate)

select SaleConvertedDate
from nashville$


 --------------------------------------------------------------------------------------------------------------------------

-- Populate Property Address data

select propertyaddress
from nashville$

select a.parcelid, a.propertyaddress, b.parcelid, b.propertyaddress, isnull(a.propertyaddress, b.propertyaddress)
from nashville$ a 
join nashville$ b
  on a.parcelid=b.parcelid
  and a.uniqueid <> b.uniqueid
where a.propertyaddress is null

update a 
set propertyaddress = isnull(a.propertyaddress, b.propertyaddress)	
from nashville$ a 
join nashville$ b
  on a.parcelid=b.parcelid
  and a.uniqueid <> b.uniqueid
where a.propertyaddress is null

--------------------------------------------------------------------------------------------------------------------------

-- Breaking out Address into Individual Columns (Address, City, State)

select propertyaddress
from nashville$

select 
SUBSTRING(propertyaddress,1,15)
from nashville$

SELECT 
SUBSTRING (propertyaddress, 1, charindex(',',propertyaddress)) as address, charindex(',',propertyaddress)
from nashville$

--if we want to go one position behind the comma add -1
SELECT 
SUBSTRING (propertyaddress, 1, charindex(',',propertyaddress)-1) as address
from nashville$

SELECT 
SUBSTRING (propertyaddress, 1, charindex(',',propertyaddress)-1) as address,
SUBSTRING (propertyaddress, charindex(',',propertyaddress)+1,len(propertyaddress)) as city
from nashville$

alter table nashville$
add PropertySplitAddress nvarchar(50)

alter table nashville$
add PropertySplitCity nvarchar(50)

update nashville$
set PropertySplitAddress = SUBSTRING (propertyaddress, 1, charindex(',',propertyaddress)-1),
	PropertySplitCity = SUBSTRING (propertyaddress, charindex(',',propertyaddress)+1,len(propertyaddress))

select PropertySplitAddress,PropertySplitCity
from nashville$

--if its address.city parse will directly split the adress and city but since we have , as delimiter we need to replace it with . and then parsename
select 
parsename(replace(owneraddress,',','.'),1) 
from Nashville$

select 
parsename(replace(owneraddress,',','.'),3) ,
parsename(replace(owneraddress,',','.'),2) ,
parsename(replace(owneraddress,',','.'),1) 
from Nashville$


alter table nashville$
add OwnerSplitAddress nvarchar(50)

alter table nashville$
add OwnerSplitCity nvarchar(50)

alter table nashville$
add OwnerSplitState nvarchar(50)

update nashville$
set OwnerSplitAddress = parsename(replace(owneraddress,',','.'),3),
	OwnerSplitCity = parsename(replace(owneraddress,',','.'),2),
	OwnerSplitState =parsename(replace(owneraddress,',','.'),1) 

select OwnerSplitAddress,OwnerSplitCity,OwnerSplitState
from nashville$

--------------------------------------------------------------------------------------------------------------------------


-- Change Y and N to Yes and No in "Sold as Vacant" field


select distinct(SoldAsVacant),count(SoldAsVacant)
from Nashville$
group by SoldAsVacant
order by count(SoldAsVacant)

select SoldAsVacant,
case	
	when soldasvacant ='y' then 'Yes'
	when soldasvacant = 'N' then 'No'
	Else soldasvacant
	end
from Nashville$

update Nashville$
set soldasvacant = case	
	when soldasvacant ='y' then 'Yes'
	when soldasvacant = 'N' then 'No'
	Else soldasvacant
	end



-----------------------------------------------------------------------------------------------------------------------------------------------------------

-- Remove Duplicates

select *, 
	row_number() over (
		partition by parcelid,
					 propertyaddress,
					 saleprice,
					 saledate,
					 legalreference
					 order by 
						uniqueid
					 ) rownum					
from Nashville$
order by ParcelID

---- we cannot check where rownum>1.. so we have to create a cte. .we cannot use a order by clause in a view

with rownumCTE as 
(
select *, 
	row_number() over (
		partition by parcelid,
					 propertyaddress,
					 saleprice,
					 saledate,
					 legalreference
					 order by 
						uniqueid
					 ) rownum					
from Nashville$
--order by ParcelID
)
select * from rownumCTE
where rownum>1


---- deleting the duplicates 

with rownumCTE as 
(
select *, 
	row_number() over (
		partition by parcelid,
					 propertyaddress,
					 saleprice,
					 saledate,
					 legalreference
					 order by 
						uniqueid
					 ) rownum					
from Nashville$
--order by ParcelID
)
delete from rownumCTE
where rownum>1



---------------------------------------------------------------------------------------------------------

-- Delete Unused Columns

select owneraddress, taxdistrict, propertyaddress 
from nashville$

alter table nashville$
drop column owneraddress, taxdistrict, propertyaddress


















-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------

--- Importing Data using OPENROWSET and BULK INSERT	

--  More advanced and looks cooler, but have to configure server appropriately to do correctly
--  Wanted to provide this in case you wanted to try it


--sp_configure 'show advanced options', 1;
--RECONFIGURE;
--GO
--sp_configure 'Ad Hoc Distributed Queries', 1;
--RECONFIGURE;
--GO


--USE PortfolioProject 

--GO 

--EXEC master.dbo.sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'AllowInProcess', 1 

--GO 

--EXEC master.dbo.sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'DynamicParameters', 1 

--GO 


---- Using BULK INSERT

--USE PortfolioProject;
--GO
--BULK INSERT nashvilleHousing FROM 'C:\Temp\SQL Server Management Studio\Nashville Housing Data for Data Cleaning Project.csv'
--   WITH (
--      FIELDTERMINATOR = ',',
--      ROWTERMINATOR = '\n'
--);
--GO


---- Using OPENROWSET
--USE PortfolioProject;
--GO
--SELECT * INTO nashvilleHousing
--FROM OPENROWSET('Microsoft.ACE.OLEDB.12.0',
--    'Excel 12.0; Database=C:\Users\alexf\OneDrive\Documents\SQL Server Management Studio\Nashville Housing Data for Data Cleaning Project.csv', [Sheet1$]);
--GO
