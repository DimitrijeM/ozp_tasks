-- 1. Prikazati ime i prezime zaposlenog, kao i koliko je taj zaposleni odsustvovao sa posla zbog odmora
-- (VacationHours), zbog bolovanja (SickLeaveHours), i ukupno. Izračunati starost tog zaposlenog u
-- godinama i sortirati zaposlene po starosti. (1 p.)
select p.FirstName + ' ' + p.LastName as Name,
       year(current_timestamp) - year(BirthDate) as Age,
       sum(VacationHours) as VacationHoursSum, sum(SickLeaveHours) as SickLeaveHoursSum,
       sum(VacationHours)+sum(SickLeaveHours) as LeaveHoursSum
from HumanResources.Employee e
         inner join Person.Person p on (e.BusinessEntityID=p.BusinessEntityID)
group by p.FirstName + ' ' + p.LastName, year(current_timestamp) - year(BirthDate);


-- 2. Prikazati ime i prezime zaposlenog, njegovo odsustvovanje zbog odmora (VacationHours) i
-- bolovanja pojedinačno (SickLeaveHours) i njegov rang u ukupnom odsustvu (ako je najduže
-- odsustvovao rang je jedan, sledeći ima 2 itd.), kao i rang unutar tog organizacionog nivoa (kolona
-- OrganizationLevel). (1 p.)
select Person.FirstName + ' ' + Person.LastName as Name,
       sum(VacationHours) as VacationHoursSum, sum(SickLeaveHours) as SickLeaveHoursSum,
       rank() over ( order by sum(VacationHours)+sum(SickLeaveHours) desc) as LeavesRank,
       rank() over (  partition by Employee.OrganizationLevel order by sum(VacationHours)+sum(SickLeaveHours) desc) as OrgLevelLeavesRank
from HumanResources.Employee
         inner join Person.Person on (Employee.BusinessEntityID=Person.BusinessEntityID)
group by Person.FirstName + ' ' + Person.LastName, OrganizationLevel;


-- 3. Prikazati prosečnu prodaju (SubTotal), prosečni iznos poreza (TaxAmt) i prosečnu putarinu
-- (Freight) grupisane po danima u nedelji datuma narudžbine (OrderDate). Datum u nedelji treba da
-- bude prikazan kao tekstualni podatak (poželjno je da bude na engleskom jeziku), a ne kao broj. (1
-- p.)
select datename(weekday, OrderDate) as weekday,
       AVG(SubTotal) as SubTotalAvg, AVG(TaxAmt) as TaxAmtAvg, AVG(Freight) as FreightAvg
from Sales.SalesOrderHeader s
group by datename(weekday, OrderDate);

-- 4. Prikažite ime, srednje slovo i prezime zaposlenog (u jednoj koloni u formatu [Ime, S, Prezime]),
-- teritoriju, prosečnu prodaju (SubTotal), prosečan iznos poreza (TaxAmt) i prosečnu putarinu
-- (Freight) grupisane po zaposlenom i teritoriji, gde je putarina bila iznad prosečne putarine. (1 p.)

-- varijanta 1. grupisati samo prodaje gde je *pojedinacna* putarina veca od proseka
select '[' + p.FirstName + ', ' +  Left(MiddleName, 1) + ', ' + p.LastName + ']' as SalesPerson, t.Name as Teritory,
       AVG(SubTotal) as SubTotalAvg, AVG(TaxAmt) as TaxAmtAvg, AVG(Freight) as FreightAvg
from Sales.SalesOrderHeader s
         inner join Sales.SalesPerson sp on s.SalesPersonID=sp.BusinessEntityID
         inner join Person.Person p on sp.BusinessEntityID=p.BusinessEntityID
         inner join Sales.SalesTerritory t on s.TerritoryID = t.TerritoryID
where Freight > (select avg(Freight) from Sales.SalesOrderHeader s)
group by '[' + p.FirstName + ', ' +  Left(MiddleName, 1) + ', ' + p.LastName + ']', t.Name;


-- varijanta 2. prikazati samo prodaje gde je *prosecna* putarina prodavca veca od proseka
select '[' + p.FirstName + ', ' +  Left(MiddleName, 1) + ', ' + p.LastName + ']' as SalesPerson, t.Name as Teritory,
       AVG(SubTotal) as SubTotalAvg, AVG(TaxAmt) as TaxAmtAvg, AVG(Freight) as FreightAvg
from Sales.SalesOrderHeader s
         inner join Sales.SalesPerson sp on s.SalesPersonID=sp.BusinessEntityID
         inner join Person.Person p on sp.BusinessEntityID=p.BusinessEntityID
         inner join Sales.SalesTerritory t on s.TerritoryID = t.TerritoryID
group by '[' + p.FirstName + ', ' +  Left(MiddleName, 1) + ', ' + p.LastName + ']', t.Name
having(AVG(Freight) > (select avg(Freight) from Sales.SalesOrderHeader s));


-- 5. Prikazati prosečnu prodaju, prosečni iznos poreza, prosečnu putarinu organizovanih tako da se
-- prikazuju grupisanja po: 1) teritoriji prodaje, 2) teritoriji i provinciji, i 3) provinciji i državi.
-- Napomena: Rezultat upita treba da bude jedna tabela. (2 p.)

SELECT t.Name as TerritoryName, p.Name as ProvinceName, c.Name as CountryName,
       AVG(SubTotal) AS SubTotalAVG, AVG(TaxAmt) AS TaxAmtAVG, AVG(Freight) AS FreightAVG
FROM Sales.SalesOrderHeader
         inner join Sales.SalesTerritory t ON SalesOrderHeader.TerritoryID = t.TerritoryID
         inner join Person.StateProvince p on t.TerritoryID = p.TerritoryID
         inner join Person.CountryRegion c on p.CountryRegionCode = c.CountryRegionCode
GROUP BY grouping sets(t.Name, (t.Name, p.Name), (p.Name, c.Name));


-- 6. Prikazati zaposlene (ime, prezime i naziv radnog mesta) koje nisu imali ni prodaju, ni kupovinu. (2
-- p.)
select '[' + p.FirstName + ', ' +   p.LastName  + ', ' + e.JobTitle + ']' as SalesPerson
from Person.Person p
         inner join HumanResources.Employee e on p.BusinessEntityID=e.BusinessEntityID
         left join Sales.SalesOrderHeader soh on p.BusinessEntityID=soh.SalesPersonID
         left join Purchasing.PurchaseOrderHeader poh on p.BusinessEntityID=poh.VendorID
where soh.OrderDate is null and poh.OrderDate is null;


-- 7. Prikazati koliko različitih proizvoda je prodato po teritoriji. (1 p.)
select t.Name as TerritoryName, count(distinct(sod.ProductID)) ProductCount
from Sales.SalesOrderHeader soh
         inner join Sales.SalesOrderDetail sod on soh.SalesOrderID = sod.SalesOrderID
         inner join Sales.SalesTerritory t on soh.TerritoryID = t.TerritoryID
group by t.Name;
