--*************************************************************************--
-- Title: Assignment06
-- Author: CWilliams
-- Desc: This file demonstrates how to use Views, Functions and Stored Procedures
--This file is not copy and paste of prior modules, instead each step is re-done as practice.
-- Change Log: When,Who,What
-- 2025-05-25,CWilliams,Created File
-- 2025-05-26,CWilliams, Created tables, added constraints and inserted data from Mods 1,2.
-- 2025-05-27,CWilliams, Created views.
-- 2025-05-28, CWilliams,Tested views, uploaded to GitHub.

--**************************************************************************--
Begin Try
	Use Master;
	If Exists(Select Name From SysDatabases Where Name = 'Assignment06DB_CWilliams')
	 Begin 
	  Alter Database [Assignment06DB_CWilliams] set Single_user With Rollback Immediate;
	  Drop Database Assignment06DB_CWilliams;
	 End
	Create Database Assignment06DB_CWilliams;
End Try
Begin Catch
	Print Error_Number();
End Catch
go
Use Assignment06DB_CWilliams;

-- Step 1 - Create Products, Inventory, Categories & Employees Tables (Module 01)

CREATE Table Categories
(CategoryID int Identity (1,1) NOT NULL,
CategoryName nvarchar(100) NOT NULL);
Go

CREATE Table Products
(ProductID int Identity (1,1) NOT NULL,
ProductName nvarchar(100) NOT NULL,
UnitPrice money NOT NULL,
CategoryID int NULL);
Go

CREATE Table Employees
(EmployeeID int Identity (1,1) NOT NULL,
EmployeeFirstName nvarchar(100) NOT NULL,
EmployeeLastName nvarchar(100) NOT NULL,
ManagerID int NULL);
Go

CREATE Table Inventories
(InventoryID int Identity (1,1) NOT NULL,
InventoryDate date NOT NULL,
EmployeeID int NOT NULL,
ProductID int NOT NULL,
Count int NOT NULL);
Go

-- Step 2 - Create Constraints (Module 02)

Begin  --Categories - Adds Primary Key and Unique Name constraints
	Alter Table Categories
	Add Constraint pkCategories
	Primary Key (CategoryID);

	Alter Table Categories
	Add Constraint ukCategories
	Unique (CategoryName);
End

Begin  --Products - Adds Primary Key, Unique Name, Foreign Key and Check UnitPrice >0 constraints
	Alter Table Products
	Add Constraint pkProducts
	Primary Key (ProductID);

	Alter Table Products
	Add Constraint ukProductName
	Unique (ProductName);

	Alter Table Products
	Add Constraint fkProductstoCategories
	Foreign Key (CategoryID) references Categories(CategoryID);

	Alter Table Products
	Add Constraint ckUnitPriceGreaterThan0
	Check (UnitPrice>=0);
End

Begin --Employees - Adds Primary Key and Foreign key constraints. References ManagerID as EmployeeID

	Alter table Employees
	Add Constraint pkEmployees
	Primary Key (EmployeeID);

	Alter table Employees
	Add Constraint fkEmployeestoManagers
	Foreign Key (ManagerID) references Employees(EmployeeID);
End
Go

Begin --Inventories - Adds Primary Key, Foreign Key, Check Count >0, and Default Date constraints
	Alter Table Inventories
 	Add Constraint pkInventories
  	Primary Key (InventoryId);   

	Alter Table Inventories
	Add Constraint fkInventoriestoProducts
	Foreign Key (ProductID) references Products(ProductID);

	Alter Table Inventories
	Add Constraint fkInventoriestoEmployees
	Foreign Key (EmployeeID) references Employees(EmployeeID);

	Alter Table Inventories
	Add Constraint ckInventoryCountGreaterThan0
	Check (Count >=0);
	
	Alter Table Inventories
	Add Constraint dfInventoryDate
	Default GetDate() for InventoryDate;

End

---Step 3 - Insert data into the tables from the Northwind database.

Insert into Categories
	(CategoryName)
	Select CategoryName 
	From Northwind.dbo.Categories
	Order by CategoryID;
Go

Insert into Products
	(ProductName, UnitPrice, CategoryID)
	Select ProductName, UnitPrice, CategoryID
	From Northwind.dbo.Products
	Order by ProductID
Go

Insert Into Employees
(EmployeeFirstName, EmployeeLastName, ManagerID)
Select E.FirstName, E.LastName, IsNull(E.ReportsTo, E.EmployeeID) 
 From Northwind.dbo.Employees as E
  Order By E.EmployeeID;
Go

Insert into Inventories
	(InventoryDate, EmployeeID, ProductID, Count)
	Select '20170101' as InventoryDate, 5 as EmployeeID, ProductID, UnitsInStock
	From Northwind.dbo.Products
