--=============== МОДУЛЬ 3. ОСНОВЫ SQL =======================================
--= ПОМНИТЕ, ЧТО НЕОБХОДИМО УСТАНОВИТЬ ВЕРНОЕ СОЕДИНЕНИЕ И ВЫБРАТЬ СХЕМУ PUBLIC===========
SET search_path TO public;

--======== ОСНОВНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Выведите для каждого покупателя его адрес проживания, 
--город и страну проживания.

select concat(last_name, ' ', first_name) as "Customer name", a.address, c2.city, c3.country
from customer c
join address a using (address_id)
join city c2 using (city_id)
join country c3 using (country_id)



--ЗАДАНИЕ №2
--С помощью SQL-запроса посчитайте для каждого магазина количество его покупателей.

select store_id, count(*)
from store
join customer using (store_id)
group by store_id




--Доработайте запрос и выведите только те магазины, 
--у которых количество покупателей больше 300-от.
--Для решения используйте фильтрацию по сгруппированным строкам 
--с использованием функции агрегации.

select store_id, count(*)
from store
join customer using (store_id)
group by store_id
having count(*) > 300



-- Доработайте запрос, добавив в него информацию о городе магазина, 
--а также фамилию и имя продавца, который работает в этом магазине.

select "ID Магазина" , "Количество покупателей", c."city" as "Город", concat(s.first_name, ' ', s.last_name) as "Имя сотрудника"
from (
	select store_id as "ID Магазина", store.address_id, count(*) as "Количество покупателей"
	from store
	join customer using (store_id)
	group by store_id
	having count(*) > 300) t
join address a on a.address_id = t.address_id
join city c on c.city_id = a.city_id 
join staff s on s.store_id = t."ID Магазина"




--ЗАДАНИЕ №3
--Выведите ТОП-5 покупателей, 
--которые взяли в аренду за всё время наибольшее количество фильмов

select concat(last_name, ' ', first_name), count(*)
from customer c 
join rental r using (customer_id)
group by customer_id 
order by count(*) desc 
limit 5

-- Я так понял, что покупатель совершает аренду, запись идет в rental, далее просто inventory нужен для отслежки 
-- доступных в каждом магазине, а film нужен просто для описания фильма.

--ЗАДАНИЕ №4
--Посчитайте для каждого покупателя 4 аналитических показателя:
--  1. количество фильмов, которые он взял в аренду
--  2. общую стоимость платежей за аренду всех фильмов (значение округлите до целого числа)
--  3. минимальное значение платежа за аренду фильма
--  4. максимальное значение платежа за аренду фильма


select concat(last_name, ' ', first_name), count(*), round(sum(amount)), min(amount), max(amount)
from customer c 
join rental r using (customer_id)
join payment p using(rental_id)
group by c.customer_id 
order by c.last_name 

--ЗАДАНИЕ №5
--Используя данные из таблицы городов, составьте все возможные пары городов так, чтобы 
--в результате не было пар с одинаковыми названиями городов. Решение должно быть через Декартово произведение.
 
select c.city as "Город 1", c2.city as "Город 2"
from city c, city c2 
where c.city < c2.city

--ЗАДАНИЕ №6
--Используя данные из таблицы rental о дате выдачи фильма в аренду (поле rental_date) и 
--дате возврата (поле return_date), вычислите для каждого покупателя среднее количество 
--дней, за которые он возвращает фильмы. В результате должны быть дробные значения, а не интервал.
 
select c.customer_id, 
       round(avg(date_part('day', age(r.return_date::date, r.rental_date::date)))::numeric,2) as avg_return_days
from customer c
join rental r on c.customer_id = r.customer_id
group by c.customer_id
order by c.customer_id 


--======== ДОПОЛНИТЕЛЬНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Посчитайте для каждого фильма сколько раз его брали в аренду и значение общей стоимости аренды фильма за всё время.

select t.title, t.rating, string_agg, t.release_year, l."name", count, sum
from 
	(select f.film_id, f.title, f.rating, f.release_year, f.language_id, count(r.rental_id), sum(p.amount)
	from film f 
	left join inventory i on f.film_id = i.film_id 
	right join rental r on i.inventory_id = r.inventory_id 
	right join payment p on r.rental_id = p.rental_id  
	group by f.film_id 
	order by f.title) t
left join 
	(select fc.film_id, string_agg(c."name", ', ')
	 from film_category fc
	 join category c on fc.category_id = c.category_id
	 group by fc.film_id) fc2 on t.film_id = fc2.film_id 
left join "language" l  on l.language_id = t.language_id

--ЗАДАНИЕ №2
--Доработайте запрос из предыдущего задания и выведите с помощью него фильмы, которые отсутствуют на dvd дисках.

select f.title, l."name", c."name", count(r.rental_id), sum(p.amount)
from film f
left join inventory i on f.film_id = i.film_id
left join rental r on r.inventory_id = i.inventory_id
left join payment p on p.rental_id = r.rental_id
join "language" l on f.language_id = l.language_id
join film_category fc on fc.film_id = f.film_id
join category c on fc.category_id = c.category_id
where i.film_id is null
group by f.film_id, l.language_id, c.category_id



--ЗАДАНИЕ №3
--Посчитайте количество продаж, выполненных каждым продавцом. Добавьте вычисляемую колонку "Премия".
--Если количество продаж превышает 7300, то значение в колонке будет "Да", иначе должно быть значение "Нет".

select s.staff_id, count(p.staff_id) AS количество_продаж, 
       case 
           when count(p.staff_id) > 7300 then 'Да'
           else 'Нет'
       end as Премия
from staff s 
left join payment p  on s.staff_id = p.staff_id
group by s.staff_id;





