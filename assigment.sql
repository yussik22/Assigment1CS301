WITH customer_spending AS (
    SELECT
        c.id AS customer_id,
        c.full_name,
        c.country AS customer_country,

        COUNT(t.id) AS transaction_count,
        SUM(t.amount) AS total_spent,
        AVG(t.amount) AS average_transaction_amount,

        COUNT(DISTINCT a.id) AS account_count,
        COUNT(DISTINCT cd.id) AS card_count,
        COUNT(DISTINCT m.category) AS merchant_category_count

    FROM customers c

    JOIN accounts a 
        ON c.id = a.customer_id

    JOIN transactions t 
        ON a.id = t.account_id

    LEFT JOIN cards cd 
        ON t.card_id = cd.id

    JOIN merchants m 
        ON t.merchant_id = m.id

    WHERE 
        t.status = 'completed'
        AND t.type = 'purchase'
        AND a.status = 'active'

    GROUP BY
        c.id,
        c.full_name,
        c.country
)

SELECT
    customer_id,
    full_name,
    customer_country,
    transaction_count,
    total_spent,
    average_transaction_amount,
    account_count,
    card_count,
    merchant_category_count,
    'VIP customer' AS customer_segment
FROM customer_spending
WHERE 
    total_spent >= 10000

UNION ALL

SELECT
    customer_id,
    full_name,
    customer_country,
    transaction_count,
    total_spent,
    average_transaction_amount,
    account_count,
    card_count,
    merchant_category_count,
    'Active customer' AS customer_segment
FROM customer_spending
WHERE 
    total_spent < 10000
    AND transaction_count >= 10

ORDER BY
    total_spent DESC;
