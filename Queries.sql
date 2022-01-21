SELECT distinct U.FirstName  , U.LastName	
FROM Composers AS c JOIN Users AS U ON 
c.Email = U.Email JOIN Recipes AS RE ON 
Re. UploadedBy = c.Email JOIN Ranking AS RA ON 
RA. RecipeName = RE. RecipeName
WHERE YEAR([DateOfRegistration])>2018
GROUP BY U.FirstName , U.LastName , RA. RecipeName 
HAVING  avg (score)>3


go

SELECT distinct R.RecipeName
FROM Recipes AS R JOIN RecipeSpecialDiet AS RS ON 
R.RecipeName = RS.RecipeName JOIN Contain AS C  ON 
R.RecipeName = C.RecipeName
Where R.season = 'summer' AND RS.specialDiet = 'kosher'
GROUP BY R.RecipeName
HAVING count(*)>=5


go

select r.RecipeName, AverageScore =  avg (score)  , recipeComposer =  U.FirstName + ' ' + U.LastName , R.UploadDate
from Recipes as r join Ranking as ra on ra.RecipeName=r.RecipeName        join Users as u on u.Email = r.UploadedBy
WHERE R.UploadDate > GETDATE() - 730 
group by r.RecipeName, U.FirstName , U.LastName, R.UploadDate
having avg (score) > (select AVG (score)
                      from  Ranking)
       and count (score) > 3


	   go

	   SELECT	 u.FirstName, u.LastName, salary
FROM	Composers as C join users as U on c.Email = u.Email join
		(select top 5 r.UploadedBy,  avrageScore = avg(score)
from Recipes as R join Ranking as Ran on r.RecipeName =         ran.RecipeName
		 group by r.UploadedBy
 order by 2 DESC ) as newTable on C.Email =            newTable.UploadedBy 
where salary < (select avg(salary)
			from Composers)


			go

alter table Ingredients
add CaloriesWarning VARCHAR(100)

update Ingredients
set CaloriesWarning = 'high calorie'
WHERE NumOfCalories > (SELECT avg(NumOfCalories)
				 FROM Ingredients)

go

(SELECT I.IngredientName
FROM Ingredients as I
where year(ExpressionDate) = 2019 and
      MONTH(ExpressionDate) < 9 and
      MONTH(ExpressionDate) > 5)

Intersect

(SELECT O.IngredientName
FROM Offer as O
group by  o.IngredientName, o.Price
having avg(o.Price) > (select avg(Price)
from Offer )
)


go

CREATE VIEW view_ShowPublicProfile 
AS
select U.FirstName, U.LastName, u.country, u.Gender, u.DateOfBirth, u.About,  U.Email , u.DateOfRegistration
from Users as U
except
select U.FirstName, U.LastName, u.country, u.Gender, u.DateOfBirth, u.About,  U.Email , u.DateOfRegistration
from Users as U join Composers as c on u.Email = c.Email


go

CREATE FUNCTION dbo.YearDidntProvidesNothing (@year int)
   	RETURNS TABLE
   	AS RETURN

   	(SELECT SupplierName
   	FROM Suppliers

	Except

	SELECT ProvidedBy
   	FROM Purchases as p
   	WHERE YEAR([DateOfPurchase])= @year
   	Group by p.ProvidedBy
	)


go

