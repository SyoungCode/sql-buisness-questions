/* ==========================================================

   OLIST E-COMMERCE SQL PROJECT

   Business Questions & Queries



   Tables:

     olist_orders_dataset

     olist_order_items_dataset

     olist_order_payments_dataset

     olist_order_reviews_dataset

     olist_customers_dataset

     olist_products_dataset

     olist_sellers_dataset

     olist_geolocation_dataset

     product_category_name_translation

   ========================================================== */





/* ==========================================================

   SECTION 1: SALES & REVENUE

   ========================================================== */



-- Q1. How many orders were canceled, and what does that list look like?

SELECT COUNT(*) AS canceled_order_count

FROM olist_orders_dataset

WHERE order_status = 'canceled';



SELECT

    order_id,

    customer_id,

    order_status,

    order_purchase_timestamp

FROM olist_orders_dataset

WHERE order_status = 'canceled'

ORDER BY order_purchase_timestamp DESC;



-- Q2. How many orders were placed during a given time window?

SELECT COUNT(*) AS order_count

FROM olist_orders_dataset

WHERE order_purchase_timestamp BETWEEN '2018-01-01' AND '2018-03-31';



-- Q3. What was our total revenue and order volume for each month?

SELECT

    strftime('%Y-%m', o.order_purchase_timestamp) AS order_month,

    COUNT(DISTINCT o.order_id) AS order_count,

    SUM(oi.price) AS total_revenue

FROM olist_orders_dataset o JOIN olist_order_items_dataset oi

ON o.order_id = oi.order_id

GROUP BY order_month

ORDER BY order_month;





-- Q4. Which product categories generate the most revenue?

SELECT t.product_category_name_english AS category,

    SUM(o.price) AS revenue

FROM olist_products_dataset p

JOIN olist_order_items_dataset o ON p.product_id = o.product_id

JOIN product_category_name_translation t ON p.product_category_name = t.product_category_name

GROUP BY category

ORDER BY revenue DESC;



-- Q5. Which customers are spending more than the average customer?

WITH customer_totals AS (

	SELECT c.customer_unique_id AS customer,

		SUM(p.payment_value) AS total_spent

		FROM olist_customers_dataset c JOIN olist_orders_dataset o 

		ON c.customer_id = o.customer_id JOIN olist_order_payments_dataset p 

		ON o.order_id = p.order_id

		GROUP BY c.customer_unique_id

)

SELECT customer, total_spent

FROM customer_totals

WHERE total_spent > (SELECT AVG(total_spent) FROM customer_totals)

ORDER BY total_spent DESC;



-- Q6. What does our cumulative revenue look like as the year progresses?

WITH monthly_revenue AS (

	SELECT strftime('%Y-%m', o.order_purchase_timestamp) AS month, 

		SUM(p.payment_value) as revenue

	FROM olist_order_payments_dataset p JOIN olist_orders_dataset o

	ON p.order_id = o.order_id

	GROUP BY month

)

SELECT month, revenue, SUM(revenue) OVER(ORDER BY month) as cumulative_total

FROM monthly_revenue

ORDER BY month;





-- Q7. How much did revenue grow or shrink compared to the previous month?

WITH monthly_revenue AS (

    SELECT strftime('%Y-%m', o.order_purchase_timestamp) AS month,

           SUM(p.payment_value) AS revenue

    FROM olist_order_payments_dataset p

    JOIN olist_orders_dataset o ON p.order_id = o.order_id

    GROUP BY month

)



SELECT month, revenue, 

	LAG(revenue) OVER(ORDER BY month) as prev_month_revenue,

	revenue - LAG(revenue) OVER(ORDER BY month) as revenue_change

FROM monthly_revenue

ORDER BY month;





-- Q8. Who are our top-spending customers, and how would we split them into

--     value tiers (e.g. top 25%, next 25%, etc.)?

WITH customer_totals AS (

    SELECT c.customer_unique_id AS customer,

           SUM(p.payment_value) AS total_spent

    FROM olist_customers_dataset c

    JOIN olist_orders_dataset o ON c.customer_id = o.customer_id

    JOIN olist_order_payments_dataset p ON o.order_id = p.order_id

    GROUP BY c.customer_unique_id

)

SELECT customer,

	total_spent,

    NTILE(4) OVER (ORDER BY total_spent DESC) AS spend_tier

FROM customer_totals

ORDER BY total_spent DESC;



-- Q9. Do higher-value orders tend to get better or worse reviews than

--     standard-value orders?

WITH order_totals AS (

    SELECT p.order_id,

	SUM(p.payment_value) AS order_total

    FROM olist_order_payments_dataset p

    GROUP BY p.order_id

),

