--customers_count
select COUNT(*) as customers_count
from customers;/*
функция подсчитывает количество записей в таблице
(при условии, что каждая запись = покупатель,
и они не дублируются)*/
--top_10_total_income
select
    CONCAT(e.first_name, ' ', e.last_name) as seller, -- склеили имя и фамилию
    COUNT(s.sales_id) as operations, -- посчитали количество сделок
    FLOOR(SUM(s.quantity * p.price)) as income/*округлили
в меньшую, посчитали на какую сумму
продавец продал товаров*/
from sales as s
-- соединили таблицы
inner join employees as e on s.sales_person_id = e.employee_id
inner join products as p on s.product_id = p.product_id -- соединили таблицы
group by e.employee_id, e.first_name, e.last_name --сгруппировали поля 
order by income desc -- отсортировали
limit 10; -- ограничили вывод
--lowest_average_income
--создали CTE, высчитывающий среднее одного продавца
with avg_sales_per_employee as (
    select
        s.sales_person_id,
        -- склеили имя и фамилию
        CONCAT(e.first_name, ' ', e.last_name) as seller,
        -- посчитали среднюю выручку и округлили
        FLOOR(AVG(s.quantity * p.price)) as average_income
    from sales as s
    -- соединили таблицы
    inner join employees as e on s.sales_person_id = e.employee_id
    inner join products as p on s.product_id = p.product_id -- соединили таблицы
    group by s.sales_person_id, e.first_name, e.last_name -- сгруппировали
),

overall_avg as ( --создали CTE, подсчитывающее среднее между всех продавцов
    select FLOOR(AVG(sales.quantity * products.price)) as global_avg_deal_value
    from sales
    inner join products on sales.product_id = products.product_id
)

select
    avg_sales_per_employee.seller,
    avg_sales_per_employee.average_income
from avg_sales_per_employee
inner join overall_avg
    -- сравнили среднее продавца и среднее продавцов
    on avg_sales_per_employee.average_income < overall_avg.global_avg_deal_value
order by avg_sales_per_employee.average_income asc;
--day_of_the_week_income
select
    CONCAT(e.first_name, ' ', e.last_name) as seller, -- склеили имя и фамилию
    CASE extract(DOW from s.sale_date) --отделили день недели
        when 0 then 'Sunday' when 1 then 'Monday'
        when 2 then 'Tuesday'
        when 3 then 'Wednesday'
        when 4 then 'Thursday'
        when 5 then 'Friday'
        when 6 then 'Saturday'
    END as day_of_week,
    FLOOR(SUM(s.quantity * p.price)) as total_revenue --суммировали выручку
from sales as s
inner join employees as e on s.sales_person_id = e.employee_id
inner join products as p on sales.product_id = products.product_id
group by
    ConCAT(e.first_name, ' ', e.last_name),
    extract(DOW from s.sale_date)
order by
    extract(DOW from s.sale_date),
    seller;
WITH age_sort as ( --запрос, который разбивает возраста на категории 
    select
        CASE
            when age BETWEEN 16 AND 25 then '16-25'
            when age BETWEEN 26 AND 40 then '26-40'
            when age >= 41 then '40+'
        END as age_category,
        customer_id
    from customers
)

select
/*запрос, который выводит категории и
подсчитывает количество покупателей в них*/
    age_category,
    COUNT(customer_id) as age_count
from age_sort
group by age_category--сгруппировали по категориям
order by
    CASE age_category
        /*в зависимости от возраста относим в одну из
        трёх категорий для подсчета*/
        when '16-25' then 1
        when '26-40' then 2
        when '40+' then 3
    END;
-- customers_by_month
select
    ConCAT(
    /*в этой строке мы по отдельности извлекаем год и месяц
    (к месяцу, если он меньше 10
    (двух знаков, как указано),
    добавляем перед числом 0,
    чтобы корректно работала сортировка по возрастанию)*/
        extract(year from sales.sale_date),
        '-',
        LPAD(extract(month from sales.sale_date)::text, 2, '0')
    ) as selling_month,
    COUNT(DISTINCT(sales.customer_id)) as total_customers,
    /*подсчитываем количество уникальных в месяце*/
    FLOOR(SUM(sales.quantity * products.price)) as income -- считаем выручку
from sales
inner join products on
/*соединяем таблицы чтобы получить данные о ценах*/
        sales.product_id = products.product_id
group by selling_month
order by selling_month; --сгруппировали и отсортировали по возрастанию
-- special_offer
WITH ranked_purchases as (
/*CTE с помощью которого находятся покупки
каждого покупателя и нумеруются, начиная с первой*/
    select
        *,
        ROW_NUMBER() OVER (PARTITIon BY (customer_id) order by sale_date) as rn
    from sales
)

select
    ConCAT(customers.first_name, ' ', customers.last_name) as customer,
    /*склеили имя и фамилию покупателя*/
    ranked_purchases.sale_date,
    ConCAT(employees.first_name, ' ', employees.last_name) as seller
    /*склеили имя и фамилию продавца*/
from ranked_purchases
inner join customers on ranked_purchases.customer_id = customers.customer_id
/*присоединили таблицы которые нужны для имени
и фамилии*/
inner join employees on ranked_purchases.sales_person_id = employees.employee_id
/*присоединили таблицы которые нужны для имени и фамилии*/
inner join products on ranked_purchases.product_id = products.product_id
/*присоединили таблицу чтобы узнать стоимость покупки*/
WHERE rn = 1
    AND (ranked_purchases.quantity * products.price) = 0  
  /*отобрали тех, кто в первый раз закупился на
  0 (по акции) и у кого эта покупка была первой
  (взяли первую строчку из оконной функции
  каждого покупателя)*/
order by ranked_purchases.customer_id;
