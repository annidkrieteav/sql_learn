-- MY SQL QUEREIES FOR SQL-EX.RU


-- 1. Find the model number, speed and hard drive capacity for all the PCs with prices below $500. Result set: model, speed, hd.

SELECT 
	model, speed, hd
FROM 
	pc
WHERE 
	price < 500

-- 2. List all printer makers. Result set: maker.

SELECT DISTINCT 
	maker
FROM 
	product
WHERE 
	type = 'Printer'

-- 3. Find the model number, RAM and screen size of the laptops with prices over $1000.

SELECT 
	model, ram, screen
FROM 
	laptop
WHERE 
	price > 1000

-- 4. Find all records from the Printer table containing data about color printers.

SELECT *
FROM 
	printer
WHERE 
	color = 'y'

-- 5. Find the model number, speed and hard drive capacity of PCs cheaper than $600 having a 12x or a 24x CD drive.

SELECT 
	model, speed, hd
FROM 
	pc
WHERE 
	cd IN ('12x', '24x') AND price < 600

-- 6. For each maker producing laptops with a hard drive capacity of 10 Gb or higher, find the speed of such laptops. Result set: maker, speed.

	SELECT DISTINCT 
	maker, speed
FROM 
	product p
	INNER JOIN laptop l ON p.model = l.model
WHERE 
	hd >= 10 AND type = 'Laptop'
	
-- 7. Get the models and prices for all commercially available products (of any type) produced by maker B.

SELECT 
	p.model, pc.price
FROM 
	pc
	INNER JOIN product p ON pc.model = p.model
WHERE 
	maker = 'B'
UNION
SELECT 
	p.model, l.price
FROM 
	Laptop l
	INNER JOIN product p ON l.model = p.model
WHERE 
	maker = 'B'
UNION
SELECT 
	p.model, pr.price
FROM 
	Printer pr
	INNER JOIN product p ON pr.model = p.model
WHERE 
	maker = 'B'
	
-- 8. Find the makers producing PCs but not laptops.
	
SELECT DISTINCT 
	maker 
FROM 
	product
WHERE 
	type = 'PC'
EXCEPT
SELECT DISTINCT 
	maker 
FROM 
	product
WHERE 
	type = 'Laptop'
	
-- 9. Find the makers of PCs with a processor speed of 450 MHz or more. Result set: maker.

SELECT DISTINCT 
	maker
FROM 	
	product p
	INNER JOIN pc ON p.model = pc.model
WHERE 
	speed >= 450
	
-- 10. Find the printer models having the highest price. Result set: model, price.
	
SELECT 
	model, price
FROM 
	printer
WHERE 
	price = (SELECT MAX(price) FROM printer)
	
-- 11. Find out the average speed of PCs.
	
SELECT 
	AVG(speed)
FROM 	
	pc
	
-- 12. Find out the average speed of the laptops priced over $1000.

SELECT 
	AVG(speed)
FROM 
	laptop
WHERE 
	price > 1000
	
-- 13. Find out the average speed of the PCs produced by maker A.
	
SELECT 
	AVG(speed)
FROM 
	pc
	INNER JOIN product p ON pc.model = p.model
WHERE 
	maker = 'A'
	
-- 14. For the ships in the Ships table that have at least 10 guns, get the class, name, and country.
	
SELECT 
	s."class", "name", country
FROM 
	ships s INNER JOIN classes c ON s.class = c.class
WHERE 
	numguns >= 10
	
-- 15. Get hard drive capacities that are identical for two or more PCs. Result set: hd.
	
SELECT 
	hd
FROM 
	pc
GROUP BY 
	hd
HAVING 	
	COUNT(hd) >=2

-- 16. Get pairs of PC models with identical speeds and the same RAM capacity. 
-- Each resulting pair should be displayed only once, i.e. (i, j) but not (j, i). 
-- Result set: model with the bigger number, model with the smaller number, speed, and RAM.
	
SELECT DISTINCT 
	pc1.model, pc2.model, pc1.speed, pc1.ram
FROM 
	pc pc1 
	INNER JOIN pc pc2 ON pc1.speed = pc2.speed AND pc1.ram = pc2.ram AND pc1.model > pc2.model
	
-- 17. Get the laptop models that have a speed smaller than the speed of any PC. Result set: type, model, speed.
	