order_value_tier AS (

    SELECT ot.order_id,

           ot.order_total,

           CASE

               WHEN ot.order_total > (SELECT AVG(order_total) FROM order_totals) THEN 'high value'

               ELSE 'standard'

           END AS value_tier

    FROM order_totals ot

)

SELECT vt.value_tier,

       AVG(r.review_score) AS avg_review_score,

       COUNT(*) AS order_count

FROM order_value_tier vt

JOIN olist_order_reviews_dataset r ON vt.order_id = r.order_id

GROUP BY vt.value_tier;

	



/* ==========================================================

   SECTION 2: PRODUCTS & CATEGORIES

   ========================================================== */



-- Q10. What product categories do we actually sell?

SELECT DISTINCT product_category_name AS categories

FROM olist_products_dataset;



-- Q11. What are our product category names in plain English, for

--      reporting purposes?

SELECT DISTINCT t.product_category_name_english AS english_names

FROM olist_products_dataset p JOIN product_category_name_translation t

ON p.product_category_name = t.product_category_name;



-- Q12. Which products have never been sold at all?

SELECT p.product_id

FROM olist_products_dataset p

LEFT JOIN olist_order_items_dataset oi ON p.product_id = oi.product_id

WHERE oi.order_id IS NULL;



-- Q13. Which product categories have the best average customer

--      satisfaction — but only counting categories with a meaningful

--      number of reviews, so we're not misled by one or two ratings?

SELECT p.product_category_name AS category, AVG(r.review_score ) AS review

FROM olist_products_dataset p 

JOIN olist_order_items_dataset o ON p.product_id = o.product_id

JOIN olist_order_reviews_dataset r ON o.order_id = r.order_id

GROUP BY category

HAVING COUNT(*) > 50

ORDER BY review DESC;



/* ==========================================================

   SECTION 3: CUSTOMERS

   ========================================================== */



-- Q14. What is the average value of a customer over their whole

--      relationship with us, and how does that vary by state?

WITH info AS (

	SELECT c.customer_unique_id as id, SUM(p.payment_value) AS total_spent, c.customer_state AS state

	FROM olist_customers_dataset c 

	JOIN olist_orders_dataset o ON c.customer_id = o.customer_id

	JOIN olist_order_payments_dataset p ON o.order_id = p.order_id

	GROUP BY id

)

SELECT state, AVG(total_spent) AS avg_customer_value

FROM info

GROUP BY state

ORDER BY avg_customer_value DESC;



-- Q15. Of customers who made their first purchase in a given month, how

--      many come back and buy again in later months?

WITH customer_orders AS (

    SELECT c.customer_unique_id AS id,

           o.order_purchase_timestamp AS order_date

    FROM olist_customers_dataset c

    JOIN olist_orders_dataset o ON c.customer_id = o.customer_id

),

first_purchase AS (

    SELECT id, MIN(order_date) AS first_order_date

    FROM customer_orders

    GROUP BY id

)

SELECT COUNT(DISTINCT co.id) AS returning_customers_calendar_month

FROM customer_orders co

JOIN first_purchase fp ON co.id = fp.id

WHERE strftime('%Y-%m', co.order_date) != strftime('%Y-%m', fp.first_order_date);



/*

SELECT COUNT(DISTINCT co.id) AS returning_customers_30_day_gap

FROM customer_orders co

JOIN first_purchase fp ON co.id = fp.id

WHERE julianday(co.order_date) - julianday(fp.first_order_date) >= 30;

*/



-- Q16. How long, on average, do repeat customers wait before placing a

--      second order?

WITH customer_orders AS (

    SELECT c.customer_unique_id AS id,

           o.order_purchase_timestamp AS order_date

    FROM olist_customers_dataset c

    JOIN olist_orders_dataset o ON c.customer_id = o.customer_id

),

ranked_orders AS (

    SELECT id, order_date,

    ROW_NUMBER() OVER (PARTITION BY id ORDER BY order_date ASC) AS order_number

    FROM customer_orders

)

SELECT AVG(julianday(second.order_date) - julianday(first.order_date)) AS avg_days_to_second_order

FROM ranked_orders first

JOIN ranked_orders second ON first.id = second.id

WHERE first.order_number = 1 AND second.order_number = 2;





-- Q17. How does each individual order compare to what a "typical" order

--      looks like for us?

WITH order_totals AS (

    SELECT o.order_id,

           SUM(oi.price) AS order_total

    FROM olist_orders_dataset o

    JOIN olist_order_items_dataset oi ON o.order_id = oi.order_id

    GROUP BY o.order_id

)

