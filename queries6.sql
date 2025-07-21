--первое задание 

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
	
-- второе задание

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
	
-- третье задание 
	
WITH ranked_purchases AS ( -- CTE с помощью которого находятся покупки каждого покупателя и нумеруются, начиная с первой
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY DATE(sale_date) ORDER BY sale_date) as rn
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
  AND (ranked_purchases.quantity * products.price) < 1 --отобрали тех, кто в первый раз закупился на 0 (по акции) и у кого эта покупка была первой (взяли первую строчку из оконной функции каждого покупателя)
ORDER BY ranked_purchases.customer_id;

	
	