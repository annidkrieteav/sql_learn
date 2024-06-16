select last_name, first_name
from customer 
order by last_name, first_name

ABNEY	NATHANIEL
ABNEY	RAFAEL

Задание 1. Создайте новую таблицу film_new со следующими полями:
· film_name — название фильма — тип данных varchar(255) и ограничение not null;
· film_year — год выпуска фильма — тип данных integer, условие, что значение должно быть больше 0;
· film_rental_rate — стоимость аренды фильма — тип данных numeric(4,2), значение по умолчанию 0.99;
· film_duration — длительность фильма в минутах — тип данных integer, ограничение not null и условие, что значение должно быть больше 0.
Если работаете в облачной базе, то перед названием таблицы задайте наименование вашей схемы.

create table film_new (
	film_id serial primary key,
	film_name varchar(255) not null,
	film_year integer check(film_year > 0),
	film_rental_rate numeric(4,2) default 0.99,
	film_duration integer not null check(film_duration > 0))

Задание 2. Заполните таблицу film_new данными с помощью SQL-запроса, где колонкам соответствуют массивы данных:
· film_name — array[The Shawshank Redemption, The Green Mile, Back to the Future, Forrest Gump, Schindler’s List];
· film_year — array[1994, 1999, 1985, 1994, 1993];
· film_rental_rate — array[2.99, 0.99, 1.99, 2.99, 3.99];
· film_duration — array[142, 189, 116, 142, 195].

insert into film_new (film_name, film_year, film_rental_rate, film_duration)
select *
from unnest(
	array['The Shawshank Redemption', 'The Green Mile', 'Back to the Future', 'Forrest Gump', 'Schindler’s List'],
	array[1994, 1999, 1985, 1994, 1993],
	array[2.99, 0.99, 1.99, 2.99, 3.99],
	array[142, 189, 116, 142, 195])

select unnest(array)

from unnest(array1, array2, array3, ...)

select *
from film_new

Задание 3. Обновите стоимость аренды фильмов в таблице film_new с учётом информации, что стоимость аренды всех фильмов поднялась на 1.41.

update film_new
set film_rental_rate = film_rental_rate + 1.41

Задание 4. Фильм с названием Back to the Future был снят с аренды, удалите строку с этим фильмом из таблицы film_new.

delete from film_new
where film_id = 3

Задание 5. Добавьте в таблицу film_new запись о любом другом новом фильме.

insert into film_new (film_name, film_year, film_rental_rate, film_duration)
values ('sdsdfsdf', 2005, default, 55)

Задание 6. Напишите SQL-запрос, который выведет все колонки из таблицы film_new, а также новую вычисляемую колонку «длительность фильма в часах», округлённую до десятых.

select *, round(film_duration / 60., 1)
from film_new

Задание 7. Удалите таблицу film_new.

drop table film_new

СЕКЦИОНИРОВАНИЕ

select * from payment 

create temporary table pay_temp as (select * from payment )

select * from pay_temp

delete from pay_temp
where payment_id > 1000

drop table pay_temp

create table pay_temp (like payment)

create table pay_temp (like payment including all)

explain analyze --320.94 / 1.9
select distinct customer_id
from payment p 
where amount > 10

explain analyze --3.85 / 0.06
select distinct customer_id
from pay_temp p 
where amount > 10

select 320.94 / 3.85 --83.3610389610389610

select 1.9 / 0.06 --31.6666666666666667

create table pay_temp (like payment) partition by range (amount)

create table pay_low partition of pay_temp for values from (minvalue) to (5)

create table pay_mid partition of pay_temp for values from (5) to (10)

create table pay_high partition of pay_temp for values from (10) to (maxvalue)

insert into pay_temp
select * from payment

select * from pay_low

select * from pay_temp

select * from only pay_temp

explain analyze --375.34 / 2.7
select distinct customer_id
from payment p 
where amount between 5 and 10

explain analyze --120.18 / 1.5
select distinct customer_id
from pay_temp p 
where amount between 5 and 10

explain analyze --325.60 / 2.7
select distinct customer_id
from payment p 

explain analyze --401.86 / 3.7
select distinct customer_id
from pay_temp p 

explain analyze --20.23 / 0.3
select *
from customer 
where lower(left(last_name, 1)) in ('a', 'b', 'c')

explain analyze --13.94 / 0.15
select *
from cust_temp 
where lower(left(last_name, 1)) in ('a', 'b', 'c')

create table cust_temp (like customer) partition by list (lower(left(last_name, 1)))

create table cust_a_i partition of cust_temp for values in ('a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i')

create table cust_j_t partition of cust_temp for values in ('j', 'k', 'l', 'm', 'n', 'o', 'p')

create table pay_q_z partition of cust_temp for values in ('q', 'r', 's', 't', 'u', 'y', 'x', 'v', 'w', 'z')

insert into cust_temp
select * from customer