SELECT order_id,

       order_total,

       ROUND(AVG(order_total) OVER (), 2) AS avg_order_value,

       ROUND(order_total - AVG(order_total) OVER (), 2) AS difference_from_avg

FROM order_totals;





/* ==========================================================

   SECTION 4: SELLERS

   ========================================================== */



-- Q18. Which sellers are our highest-volume shippers?

SELECT seller_id, COUNT(*) AS volume

FROM olist_order_items_dataset 

GROUP BY seller_id 

ORDER BY volume DESC;





-- Q19. Who are the top-performing sellers within each product category?

WITH seller_performance AS (

    SELECT o.seller_id AS seller, SUM(o.price) AS sold, p.product_category_name AS category  

    FROM olist_products_dataset p JOIN olist_order_items_dataset o

    ON p.product_id = o.product_id 

    GROUP BY seller, category

),

ranked_sellers AS (

    SELECT seller, sold, category,

           ROW_NUMBER() OVER (PARTITION BY category ORDER BY sold DESC) AS rank

    FROM seller_performance

)

SELECT seller, sold, category

FROM ranked_sellers

WHERE rank = 1;



-- Q20. Which sellers are strong in both revenue and customer

--      satisfaction, and which are only strong in one or the other?

WITH seller_revenue AS (

    SELECT seller_id,

           SUM(price) AS revenue,

           NTILE(4) OVER (ORDER BY SUM(price) DESC) AS revenue_tier

    FROM olist_order_items_dataset

    GROUP BY seller_id

),

seller_satisfaction AS (

    SELECT oi.seller_id,

           AVG(r.review_score) AS avg_score,

           NTILE(4) OVER (ORDER BY AVG(r.review_score) DESC) AS satisfaction_tier

    FROM olist_order_items_dataset oi

    JOIN olist_order_reviews_dataset r ON oi.order_id = r.order_id

    GROUP BY oi.seller_id

)

SELECT rev.seller_id,

       rev.revenue,

       sat.avg_score,

       CASE

           WHEN rev.revenue_tier = 1 AND sat.satisfaction_tier = 1 THEN 'strong in both'

           WHEN rev.revenue_tier = 1 THEN 'strong in revenue only'

           WHEN sat.satisfaction_tier = 1 THEN 'strong in satisfaction only'

           ELSE 'not top tier in either'

       END AS performance_label

FROM seller_revenue rev

JOIN seller_satisfaction sat ON rev.seller_id = sat.seller_id

WHERE rev.revenue_tier = 1 OR sat.satisfaction_tier = 1

ORDER BY performance_label;



-- Q21. Which sellers are based in a specific city or region

--      (e.g. Sao Paulo)?

SELECT seller_id, seller_city, seller_state

FROM olist_sellers_dataset

WHERE seller_city = 'sao paulo';



/* ==========================================================

   SECTION 5: DELIVERY & LOGISTICS

   ========================================================== */



-- Q22. What's our best, worst, and average delivery time?

SELECT 

MIN(julianday(order_delivered_customer_date) - julianday(order_purchase_timestamp)) AS best_delivery_time,

MAX(julianday(order_delivered_customer_date) - julianday(order_purchase_timestamp)) AS worst_delivery_time,

AVG(julianday(order_delivered_customer_date) - julianday(order_purchase_timestamp)) AS avg_delivery_time

FROM olist_orders_dataset;



-- Q23. What proportion of orders arrive early, on time, or late?

WITH delivery_status AS (

    SELECT

        CASE

            WHEN strftime('%Y-%m-%d', order_delivered_customer_date) < strftime('%Y-%m-%d', order_estimated_delivery_date) THEN 'early'

            WHEN strftime('%Y-%m-%d', order_delivered_customer_date) = strftime('%Y-%m-%d', order_estimated_delivery_date) THEN 'on time'

            ELSE 'late'

        END AS status

    FROM olist_orders_dataset

    WHERE order_delivered_customer_date IS NOT NULL

)

SELECT status,

       COUNT(*) AS order_count,

       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS percentage

FROM delivery_status

GROUP BY status;



-- Q24. How many days does it typically take for an order to reach the

--      customer?

SELECT AVG(julianday(order_delivered_customer_date) - julianday(order_purchase_timestamp)) AS avg_days_to_deliver

FROM olist_orders_dataset

WHERE order_delivered_customer_date IS NOT NULL;



-- Q25. How common is it for an order to be shipped from a seller in one

--      state to a customer in another — and does that affect delivery

--      time?

