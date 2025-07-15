--первое задание

SELECT 
    CONCAT(e.first_name, ' ', e.last_name) AS seller , -- склеили имя и фамилию
    COUNT(s.sales_id) AS operations, -- посчитали количество сделок
    FLOOR(SUM(s.quantity * p.price)) AS income -- округлили в меньшую, посчитали на какую сумму продавец продал товаров
FROM sales s
JOIN employees e ON s.sales_person_id = e.employee_id -- соединили таблицы
JOIN products p ON s.product_id = p.product_id -- соединили таблицы
GROUP BY e.employee_id, e.first_name, e.last_name --сгруппировали поля 
ORDER BY income DESC; -- отсортировали

--второе задание

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


--третье задание 

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
   