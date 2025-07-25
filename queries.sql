
--customers_count
select COUNT(*) customers_count from customers; -- функция подсчитывает количество записей в таблице (при условии, что каждая запись = покупатель, и они не дублируются)

--top_10_total_income

SELECT 
    CONCAT(e.first_name, ' ', e.last_name) AS seller , -- склеили имя и фамилию
    COUNT(s.sales_id) AS operations, -- посчитали количество сделок
    FLOOR(SUM(s.quantity * p.price)) AS income -- округлили в меньшую, посчитали на какую сумму продавец продал товаров
FROM sales s
JOIN employees e ON s.sales_person_id = e.employee_id -- соединили таблицы
JOIN products p ON s.product_id = p.product_id -- соединили таблицы
GROUP BY e.employee_id, e.first_name, e.last_name --сгруппировали поля 
ORDER BY income DESC; -- отсортировали

--lowest_average_income

WITH avg_sales_per_employee AS ( --создали CTE, высчитывающий среднее одного продавца
    SELECT 
        s.sales_person_id,
        CONCAT(e.first_name, ' ', e.last_name) AS seller, -- склеили имя и фамилию
        FLOOR(AVG(s.quantity * p.price)) AS average_income -- посчитали среднюю выручку и округлили
    FROM sales s
    JOIN employees e ON s.sales_person_id = e.employee_id -- соединили таблицы
    JOIN products p ON s.product_id = p.product_id -- соединили таблицы
    GROUP BY s.sales_person_id, e.first_name, e.last_name -- сгруппировали
),
overall_avg AS ( --создали CTE, подсчитывающее среднее между всех продавцов
    SELECT 
        FLOOR(AVG(quantity * price)) AS global_avg_deal_value
    FROM sales
    JOIN products USING(product_id)
)
SELECT 
    seller,
    average_income
FROM avg_sales_per_employee
JOIN overall_avg
    ON average_income < global_avg_deal_value -- сравнили среднее продавца и среднее продавцов
ORDER BY average_income ASC;


--day_of_the_week_income

SELECT 
 CONCAT(e.first_name, ' ', e.last_name) AS seller, -- склеили имя и фамилию
 CASE EXTRACT(DOW FROM s.sale_date) --отделили день недели
     WHEN 0 THEN 'Sunday'  WHEN 1 THEN 'Monday'
     WHEN 2 THEN 'Tuesday'
     WHEN 3 THEN 'Wednesday'
     WHEN 4 THEN 'Thursday'
     WHEN 5 THEN 'Friday'
     WHEN 6 THEN 'Saturday'
 END AS day_of_week,
 FLOOR(SUM(s.quantity * p.price)) AS total_revenue --суммировали выручку
FROM sales s
JOIN employees e ON s.sales_person_id = e.employee_id
JOIN products p ON s.product_id = p.product_id
GROUP BY 
 CONCAT(e.first_name, ' ', e.last_name),
 EXTRACT(DOW FROM s.sale_date)
ORDER BY 
 EXTRACT(DOW FROM s.sale_date),
 seller;
   
   
--age_groups

WITH age_sort AS ( --запрос, который разбивает возраста на категории 
    SELECT
        CASE 
            WHEN age BETWEEN 16 AND 25 THEN '16-25'
            WHEN age BETWEEN 26 AND 40 THEN '26-40'
            WHEN age >= 41 THEN '40+'
        END AS age_category,
        customer_id
    FROM customers
)
SELECT -- запрос, который выводит категории и подсчитывает количество покупателей в них
    age_category,
    COUNT(customer_id) AS age_count
FROM age_sort
GROUP BY age_category --сгруппировали по категориям
ORDER BY 
    CASE age_category -- в зависимости от возраста относим в одну из трёх категорий для подсчета
        WHEN '16-25' THEN 1
        WHEN '26-40' THEN 2
        WHEN '40+' THEN 3
    END;
	
-- customers_by_month

select CONCAT( --в этой строке мы по отдельности извлекаем год и месяц (к месяцу, если он меньше 10(двух знаков, как указано), добавляем перед числом 0 чтобы корректно работала сортировка по возрастанию)
        EXTRACT(year FROM sale_date),
        '-',
        LPAD(EXTRACT(month FROM sale_date)::text, 2, '0')
    ) AS selling_month,
COUNT(DISTINCT(customer_id)) as total_customers, --подсчитываем количество уникальных в месяце
FLOOR(SUM(sales.quantity * products.price)) as income -- считаем выручку
from sales
inner join products on --соединяем таблицы чтобы получить данные о ценах
sales.product_id=products.product_id
group by selling_month
order by selling_month; --сгруппировали и отсортировали по возрастанию
	
-- special_offer
	
WITH ranked_purchases AS ( -- CTE с помощью которого находятся покупки каждого покупателя и нумеруются, начиная с первой
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY (customer_id) order by sale_date) as rn
    FROM sales
)
SELECT
    CONCAT(customers.first_name, ' ', customers.last_name) as customer, --склеили имя и фамилию покупателя
    sale_date,
    CONCAT(employees.first_name, ' ', employees.last_name) as seller --склеили имя и фамилию продавца
FROM ranked_purchases
INNER JOIN customers ON ranked_purchases.customer_id = customers.customer_id --присоединили таблицы которые нужны для имени и фамилии
INNER JOIN employees ON ranked_purchases.sales_person_id = employees.employee_id --присоединили таблицы которые нужны для имени и фамилии
INNER JOIN products ON ranked_purchases.product_id = products.product_id --присоединили таблицу чтобы узнать стоимость покупки
WHERE rn = 1
  AND (ranked_purchases.quantity * products.price) = 0  --отобрали тех, кто в первый раз закупился на 0 (по акции) и у кого эта покупка была первой (взяли первую строчку из оконной функции каждого покупателя)
ORDER BY ranked_purchases.customer_id;
	