Union
	Select '20170201' as InventoryDate, 7 as EmployeeID, ProductID, UnitsInStock+10
	From Northwind.dbo.Products
Union
	Select '20170301' as InventoryDate, 9 as EmployeeID, ProductID, UnitsInStock+20
	From Northwind.dbo.Products
Order by 1,2
Go


Select * from Products
Select * from Categories
Select * from Inventories
Select * from Employees


/********************************* Questions and Answers *********************************/
print 
'NOTES------------------------------------------------------------------------------------ 
 1) You can use any name you like for you views, but be descriptive and consistent
 2) You can use your working code from assignment 5 for much of this assignment
 3) You must use the BASIC views for each table after they are created in Question 1
------------------------------------------------------------------------------------------'

-- Question 1 (5% pts): How can you create BASIC views to show data from each table in the database.
-- NOTES: 1) Do not use a *, list out each column!
--        2) Create one view per table!
--		  3) Use SchemaBinding to protect the views from being orphaned!
Go

CREATE View vCategories  --Basic view with schema binding for Categories table
WITH SCHEMABINDING
As  
	Select CategoryID, CategoryName
	From dbo.Categories AS c;
Go
Select * from vCategories
Go

CREATE View vProducts  --Basic view with schema binding for Products table
WITH SCHEMABINDING
As  
	Select ProductID, ProductName,CategoryID, UnitPrice
	From dbo.Products AS p;
Go
Select * from vProducts
Go

Create View vEmployees  ---Basic view with schema binding for Employees table
WITH SCHEMABINDING
As
	Select EmployeeID, EmployeeFirstName, EmployeeLastName, ManagerID
	From dbo.Employees AS e;
Go
Select * from vEmployees
Go

CREATE View vInventories  --Basic view with schema binding for Inventories table
WITH SCHEMABINDING
As  
	Select InventoryID, InventoryDate, EmployeeID, ProductID, Count
	From dbo.Inventories AS i;
Go
Select * from vInventories
Go

-- Question 2 (5% pts): How can you set permissions, so that the public group CANNOT select data 
-- from each table, but can select data from each view?

Deny Select on Categories to Public;  --Public users now only have access to the views of tables	.
Deny Select on Products to Public;
Deny Select on Employees to Public;
Deny Select on Inventories to Public;
Go
Grant Select on vCategories to Public;
Grant Select on vProducts to Public;
Grant Select on vEmployees to Public;
Grant Select on vInventories to Public;
Go

-- Question 3 (10% pts): How can you create a view to show a list of Category and Product names, 
-- and the price of each product?
-- Order the result by the Category and Product!

Create 
View vProductsbyCategory
As
	Select Top 1000000    --select Top to get around the order by issues with views.
	c.CategoryName, 
	p.ProductName, 
	p.Unitprice
	FROM vCategories as c
	Join vProducts as p
	ON c.CategoryID = p.CategoryID
	ORDER BY 1,2,3;
Go
Select * from vProductsbyCategory
Go

-- Question 4 (10% pts): How can you create a view to show a list of Product names 
-- and Inventory Counts on each Inventory Date?
-- Order the results by the Product, Date, and Count!

CREATE View vInventoryCountsbyDate
AS
	Select TOP 1000000
	p.ProductName,
	i.InventoryDate,
	i.Count
	FROM vInventories as i
	Join vProducts as p
	ON i.ProductID = p.ProductID
	ORDER BY 1,2,3
	Go
	Select * from vInventoryCountsbyDate
	Go

-- Question 5 (10% pts): How can you create a view to show a list of Inventory Dates 
-- and the Employee that took the count?
-- Order the results by the Date and return only one row per date!

-- Here is are the rows selected from the view:

-- InventoryDate	EmployeeName
-- 2017-01-01	    Steven Buchanan
-- 2017-02-01	    Robert King
-- 2017-03-01	    Anne Dodsworth

CREATE View vEmployeeInventoryCountsbyDate   --View employee who counted inventory each month.
AS
	Select DISTINCT TOP 1000000
	i.InventoryDate,
	e.EmployeeFirstName + ' ' + e.EmployeeLastName as EmployeeName
	FROM vInventories as i
	Join vEmployees as e
	ON i.EmployeeID = e.EmployeeID
	Order by 1
	Go
	Select * from vEmployeeInventoryCountsbyDate
	Go

-- Question 6 (10% pts): How can you create a view show a list of Categories, Products, 
-- and the Inventory Date and Count of each product?
-- Order the results by the Category, Product, Date, and Count!

CREATE --drop
View vInventoryCountsbyDateProductCategory   --View to show the inventory counts by date, category, product.
AS
	Select TOP 1000000
	c.CategoryName,
	p.ProductName,
	i.InventoryDate,
	i.Count
	FROM vInventories as i
	Join vProducts as p
	ON i.ProductID = p.ProductID
	Join vCategories as c
	ON p.CategoryID = c.CategoryID
	Order by 1,2,3,4
	Go
	Select * from vInventoryCountsbyDateProductCategory
	Go


