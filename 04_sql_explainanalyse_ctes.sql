--=============== МОДУЛЬ 6. POSTGRESQL =======================================
--= ПОМНИТЕ, ЧТО НЕОБХОДИМО УСТАНОВИТЬ ВЕРНОЕ СОЕДИНЕНИЕ И ВЫБРАТЬ СХЕМУ PUBLIC===========
SET search_path TO public;

--======== ОСНОВНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Напишите SQL-запрос, который выводит всю информацию о фильмах 
--со специальным атрибутом "Behind the Scenes".

explain analyse --113.75 2 Плохо, тк подзапрос сьедает
select film_id, title, special_features 
from film
where 'Behind the Scenes' in (select unnest(special_features))



--ЗАДАНИЕ №2
--Напишите еще 2 варианта поиска фильмов с атрибутом "Behind the Scenes",
--используя другие функции или операторы языка SQL для поиска значения в массиве.

explain analyse --67.50 1 Хорошо пробегаем 1 раз
select film_id, title, special_features 
from film
where special_features && array['Behind the Scenes']

explain analyse --67.50 1 Хорошо пробегаем 1 раз
select film_id, title, special_features 
from film
where array['Behind the Scenes'] <@ special_features 



--ЗАДАНИЕ №3
--Для каждого покупателя посчитайте сколько он брал в аренду фильмов 
--со специальным атрибутом "Behind the Scenes.

--Обязательное условие для выполнения задания: используйте запрос из задания 1, 
--помещенный в CTE. CTE необходимо использовать для решения задания.

explain analyse --720 20
with cte as (
	select film_id, title, special_features 
	from film
	where array['Behind the Scenes'] <@ special_features)
select c.customer_id, count(i.film_id)
from customer c 
join rental r on r.customer_id = c.customer_id 
join inventory i on i.inventory_id = r.inventory_id 
join cte on cte.film_id = i.film_id 
group by c.customer_id 
order by c.customer_id 




--ЗАДАНИЕ №4
--Для каждого покупателя посчитайте сколько он брал в аренду фильмов
-- со специальным атрибутом "Behind the Scenes".

--Обязательное условие для выполнения задания: используйте запрос из задания 1,
--помещенный в подзапрос, который необходимо использовать для решения задания.

explain analyse --720 20
select c.customer_id, count(i.film_id)
from customer c 
join rental r on r.customer_id = c.customer_id 
join inventory i on i.inventory_id = r.inventory_id 
join (
	select film_id, title, special_features 
	from film
	where array['Behind the Scenes'] <@ special_features) t on t.film_id = i.film_id 
group by c.customer_id 
order by c.customer_id 



--ЗАДАНИЕ №5
--Создайте материализованное представление с запросом из предыдущего задания
--и напишите запрос для обновления материализованного представления

create materialized view bsfilms as
	select c.customer_id, count(i.film_id)
	from customer c 
	join rental r on r.customer_id = c.customer_id 
	join inventory i on i.inventory_id = r.inventory_id 
	join (
		select film_id, title, special_features 
		from film
		where array['Behind the Scenes'] <@ special_features) t on t.film_id = i.film_id 
	group by c.customer_id 
	order by c.customer_id 
with no data

refresh materialized view bsfilms

select * from bsfilms

--ЗАДАНИЕ №6
--С помощью explain analyze проведите анализ стоимости выполнения запросов из предыдущих заданий и ответьте на вопросы:
--1. с каким оператором или функцией языка SQL, используемыми при выполнении домашнего задания: 
--поиск значения в массиве затрачивает меньше ресурсов системы;
--2. какой вариант вычислений затрачивает меньше ресурсов системы: 
--с использованием CTE или с использованием подзапроса.