Задание 1. С помощью оконной функции выведите для каждого сотрудника сумму продаж за август 2005 года с нарастающим итогом по каждому сотруднику и по каждой дате 
продажи (без учёта времени) с сортировкой по дате.
Ожидаемый результат запроса: letsdocode.ru...in/5-5.png

select staff_id, payment_date::date, sum(amount),
	sum(sum(amount)) over (partition by staff_id order by payment_date::date)
from payment 
where date_trunc('month', payment_date) = '01.08.2005'
group by staff_id, payment_date::date

Задание 2. 20 августа 2005 года в магазинах проходила акция: покупатель каждого сотого платежа получал дополнительную скидку на следующую аренду. 
С помощью оконной функции выведите всех покупателей, которые в день проведения акции получили скидку.
Ожидаемый результат запроса: letsdocode.ru...in/5-6.png

explain analyze --364.86 / 1.854
select customer_id
from (
	select *, row_number() over (order by payment_date)
	from payment 
	where payment_date::date = '20.08.2005') 
--where row_number % 100 = 0
where mod(row_number, 100) = 0

explain analyze --4018.96 / 1298.099
with recursive r as (
	select *
	from (
		select customer_id, 1 as x, 1 as y, lead(payment_id) over (order by payment_date)
		from payment p
		where payment_date::date = '20.08.2005'
		order by payment_date
		limit 1)
	union
	select p.customer_id,
		case when x + 1 = 101 then 1 else x + 1 end x, 
		case when x + 1 = 101 then y + 1 else y end y, 
		p.lead
	from r
	join (
		select *, lead(payment_id) over (order by payment_date)
		from payment
		where payment_date::date = '20.08.2005') p on p.payment_id = r.lead
	where p.lead is not null)
select *
from r
where x = 100

select t1.*
from (
	select *, lead(p.payment_id) over (order by p.payment_date)
	from payment p
	where payment_date::date = '20.08.2005') t1 
join (
		select customer_id, 1 as x, 1 as y, lead(payment_id) over (order by payment_date)
		from payment p
		where payment_date::date = '20.08.2005'
		order by payment_date
		limit 1) t2 on t2.lead = t1.payment_id
		
		1026
		13352
		13183

Задание 3. Для каждой страны определите и выведите одним SQL-запросом покупателей, которые попадают под условия:
· покупатель, арендовавший наибольшее количество фильмов;
· покупатель, арендовавший фильмов на самую большую сумму;
· покупатель, который последним арендовал фильм.
Ожидаемый результат запроса: letsdocode.ru...in/5-7.png

explain analyze --6686.03 / 32
select distinct c.country, 
	first_value(concat(c3.last_name, ' ', c3.first_name)) over (partition by c.country_id order by count(i.film_id) desc),
	first_value(concat(c3.last_name, ' ', c3.first_name)) over (partition by c.country_id order by sum(p.amount) desc),
	first_value(concat(c3.last_name, ' ', c3.first_name)) over (partition by c.country_id order by max(r.rental_date) desc)
from country c
left join city c2 on c.country_id = c2.country_id
left join address a on a.city_id = c2.city_id
left join customer c3 on a.address_id = c3.address_id
left join rental r on r.customer_id = c3.customer_id
left join inventory i on i.inventory_id = r.inventory_id
left join payment p on p.rental_id = r.rental_id
group by c.country_id, c3.customer_id
order by 1

explain analyze --1262.85 / 14
with cte1 as (
	select p.customer_id, count, sum, max
	from (
		select customer_id, sum(amount)
		from payment 
		group by customer_id) p 
	join (
		select customer_id, count(i.film_id), max(r.rental_date)
		from rental r
		join inventory i on i.inventory_id = r.inventory_id
		group by customer_id) r on r.customer_id = p.customer_id),
cte2 as (
	select c.customer_id, concat(c.last_name, ' ', c.first_name), c2.country_id,
		case when count = max(count) over (partition by c2.country_id) then concat(c.last_name, ' ', c.first_name) end cc,
		case when sum = max(sum) over (partition by c2.country_id) then concat(c.last_name, ' ', c.first_name) end cs,
		case when max = max(max) over (partition by c2.country_id) then concat(c.last_name, ' ', c.first_name) end cm
	from cte1 
	join customer c on c.customer_id = cte1.customer_id
	join address a on a.address_id = c.address_id
	join city c2 on c2.city_id = a.city_id)
select c.country, string_agg(cc, ', '), string_agg(cs, ', '), string_agg(cm, ', ')
from country c 
left join cte2 on cte2.country_id = c.country_id
group by c.country_id
order by 1

аренда 				платеж
диск				диск
сотрудник			сотрудник
покупатель			покупатель
диск 				сотрудник
сотрудник			диск 
сотрудник			покупатель
покупатель			сотрудник
покупатель			диск 
диск 				покупатель