CREATE FUNCTION dbo.userTotalSpent (@Email varchar(30))
   	RETURNS TABLE
   	AS RETURN
   	(
	select  moneySpend = SUM(t2.toCost)
	from   (select  t.NumOfPurchase,toCost = sum(t.totalcost)
  from (SELECT b.NumOfPurchase, totalcost =    (			   B.Quantity*o.Price)
FROM Buys as B join Purchases as p on      b.NumOfPurchase = p.NumOfPurchase join Offer as o on o.SupplierName = p.ProvidedBy
Where b.IngredientName = o.IngredientName  and  p.MadeBy = @Email
		       ) as t
		  group by  t.NumOfPurchase 
		 ) as t2

go

CREATE TRIGGER UploadRecipes 
	ON Recipes
	FOR INSERT
	AS
 
	UPDATE  Composers
	SET numOfRecipes = numOfRecipes + (SELECT COUNT(*)
							  FROM INSERTED
WHERE INSERTED.UploadedBy =      Composers.Email)
 
	UPDATE Composers
	SET LastUploadeDate =ISNULL ((SELECT [UploadDate]
						   FROM INSERTED
WHERE INSERTED.UploadDate =                             Composers.Email),
   LastUploadeDate)

go

CREATE PROCEDURE UpdatePrice
	@ingredientName	 varchar(20), @supplierName varchar(30),	@Action Varchar(10), @Rate Real
AS
IF ( @Action = 'raise' ) BEGIN
					UPDATE Offer
					SET Price = (1 + @Rate)*Price
WHERE SupplierName = @supplierName and IngredientName = @ingredientName
		              END
 
ELSE IF (@Action = 'discount') BEGIN
						UPDATE Offer	
SET Price = (1 - @Rate)*Price
WHERE SupplierName = @supplierName and IngredientName = @ingredientName
					    END




go

CREATE VIEW v_topRatedRecipes AS
SELECT re.RecipeName , avgRank = avg (score) 
FROM dbo.Recipes as re join dbo.Ranking as ra on re.RecipeName = ra.RecipeName 
GROUP BY re.RecipeName

go


CREATE VIEW v_sumCalorie AS
SELECT  re.RecipeName , sumCalorie = sum (NumOfCalories) 
FROM dbo.Recipes as re join Contain as c on re.RecipeName= c.RecipeName join Ingredients as i on i.IngredientName= c.IngredientName 
GROUP BY re.RecipeName

go


CREATE VIEW v_ShortCookingTime AS
SELECT   re.RecipeName, re.CookingTime
FROM dbo.Recipes as re
where  CookingTime< 15

go

create view [dbo].[v_Money1] 
as
select p.ProvidedBy , p.yearOfPurchase, sum1 = sum(p.totalcost)
from	(SELECT b.NumOfPurchase, totalcost = (B.Quantity*o.Price) , p.ProvidedBy ,  yearOfPurchase = year(p.DateOfPurchase)
FROM Buys as B join Purchases as p on b.NumOfPurchase = p.NumOfPurchase join Offer as o on o.SupplierName = p.ProvidedBy
	Where b.IngredientName = o.IngredientName) as p
group by p.ProvidedBy , p.yearOfPurchase


go

CREATE VIEW [dbo].[v_MoneyPercountry] as
select c.country,  totSpent = sum(c.totalcost) 
from (	SELECT b.NumOfPurchase, totalcost =                                                       ( B.Quantity*o.Price),u.country
FROM Buys as B join Purchases as p on b.NumOfPurchase = p.NumOfPurchase join Offer as o on o.SupplierName = p.ProvidedBy join Users as u on u.Email = p.MadeBy
		Where b.IngredientName = o.IngredientName) as c
group by country

go


CREATE VIEW [dbo].[v_MoneyPerYear] 
as
select y.yearOfPurchase, sumT = sum(y.totalcost) 
from (	SELECT b.NumOfPurchase, totalcost = (B.Quantity*o.Price),  yearOfPurchase = year(p.DateOfPurchase)
FROM Buys as B join Purchases as p on b.NumOfPurchase = p.NumOfPurchase join Offer as o on o.SupplierName = p.ProvidedBy
		Where b.IngredientName = o.IngredientName
	     ) as y
group by yearOfPurchase

go

create view [dbo].[v_pbi] as
select Country,numOfSupplires =  count(SupplierName) 
from Suppliers
group by Country

go


CREATE VIEW [dbo].[v_QuntityOfIngridients] as
select b.IngredientName ,sumQ = sum (Quantity) 
from buys as b 
where b.IngredientName= b.IngredientName
group by b.IngredientName

go

ALTER TABLE contain add [Expired] bit default 0 not null
 
GO

CREATE PROCEDURE sp_CheckExpiryIngredient2(@recipeName VARCHAR(30))
 
   	AS
   	declare @recipeName1  varchar(30)
   	declare @ingredient varchar(20)
   	declare @expired as Date
 
   	Declare ingredientCursor CURSOR FOR
   	SELECT rc.RecipeName, rc.IngredientName, i.ExpressionDate
	FROM (SELECT r.RecipeName, c.IngredientName
FROM Recipes AS R join Contain as c on c.RecipeName = r.RecipeName
	      Where r.RecipeName=@recipeName) AS rc JOIN Ingredients AS i
   	ON rc.IngredientName=i.IngredientName
   	


   	OPEN ingredientCursor
	FETCH NEXT FROM ingredientCursor
   	INTO @recipeName1, @ingredient, @expired
 
   	WHILE (@@FETCH_STATUS=0)
   	BEGIN
   	IF @expired<GetDate()
          	BEGIN
PRINT 'FOR recipe ' + @recipeName1 + ' ingredient ' + @ingredient + ' has expired '
          		UPDATE Contain
          		SET [Expired] = 1
WHERE Contain.IngredientName=@ingredient AND Contain.RecipeName=@recipeName1;
          	END


   	ELSE IF (DATEDIFF(Day,Getdate(),@expired)<14)
PRINT 'IN 2 Weeks the ingredient ' + @ingredient +' will be expire for Recipe ' + @recipeName1

   	FETCH NEXT FROM ingredientCursor
   	INTO @recipeName1, @ingredient, @expired
   	END
   

   	CLOSE ingredientCursor
   	DEALLOCATE ingredientCursor


	go

	CREATE FUNCTION [dbo].[AvrageCalories12] ()
RETURNS real
AS
BEGIN
	RETURN 
		(select avg1 = avg (recipeCalorie)
from (SELECT r.RecipeName ,recipeCalorie =  sum(i.NumOfCalories) 
FROM Recipes as r join Contain as c on c.RecipeName = r.RecipeName join Ingredients as i on i.IngredientName= c.IngredientName
			group by r.RecipeName ) as r)
	
END

go




create PROCEDURE [dbo].[UpdateCaloriesWarningRe]
AS
BEGIN

UPDATE Recipes
SET CaloriesWarningRecipe = NULL



UPDATE R
SET R.CaloriesWarningRecipe = 'High Calorie'
from Recipes as r join 
(select r1.RecipeName , caloriesSum = sum(i.NumOfCalories)
from Recipes as r1 join contain as c on r1.RecipeName = c.RecipeName
join Ingredients as i on i.IngredientName = c.IngredientName
group by r1.RecipeName )
as a on r.RecipeName = a.RecipeName
WHERE a.caloriesSum > dbo.AvrageCalories12()*1.2

UPDATE R
SET CaloriesWarningRecipe = 'Avrage Calorie'
from Recipes as r join
(select r1.RecipeName , caloriesSum = sum(i.NumOfCalories)
from Recipes as r1 join contain as c on r1.RecipeName = c.RecipeName
join Ingredients as i on i.IngredientName = c.IngredientName
group by r1.RecipeName )
as a on r.RecipeName = a.RecipeName
WHERE  a.caloriesSum  < dbo.AvrageCalories12()*1.2 and  a.caloriesSum  > dbo.AvrageCalories12()*0.8

UPDATE R
SET CaloriesWarningRecipe = 'Low Calorie'
from Recipes as r join 
(select r1.RecipeName , caloriesSum = sum(i.NumOfCalories)
from Recipes as r1 join contain as c on r1.RecipeName = c.RecipeName
join Ingredients as i on i.IngredientName = c.IngredientName
group by r1.RecipeName ) as a on r.RecipeName = a.RecipeName
WHERE  a.caloriesSum  < dbo.AvrageCalories12()*0.8


END

go

CREATE TRIGGER UpdateCaloriesWarningRecipes
ON contain
AFTER INSERT, DELETE
AS
BEGIN

IF UPDATE(recipeName) OR EXISTS (SELECT * FROM inserted) OR EXISTS (SELECT * FROM deleted)
BEGIN
EXEC [dbo].[UpdateCaloriesWarningRe]
END

END




בדומה לעדכון המתכונים, כעת אנו מעדכנים את אזהרת הקלוריות על כל אחד מהמצרכים:



CREATE FUNCTION [dbo].[AvrageCalories] ()
RETURNS real
AS
BEGIN
	RETURN (
		SELECT avg(NumOfCalories)
		FROM Ingredients
		)
END


GO






CREATE PROCEDURE UpdateCaloriesWarningIn
AS
BEGIN
	UPDATE Ingredients
	SET CaloriesWarning = NULL

	UPDATE Ingredients
	SET CaloriesWarning = 'High Calorie'
	WHERE NumOfCalories > dbo.AvrageCalories()*1.2

	UPDATE Ingredients
	SET CaloriesWarning = 'Avrage Calorie'
WHERE NumOfCalories < dbo.AvrageCalories()*1.2 and NumOfCalories > dbo.AvrageCalories()*0.8

	UPDATE Ingredients
	SET CaloriesWarning = 'Low Calorie'
	WHERE NumOfCalories < dbo.AvrageCalories()*0.8
END

GO

CREATE TRIGGER UpdateCaloriesWarningTriggerIng
ON Ingredients
AFTER INSERT, UPDATE, DELETE
AS

BEGIN
	
IF UPDATE(NumOfCalories) OR EXISTS (SELECT * FROM inserted) OR EXISTS (SELECT * FROM deleted)
	BEGIN     
		EXEC UpdateCaloriesWarning
	END

END

go


	create PROCEDURE SP_SearchRecipesByParametersTopTenDistinct 
 @specialDiet varchar (30), @course varchar(20), @season varchar(10),  @maxcookingTime real 
		AS
		begin
			Select Distinct top 10 r.RecipeName , u.FirstName + ' ' +u.LastName , r.cuisin,
			 r.course, rsd.specialDiet, r.CookingTime, dbo.AvrageRate(r.RecipeName)
				From Recipes as r join Users as U  on U.Email = r.UploadedBy 
					join RecipeSpecialDiet as rsd on rsd.RecipeName = r.RecipeName 
				Where (r.course =  @course or @course = 'Any' ) AND (r.season = @season or @season = 'all') and 
			(r.CookingTime <= @maxcookingTime or @maxcookingTime= '')AND (rsd.specialDiet = @specialDiet or @specialDiet = 'None')
			order by 7 desc
			
		
	end


	go

	
create PROCEDURE SP_giveMore @Recipe varchar(30)  
 
		AS
		begin
				Select RecipeName, R.About,  [dbo].[numOfRanks] (@Recipe) [dbo].[numOfComments] (@Recipe), UploadDate
				FROM  Recipes as R
				WHERE RecipeName = @Recipe
		End


go


create PROCEDURE SP_giveMeMyComments    (@Recipe varchar (30))
		As begin 
				SELECT  C.Text, U.FirstName +' ' + U.LastName, C.Date
				FROM Comments as C join Users as U on U.Email = C.WrittenBy
				WHERE C.RecipeName = @Recipe
			order by 3
			end


go