SELECT DISTINCT 
type, l.model, speed
FROM 
	laptop l
	INNER JOIN product p ON l.model = p.model
WHERE 
	speed < (SELECT MIN(speed) FROM pc)
	
-- 18. Find the makers of the cheapest color printers. Result set: maker, price.
	
SELECT DISTINCT 
	maker, price
FROM 
	product p
	INNER join
		(SELECT 
			model, price
		FROM 
			printer
		WHERE 
			color = 'y' AND price = (SELECT MIN(price) FROM printer WHERE color = 'y')) AS t
	ON p.model = t.model
	
-- 19. For each maker having models in the Laptop table, find out the average screen size of the laptops he produces. 
-- Result set: maker, average screen size.
	
SELECT 	
	maker, AVG(screen)
FROM 
	laptop l
	INNER JOIN product p ON l.model = p.model
GROUP BY 
	maker
	
-- 20. Find the makers producing at least three distinct models of PCs. Result set: maker, number of PC models.
	
SELECT 
	maker, COUNT(*) models_num
FROM 
	product
WHERE 
	type = 'pc'
GROUP BY 
	maker
HAVING 
	COUNT(*) > 2
	
-- 21. Find out the maximum PC price for each maker having models in the PC table. Result set: maker, maximum price.
	
SELECT 
	maker, MAX(price)
FROM 
	product p
	INNER JOIN pc ON p.model = pc.model
GROUP BY 
	maker
	
-- 22. For each value of PC speed that exceeds 600 MHz, find out the average price of PCs with identical speeds. Result set: speed, average price.
	
SELECT 
	speed, AVG(price)
FROM 
	pc
WHERE 
	speed > 600
GROUP BY 	
	speed
	
-- 23. Get the makers producing both PCs having a speed of 750 MHz or higher and laptops with a speed of 750 MHz or higher. Result set: maker
	
SELECT DISTINCT 
	maker
FROM 
	product p
WHERE 
	maker IN (SELECT maker FROM product p INNER JOIN pc ON p.model = pc.model AND pc.speed >= 750)
	AND maker in (SELECT maker FROM product p INNER JOIN laptop l ON p.model = l.model AND l.speed >= 750)
	
-- 24. List the models of any type having the highest price of all products present in the database.
	
WITH cte AS (
	SELECT 
		model, price
	FROM 
		pc
	WHERE 	
		price = (SELECT MAX(price) FROM pc)
	UNION
	SELECT 
		model, price
	FROM 
		laptop
	WHERE 
		price = (SELECT MAX(price) FROM laptop)
	UNION
	SELECT 
		model, price
	FROM 
		printer
	WHERE 
		price = (SELECT MAX(price) FROM printer)
)
SELECT 
	model
FROM 
	cte
WHERE 
	price = (SELECT MAX(price) FROM cte)
	
-- 25. Find the printer makers also producing PCs with the lowest RAM capacity and the highest processor speed of all PCs having the lowest RAM capacity. 
-- Result set: maker.
	
select distinct 
	p.maker
from 
	product p
where 
	p.model in (
		select model from pc 
		where speed = (select max(speed) from pc 
			where ram = (select min(ram) from pc))
		and ram = (select min(ram) from pc))
intersect
select distinct 
	p.maker
from 
	product p
where 
	p.type = 'Printer'

-- 26. Find out the average price of PCs and laptops produced by maker A. Result set: one overall average price for all items.
	
WITH cte as (
	SELECT 
		maker, p.model, price
	FROM 
		product p
		INNER JOIN pc ON pc.model = p.model AND p.maker = 'A' AND p.type = 'PC'
	UNION ALL
	SELECT 
		maker, p.model, price
	FROM 
		product p
		INNER JOIN laptop l	ON l.model = p.model AND p.maker = 'A' AND p.type = 'Laptop')
SELECT 
	AVG(price)
FROM cte

-- 27. Find out the average hard disk drive capacity of PCs produced by makers who also manufacture printers. Result set: maker, average HDD capacity.

SELECT 
	p.maker, AVG(hd)
FROM 
	pc
	INNER JOIN product p ON p.model = pc.model AND p.maker IN (SELECT distinct maker FROM product WHERE type = 'Printer')
GROUP BY 
	p.maker

-- 28. Using Product table, find out the number of makers who produce only one model.
	
