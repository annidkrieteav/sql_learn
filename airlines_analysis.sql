SET search_path TO bookings;

--1. Выведите название самолетов, которые имеют менее 50 посадочных мест?

select 
	a.aircraft_code, 
	a.model, 
	count(*)
from 
	aircrafts a 
	left join 
		seats s on a.aircraft_code = s.aircraft_code 
group by 
	a.aircraft_code 
having 
	count(*) < 50

--2. Выведите процентное изменение ежемесячной суммы бронирования билетов, округленной до сотых.

with cte as (
	select 
		date_trunc('month', book_date) as book_month, 
		sum(total_amount) as monthly_total, 
		round(((sum(total_amount) - lag(sum(total_amount), 1, sum(total_amount)) over (order by date_trunc('month', book_date))) / lag(sum(total_amount), 1, sum(total_amount)) over (order by date_trunc('month', book_date))) * 100, 2) as monthly_change
	from 
		bookings b 
	group by 
		date_trunc('month', book_date))
select 
	t."generate_series", cte.monthly_total, cte.monthly_change
from 
	cte
	left join (
		select 
			generate_series (min(book_month), max(book_month), '1 month'::interval)
		from cte) t on cte.book_month = t."generate_series"

--3. Выведите названия самолетов не имеющих бизнес - класс. Решение должно быть через функцию array_agg.

select 
	a.aircraft_code, 
	a.model, 
	array_agg(distinct(s.fare_conditions))
from 
	seats s
	join 
		aircrafts a on s.aircraft_code = a.aircraft_code 
group by 
	a.aircraft_code
having 
	not (array['Business'::varchar] && array_agg(distinct(s.fare_conditions)))

--4. Вывести накопительный итог количества мест в самолетах по каждому аэропорту на каждый день,
--	 учитывая только те самолеты, которые летали пустыми и только те дни, 
--   где из одного аэропорта таких самолетов вылетало более одного.
--   В результате должны быть код аэропорта, дата, количество пустых мест в самолете и накопительный итог.
	
with cte1 as 
(
    select 
        a.aircraft_code, 
        count(*) as seats
    from 
        aircrafts a 
        left join 
            seats s on a.aircraft_code = s.aircraft_code 
    group by 
        a.aircraft_code
)
select 
    a2.airport_code, 
    f.actual_departure::date, 
    f.actual_departure,
    c.seats,
    sum(c.seats) over (partition by a2.airport_code, f.actual_departure::date order by f.actual_departure) as day_seats_running
from 
    flights f 
    left join 
        boarding_passes bp on f.flight_id = bp.flight_id 
    join 
        cte1 c on f.aircraft_code = c.aircraft_code
    left join 
        airports a2 on f.departure_airport = a2.airport_code 
where 
    bp.flight_id is null 
    and f.actual_departure is not null
    and (a2.airport_code, f.actual_departure::date) not in (
        select a2.airport_code, f.actual_departure::date
        from 
        	flights f 
   			left join
   				boarding_passes bp on f.flight_id = bp.flight_id 
    		join 
        		cte1 c on f.aircraft_code = c.aircraft_code
    		left join 
        		airports a2 on f.departure_airport = a2.airport_code 
        where
    		bp.flight_id is null 
    		and f.actual_departure is not null
        group by 
            a2.airport_code, f.actual_departure::date
        having count(*) = 1)

--5. Найдите процентное соотношение перелетов по маршрутам от общего количества перелетов.
-- Выведите в результат названия аэропортов и процентное отношение.
-- Решение должно быть через оконную функцию.

select 
    a1.airport_name, 
    a2.airport_name, 
    round(count(*) * 100.0 / sum(count(*)) over (), 2) as percentage
from
    flights f
    join airports a1 on f.departure_airport = a1.airport_code 
    join airports a2 on f.arrival_airport = a2.airport_code 
group by a1.airport_name, a2.airport_name
order by a1.airport_name, a2.airport_name

--6. Выведите количество пассажиров по каждому коду сотового оператора, если учесть, что код оператора - это три символа после +7

select 
	substring(contact_data->>'phone' from 3 for 3), 
	count(*)
from 
	tickets
group by 
	substring(contact_data->>'phone' from 3 for 3)
order by 1 asc

--7. Классифицируйте финансовые обороты (сумма стоимости перелетов) по маршрутам:
-- До 50 млн - low
-- От 50 млн включительно до 150 млн - middle
-- От 150 млн включительно - high
-- Выведите в результат количество маршрутов в каждом полученном классе
	
select 
	case
		when total < 50000000 then 'low'
		when total between 50000000 and 150000000 then 'middle'
		else 'high'
		end as classified, 
	count(*)
from 
(
	select 
		departure_airport, 
		arrival_airport, 
		sum(amount) as total
	from 
		flights f 
		join ticket_flights tf on f.flight_id = tf.flight_id 
	group by 
		departure_airport, 
		arrival_airport 
) as t
group by classified
order by count

--8. Вычислите медиану стоимости перелетов, медиану размера бронирования и отношение медианы бронирования к медиане стоимости перелетов, округленной до сотых

select 
	t.median_flight, 
	h.median_booking,
	round((h.median_booking / t.median_flight)::numeric, 2) as relation
from 
	(
		select 
			percentile_cont(0.5) within group (order by amount) as median_flight
		from 
			ticket_flights tf
	) t,
	(
		select
			percentile_cont(0.5) within group (order by total_amount) as median_booking
		from
			bookings b
	) h
	
--9. Найдите значение минимальной стоимости полета 1 км для пассажиров. То есть нужно найти расстояние между аэропортами и с учетом стоимости перелетов получить искомый результат
--  Для поиска расстояния между двумя точками на поверхности Земли используется модуль earthdistance.
--  Для работы модуля earthdistance необходимо предварительно установить модуль cube.
--  Установка модулей происходит через команду: create extension название_модуля.

create extension cube;
create extension earthdistance;

with distances as 
(
	select 
		f.flight_id, 
		earth_distance(ll_to_earth(a.latitude, a.longitude), ll_to_earth(a2.latitude, a2.longitude)) / 1000.0 as distance_km
	from
		flights f 
		join airports a on f.departure_airport = a.airport_code 
		join airports a2 on f.arrival_airport = a2.airport_code 
)
select 
	amount / d.distance_km
from
	ticket_flights tf
	join distances d on tf.flight_id = d.flight_id
order by 1 asc 
limit 1
	
	