-- Question 7 (10% pts): How can you create a view to show a list of Categories, Products, 
-- the Inventory Date and Count of each product, and the EMPLOYEE who took the count?
-- Order the results by the Inventory Date, Category, Product and Employee!

CREATE --drop
View vInventoryCountsByProductEmployee   --View to show the inventory counts by date, category, product.
AS
	Select TOP 1000000
	c.CategoryName,
	p.ProductName,
	i.InventoryDate,
	i.Count,
	e.EmployeeFirstName + ' ' + e.EmployeeLastName as EmployeeName
	FROM vInventories as i
	Join vProducts as p
	ON i.ProductID = p.ProductID
	Join vCategories as c
	ON p.CategoryID = c.CategoryID
	Join vEmployees as e
	ON e.EmployeeID = i.EmployeeID
	Order by 3,1,2,4
	Go
	Select * from vInventoryCountsByProductEmployee
	Go


-- Question 8 (10% pts): How can you create a view to show a list of Categories, Products, 
-- the Inventory Date and Count of each product, and the Employee who took the count
-- for the Products 'Chai' and 'Chang'? 

CREATE --drop
View vInventoriesForChaiAndChangByEmployees   --View to show the inventory counts by date, category, for only Chai and Chang.
AS
	Select TOP 1000000
	c.CategoryName,
	p.ProductName,
	i.InventoryDate,
	i.Count,
	e.EmployeeFirstName + ' ' + e.EmployeeLastName as EmployeeName
	FROM vInventories as i
	Join vEmployees as e
	ON i.EmployeeID = e.EmployeeID
	Join vProducts as p
	ON i.ProductID = p.ProductID
	Join vCategories as c
	ON p.CategoryID = c.CategoryID
	WHERE p.ProductName IN ('Chai','Chang')
	Order by 3,1,2,4
	Go
	Select * from vInventoriesForChaiAndChangByEmployees
	Go

-- Question 9 (10% pts): How can you create a view to show a list of Employees and the Manager who manages them?
-- Order the results by the Manager's name!

Create --drop --This is a view to list the employees and their managers.
View vEmployeesbyManagers
	As
	SELECT TOP 1000000
	m.EmployeeFirstName+' '+ m.EmployeeLastName as Manager,
	e.EmployeeFirstName + ' ' + e.EmployeeLastName as EmployeeName
	FROM vEmployees as e, vEmployees as m
	WHERE e.ManagerID = m.EmployeeID
	Order by 1
	Go

	Select * from vEmployeesbyManagers

-- Question 10 (20% pts): How can you create one view to show all the data from all four 
-- BASIC Views? Also show the Employee's Manager Name and order the data by 
-- Category, Product, InventoryID, and Employee.

CREATE
View vInventoriesByProductsByCategoriesByEmployees   --View to show all basic data.
AS
	Select TOP 1000000
	c.CategoryID,
	c.CategoryName,
	p.ProductID,
	p.ProductName,
	p.UnitPrice,
	i.InventoryID,
	i.InventoryDate,
	i.Count,
	e.EmployeeID,
	e.EmployeeFirstName + ' ' + e.EmployeeLastName as EmployeeName,
	m.EmployeeFirstName+' '+ m.EmployeeLastName as Manager
	FROM vInventories as i
	Join vProducts as p ON i.ProductID = p.ProductID
	Join vCategories as c ON p.CategoryID = c.CategoryID
	Join vEmployees as e ON i.EmployeeID = e.EmployeeID
	Join vEmployees as m ON e.ManagerID = m.EmployeeID
	Order by c.CategoryID,p.ProductID,i.InventoryID,e.EmployeeID
	Go
	Select * from vInventoriesByProductsByCategoriesByEmployees
	Go

	   
-- Test your Views (NOTE: You must change the your view names to match what I have below!)
Print 'Note: You will get an error until the views are created!'
Select * From [dbo].[vCategories]
Select * From [dbo].[vProducts]
Select * From [dbo].[vInventories]
Select * From [dbo].[vEmployees]

Select * From [dbo].[vProductsbyCategory]
Select * From [dbo].[vInventoryCountsbyDate]
Select * From [dbo].[vEmployeeInventoryCountsbyDate]
Select * From [dbo].[vInventoryCountsbyDateProductCategory]
Select * From [dbo].[vInventoryCountsByProductEmployee]
Select * From [dbo].[vInventoriesForChaiAndChangByEmployees]
Select * From [dbo].[vEmployeesbyManagers]
Select * From [dbo].[vInventoriesByProductsByCategoriesByEmployees]

/***************************************************************************************/