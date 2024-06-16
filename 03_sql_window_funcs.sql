--=============== МОДУЛЬ 5. РАБОТА С POSTGRESQL =======================================
--= ПОМНИТЕ, ЧТО НЕОБХОДИМО УСТАНОВИТЬ ВЕРНОЕ СОЕДИНЕНИЕ И ВЫБРАТЬ СХЕМУ PUBLIC===========
SET search_path TO public;

--======== ОСНОВНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Сделайте запрос к таблице payment и с помощью оконных функций добавьте вычисляемые колонки согласно условиям:
--Пронумеруйте все платежи от 1 до N по дате платежа
--Пронумеруйте платежи для каждого покупателя, сортировка платежей должна быть по дате платежа
--Посчитайте нарастающим итогом сумму всех платежей для каждого покупателя, сортировка должна 
--быть сперва по дате платежа, а затем по размеру платежа от наименьшей к большей
--Пронумеруйте платежи для каждого покупателя по размеру платежа от наибольшего к
--меньшему так, чтобы платежи с одинаковым значением имели одинаковое значение номера.
--Можно составить на каждый пункт отдельный SQL-запрос, а можно объединить все колонки в одном запросе.

select customer_id, payment_id, payment_date, row_number() over (order by payment_date) as column1, row_number() over (partition by customer_id order by payment_date) as column2,
	   sum(amount) over (partition by customer_id order by payment_date, amount asc) as column3, dense_rank() over (partition by customer_id order by amount) as column4
from payment
order by customer_id, column4



--ЗАДАНИЕ №2
--С помощью оконной функции выведите для каждого покупателя стоимость платежа и стоимость 
--платежа из предыдущей строки со значением по умолчанию 0.0 с сортировкой по дате платежа.

select customer_id, payment_id, payment_date, amount, lag(amount, 1, 0.) over (partition by customer_id order by payment_date)
from payment p 




--ЗАДАНИЕ №3
--С помощью оконной функции определите, на сколько каждый следующий платеж покупателя больше или меньше текущего.

select customer_id, payment_id, payment_date, amount, amount - lead(amount, 1, 0.) over (partition by customer_id order by payment_date) as difference
from payment p 



--ЗАДАНИЕ №4
--С помощью оконной функции для каждого покупателя выведите данные о его последней оплате аренды.

select distinct customer_id, 
	   first_value(payment_id) over (partition by customer_id order by payment_date desc),
	   first_value(payment_date) over (partition by customer_id order by payment_date desc),
	   first_value(amount) over (partition by customer_id order by payment_date desc)
from payment 
order by customer_id 



--======== ДОПОЛНИТЕЛЬНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--С помощью оконной функции выведите для каждого сотрудника сумму продаж за август 2005 года 
--с нарастающим итогом по каждому сотруднику и по каждой дате продажи (без учёта времени) 
--с сортировкой по дате.

select *, sum(sum) over (partition by customer_id order by customer_id, payment_date::date)
from 
	(select customer_id, payment_date::date, sum(amount)
	 from payment 
	 where date_part('month', payment_date::date) = 5
	 group by customer_id, payment_date::date
	 order by customer_id) t



--ЗАДАНИЕ №2
--20 августа 2005 года в магазинах проходила акция: покупатель каждого сотого платежа получал
--дополнительную скидку на следующую аренду. С помощью оконной функции выведите всех покупателей,
--которые в день проведения акции получили скидку

select *
from 
	(select *, row_number() over (order by payment_date)
	from payment
	where payment_date::date = '2005-08-20') t
where row_number % 100 = 0

--ЗАДАНИЕ №3
--Для каждой страны определите и выведите одним SQL-запросом покупателей, которые попадают под условия:
-- 1. покупатель, арендовавший наибольшее количество фильмов
-- 2. покупатель, арендовавший фильмов на самую большую сумму
-- 3. покупатель, который последним арендовал фильм

select 
	t.country,
	group_concat(case 
		when max_count = 1 then t.nickname
	end) as max_count_customer,
	group_concat(case 
		when max_amount = 1 then t.nickname
	end) as max_amount_customer,
	group_concat(case 
		when latest_rent = 1 then t.nickname
	end) as latest_rent_customer
from 
	(select 
	c.country_id, c.country, c3.customer_id, concat(c3.first_name,' ', c3.last_name) as nickname, count(r.rental_id), sum(p.amount), max(r.rental_date),
	rank() over (partition by c.country_id order by count(r.rental_id) desc) as max_count,
	rank() over (partition by c.country_id order by sum(p.amount) desc) as max_amount,
	rank() over (partition by c.country_id order by max(r.rental_date) desc) as latest_rent
from
	country c 
	left join city c2 on c.country_id = c2.country_id 
	left join address a on a.city_id = c2.city_id 
	left join customer c3 on c3.address_id = a.address_id 
	join rental r on c3.customer_id = r.customer_id 
	left join payment p on p.rental_id = r.rental_id 
group by 
	c3.customer_id, c.country_id, c.country) t
group by t.country_id, t.country