--1. В первом запросе используется подзапрос, из-за этого приходится 2 раза пробегать одну и ту же таблицу.
--   Следующие 2 запроса работают по другой логике, как бы проверяя наличие значения 'Behind the Scenes' в массиве special_features.
--   anyarray && anyarray → boolean (у них есть общие элементы?); anyarray <@ anyarray → boolean (1 массив содердится во втором?).
--2. В нашем случае одинаково, тк и подзапрос выполнился 1 раз. Однако, если один и тот же подзапрос 
--   понадобилось бы использовать более 1 раза, то CTE затратила бы меньше ресурсов, благодаря тому, 
--   что она выполнится 1 раз и далее у ней можно будет обращаться как к таблице.






--======== ДОПОЛНИТЕЛЬНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Выполняйте это задание в форме ответа на сайте Нетологии

explain analyse -- 1090 120 unnest узкое место
select distinct cu.first_name  || ' ' || cu.last_name as name, 
	count(ren.iid) over (partition by cu.customer_id)
from customer cu
full outer join 
	(select *, r.inventory_id as iid, inv.sf_string as sfs, r.customer_id as cid
	from rental r 
	full outer join 
		(select *, unnest(f.special_features) as sf_string
		from inventory i
		full outer join film f on f.film_id = i.film_id) as inv 
		on r.inventory_id = inv.inventory_id) as ren 
	on ren.cid = cu.customer_id 
where ren.sfs like '%Behind the Scenes%'
order by count desc


explain analyse --720 20
select c.customer_id, count(i.film_id)
from customer c 
join rental r on r.customer_id = c.customer_id 
join inventory i on i.inventory_id = r.inventory_id 
join (
	select film_id, title, special_features 
	from film
	where array['Behind the Scenes'] <@ special_features) t on t.film_id = i.film_id 
group by c.customer_id 
order by c.customer_id 

Seq Scan film
Seq Scan inventory
Seq Scan rental
Seq scan customer
Hash join
Hash join
Hash join


--ЗАДАНИЕ №2
--Используя оконную функцию выведите для каждого сотрудника
--сведения о самой первой продаже этого сотрудника.

select s.staff_id, s.first_name || ' ' || s.last_name as "sname", f.film_id, f.title, 
	   t.amount, t.payment_date, c.customer_id, c.first_name || ' ' || c.last_name as "cname"
from (
	select  *, row_number() over (partition by staff_id order by payment_date)
	from payment) t
join staff s on s.staff_id = t.staff_id 
join rental r on r.rental_id = t.rental_id 
join customer c on c.customer_id = r.customer_id 
join inventory i on i.inventory_id = r.inventory_id 
join film f on f.film_id = i.film_id 
where row_number = 1


--ЗАДАНИЕ №3
--Для каждого магазина определите и выведите одним SQL-запросом следующие аналитические показатели:
-- 1. день, в который арендовали больше всего фильмов (день в формате год-месяц-день)
-- 2. количество фильмов взятых в аренду в этот день
-- 3. день, в который продали фильмов на наименьшую сумму (день в формате год-месяц-день)
-- 4. сумму продажи в этот день

select s.store_id, tt1.date1, tt1.fv1, tt2.date2, tt2.fv2
from store s 
join (
	select distinct t1.store_id, t1.rental_date::date as date1, first_value(t1.count) over (partition by t1.store_id) as fv1
	from(
		select s2.store_id, r.rental_date::date, count(*)
		from rental r 
		right join customer c on r.customer_id = c.customer_id 
		right join store s2 on s2.store_id = c.store_id 
		group by s2.store_id, rental_date::date
		order by 1, 3 desc) t1) tt1 on s.store_id = tt1.store_id
join (
	select distinct t2.store_id, t2.payment_date::date as date2, first_value(t2.sum) over (partition by t2.store_id) as fv2
	from(
		select c.store_id, p.payment_date::date, sum(p.amount)
		from payment p
		join customer c on c.customer_id = p.customer_id 
		group by c.store_id, p.payment_date::date
		order by 1, 3 asc) t2) tt2 on s.store_id = tt2.store_id
order by 1
	
	
	