WITH order_state_info AS (

    SELECT o.order_id,

           s.seller_state,

           c.customer_state,

           julianday(o.order_delivered_customer_date) - julianday(o.order_purchase_timestamp) AS delivery_days,

           CASE WHEN s.seller_state = c.customer_state THEN 'same state' ELSE 'cross state' END AS shipping_type

    FROM olist_orders_dataset o

    JOIN olist_customers_dataset c ON o.customer_id = c.customer_id

    JOIN olist_order_items_dataset oi ON o.order_id = oi.order_id

    JOIN olist_sellers_dataset s ON oi.seller_id = s.seller_id

    WHERE o.order_delivered_customer_date IS NOT NULL

)

SELECT shipping_type,

       COUNT(DISTINCT order_id) AS order_count,

       AVG(delivery_days) AS avg_delivery_days

FROM order_state_info

GROUP BY shipping_type;



-- Q26. Which days of the week see the most orders come in?

SELECT 

    CASE strftime('%w', order_purchase_timestamp)

        WHEN '0' THEN 'Sunday' WHEN '1' THEN 'Monday' WHEN '2' THEN 'Tuesday'

        WHEN '3' THEN 'Wednesday' WHEN '4' THEN 'Thursday' WHEN '5' THEN 'Friday'

        WHEN '6' THEN 'Saturday'

    END AS day_of_week,

    COUNT(*) AS order_count

FROM olist_orders_dataset

GROUP BY day_of_week

ORDER BY order_count DESC;



-- Q27. What time of day do most orders get placed?

SELECT strftime('%H', order_purchase_timestamp) AS hour_of_day,

       COUNT(*) AS order_count

FROM olist_orders_dataset

GROUP BY hour_of_day

ORDER BY order_count DESC;





/* ==========================================================

   SECTION 6: REVIEWS & SATISFACTION

   ========================================================== */



-- Q28. How many orders never received a customer review at all?

SELECT COUNT(*) AS orders_without_review

FROM olist_orders_dataset o

LEFT JOIN olist_order_reviews_dataset r ON o.order_id = r.order_id

WHERE r.review_id IS NULL;



-- Q29. What share of our reviews are positive, neutral, or negative

--      overall?

WITH review_sentiment AS (

    SELECT

        CASE

            WHEN review_score >= 4 THEN 'positive'

            WHEN review_score = 3 THEN 'neutral'

            ELSE 'negative'

        END AS sentiment

    FROM olist_order_reviews_dataset

)

SELECT sentiment,

       COUNT(*) AS review_count,

       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS percentage

FROM review_sentiment

GROUP BY sentiment;



-- Q30. How many customers leave a written comment with their review,

--      versus just a star rating?

SELECT

    COUNT(*) AS total_reviews,

    COUNT(review_comment_message) AS reviews_with_comment,

    COUNT(*) - COUNT(review_comment_message) AS reviews_without_comment

FROM olist_order_reviews_dataset;



-- Q31. Can we produce a clean report where missing review comments are

--      shown as "No comment" instead of being blank?

SELECT review_id,

       review_score,

       COALESCE(review_comment_message, 'No comment') AS comment

FROM olist_order_reviews_dataset;





/* ==========================================================

   SECTION 7: OPERATIONAL / REPORTING

   ========================================================== */



-- Q32. Can we produce a single, full order history report — showing

--      customer location, order date, product category, and review

--      score together in one place?

SELECT o.order_id,

       c.customer_city,

       c.customer_state,

       o.order_purchase_timestamp,

       t.product_category_name_english AS category,

       r.review_score

FROM olist_orders_dataset o

JOIN olist_customers_dataset c ON o.customer_id = c.customer_id

JOIN olist_order_items_dataset oi ON o.order_id = oi.order_id

JOIN olist_products_dataset p ON oi.product_id = p.product_id

LEFT JOIN product_category_name_translation t ON p.product_category_name = t.product_category_name

LEFT JOIN olist_order_reviews_dataset r ON o.order_id = r.order_id;



-- Q33. How many unique cities do we actually operate in, once

--      inconsistent spelling and capitalization in the data are

--      cleaned up?

SELECT DISTINCT TRIM(LOWER(customer_city)) AS clean_city

FROM olist_customers_dataset

ORDER BY clean_city;



-- Q34. Can we build a standard "seller performance" report that could

--      be reused for future monthly or quarterly reviews?

CREATE VIEW seller_performance AS

SELECT oi.seller_id,

       COUNT(*) AS items_sold,

       SUM(oi.price) AS total_revenue,

       AVG(r.review_score) AS avg_review_score

FROM olist_order_items_dataset oi

LEFT JOIN olist_order_reviews_dataset r ON oi.order_id = r.order_id

GROUP BY oi.seller_id;