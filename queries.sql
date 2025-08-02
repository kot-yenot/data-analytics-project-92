--customers_count
select COUNT(*) as customers_count
from customers;/*
функция подсчитывает количество записей в таблице*/
--top_10_total_income
select
    CONCAT(e.first_name, ' ', e.last_name) as seller, -- склеили имя и фамилию
    COUNT(s.sales_id) as operations, -- посчитали количество сделок
    FLOOR(SUM(s.quantity * p.price)) as income
from sales as s
-- соединили таблицы
inner join employees as e on s.sales_person_id = e.employee_id
inner join products as p on s.product_id = p.product_id 
group by seller
order by income desc 
limit 10;

--lowest_average_income
WITH overall_avg AS ( -- CTE для среднего значения сделок по всем продавцам
    SELECT FLOOR(AVG(s.quantity * p.price)) AS global_avg_deal_value
    FROM sales AS s
    INNER JOIN products AS p ON s.product_id = p.product_id
)
SELECT 
    CONCAT(e.first_name, ' ', e.last_name) AS seller,
    FLOOR(AVG(s.quantity * p.price)) AS average_income
FROM sales AS s
INNER JOIN employees AS e ON s.sales_person_id = e.employee_id
INNER JOIN products AS p ON s.product_id = p.product_id
CROSS JOIN overall_avg  -- соединяем с CTE для фильтрации
GROUP BY seller
HAVING FLOOR(AVG(s.quantity * p.price)) < (SELECT global_avg_deal_value FROM overall_avg)  -- фильтруем по среднему
ORDER BY average_income ASC;
-- day_of_the_week_income
SELECT
    CONCAT(e.first_name, ' ', e.last_name) AS seller,
    TO_CHAR(s.sale_date, 'Day') AS day_of_week, 
    FLOOR(SUM(s.quantity * p.price)) AS total_revenue
FROM sales AS s
INNER JOIN employees AS e ON s.sales_person_id = e.employee_id
INNER JOIN products AS p ON s.product_id = p.product_id
GROUP BY
    seller,
    day_of_week,
    EXTRACT(ISODOW FROM s.sale_date)
ORDER BY
    EXTRACT(ISODOW FROM s.sale_date),  -- Сортировка по номеру дня (пн-вс)
    seller;
-- age_groups
SELECT
    age_category,
    COUNT(customer_id) AS age_count
FROM (
    SELECT
        customer_id,
        CASE
            WHEN age BETWEEN 16 AND 25 THEN '16-25'
            WHEN age BETWEEN 26 AND 40 THEN '26-40'
            WHEN age >= 41 THEN '40+'
        END AS age_category,
        CASE
            WHEN age BETWEEN 16 AND 25 THEN 1
            WHEN age BETWEEN 26 AND 40 THEN 2
            WHEN age >= 41 THEN 3
        END AS sort_order
    FROM customers
) AS categorized
GROUP BY age_category, sort_order
ORDER BY sort_order;

-- customers_by_month
select
    CONCAT(
    /*в этой строке мы по отдельности извлекаем год и месяц
    (к месяцу, если он меньше 10
    (двух знаков, как указано),
    добавляем перед числом 0,
    чтобы корректно работала сортировка по возрастанию)*/
        EXTRACT(year from sales.sale_date), '-',
        LPAD(EXTRACT(month from sales.sale_date)::text, 2, '0')
    ) as selling_month,
    COUNT(distinct sales.customer_id) as total_customers,
    /*подсчитываем количество уникальных в месяце*/
    FLOOR(SUM(sales.quantity * products.price)) as income -- считаем выручку
from sales
inner join products on sales.product_id = products.product_id
/*соединяем таблицы чтобы получить данные о ценах*/
group by selling_month
order by selling_month; --сгруппировали и отсортировали по возрастанию
-- special_offer
SELECT DISTINCT ON (s.customer_id)
    s.sale_date,
    CONCAT(c.first_name, ' ', c.last_name) AS customer,
    CONCAT(e.first_name, ' ', e.last_name) AS seller
FROM sales s
INNER JOIN customers c ON s.customer_id = c.customer_id
INNER JOIN employees e ON s.sales_person_id = e.employee_id
INNER JOIN products p ON s.product_id = p.product_id
WHERE (s.quantity * p.price) = 0
ORDER BY s.customer_id, s.sale_date;