SELECT 
	COUNT(maker)
FROM 
	(SELECT maker FROM product GROUP BY maker HAVING COUNT(model) = 1) a

-- 29. Under the assumption that receipts of money (inc) and payouts (out) are registered not more than once a day for each collection point [i.e. the primary key consists of (point, date)], write a query displaying cash flow data (point, date, income, expense). Use Income_o and Outcome_o tables.

SELECT 
	CASE 
		WHEN i.point IS NULL THEN o.point
		WHEN o.point IS NULL THEN i.point
		ELSE i.point 
	END AS point, 
	CASE 
		WHEN i.date IS NULL THEN o.date
		WHEN o.date IS NULL THEN i.date
		ELSE i.date END AS date, 
	SUM(inc) AS inc, 
	SUM(out) AS out
FROM 
	outcome_o o
	FULL JOIN income_o i ON o.point = i.point AND o.date = i.date
GROUP BY 
	CASE 
		WHEN i.point IS NULL THEN o.point
		WHEN o.point IS NULL THEN i.point
		ELSE i.point 
	END, 
	CASE 
		WHEN i.date IS NULL THEN o.date
		WHEN o.date IS NULL THEN i.date
		ELSE i.date 
	END
		
-- 30. Under the assumption that receipts of money (inc) and payouts (out) can be registered any number of times a day for each collection point 
-- [i.e. the code column is the primary key], display a table with one corresponding row for each operating date of each collection point. 
-- Result set: point, date, total payout per day (out), total money intake per day (inc). Missing values are considered to be NULL.
	
WITH inc_gr AS (
	SELECT 
		point, date, SUM(inc) inc
	FROM 
		income
	GROUP BY 
		point, date), 
out_gr as (
	SELECT 
		point, date, SUM(out) out
	FROM 
		outcome
	GROUP BY 
		point, date)
SELECT 
	i.point, i.date, out, inc
FROM 
	inc_gr i 
	LEFT JOIN out_gr o ON i.point = o.point AND i.date = o.date
UNION
SELECT 
	o.point, o.date, out, inc
FROM 
	inc_gr i 
	RIGHT JOIN out_gr o ON i.point = o.point AND i.date = o.date
	
-- 31. For ship classes with a gun caliber of 16 in. or more, display the class and the country.
	
SELECT 
	class, country
FROM 
	classes
WHERE 
	bore >= 16
	
-- 32. One of the characteristics of a ship is one-half the cube of the calibre of its main guns (mw). 
-- Determine the average ship mw with an accuracy of two decimal places for each country having ships in the database.
	
SELECT 
	country, CAST(AVG(POWER(bore, 3)/2) AS NUMERIC(10, 2)) 
FROM
	(SELECT 
		country, bore, name 
	FROM 
		classes c
		INNER JOIN ships s ON s.class = c.class
	UNION
	SELECT 
		country, bore, ship 
	FROM 	
		classes c
		INNER JOIN outcomes o ON o.ship = c.class AND o.ship NOT IN(SELECT DISTINCT name FROM ships)) AS n
GROUP BY 
	country
	 
-- 33. Get the ships sunk in the North Atlantic battle. Result set: ship.
	
SELECT 
	ship
FROM 
	outcomes
WHERE 
	battle = 'North Atlantic' AND result = 'sunk'
	
-- 34. In accordance with the Washington Naval Treaty concluded in the beginning of 1922, 
-- it was prohibited to build battle ships with a displacement of more than 35 thousand tons. 
-- Get the ships violating this treaty (only consider ships for which the year of launch is known). List the names of the ships.
	
SELECT 
	name 
FROM 
	classes c
	INNER JOIN ships s ON c.class = s.class
WHERE 
	displacement > 35000 AND launched >= 1922 AND type = 'bb'
	
-- 35. Find models in the Product table consisting either of digits only or Latin letters (A-Z, case insensitive) only. Result set: model, type.
	
SELECT 
	model, type 
FROM 
	Product 
WHERE 
	model NOT LIKE '%[^A-Z]%'  OR model NOT LIKE '%[^0-9]%'
	
-- 36. List the names of lead ships in the database (including the Outcomes table).
	
SELECT 
	class
FROM 
	classes
WHERE 
	class in (SELECT name FROM ships UNION SELECT ship FROM outcomes)
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	