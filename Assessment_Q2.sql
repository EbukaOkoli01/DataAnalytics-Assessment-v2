USE adashi_staging;

/*
Task: Calculate the average number of transactions per customer per month and categorize them:
"High Frequency" (≥10 transactions/month) | "Medium Frequency" (3-9 transactions/month) | "Low Frequency" (≤2 transactions/month)
*/


SELECT DISTINCT(MONTH(transaction_date))
FROM savings_savingsaccount;

-- 1st: Let's Extract month of customer transaction from transaction_date
WITH month_extraction AS
	(
	SELECT 
			s.owner_id,
			MONTH(transaction_date) AS transaction_month -- TO get the month from the transaction date
	FROM savings_savingsaccount AS s
	INNER JOIN users_customuser AS u
    ON s.owner_id = u.id
    ),
-- 2nd:I can now obtain the count of transactions per month by each customer
transact_count AS
 	( 
  SELECT 
			owner_id,
            transaction_month,
            COUNT(*) AS transaction_per_month -- To count the total transactions carried out per month for each customer
    FROM month_extraction
    GROUP BY owner_id, transaction_month 
    ORDER BY owner_id, transaction_month
	) ,
-- 3rd: I went ahead to get the average transactions per month for each customer
average_transact_per_month AS
	( 
	 SELECT owner_id,
				AVG(transaction_per_month) AS avg_transaction_per_month
		FROM transact_count
		GROUP BY owner_id
	),
-- 4th: I used CASE statement to categorize customers into different groups
categorize_customer AS 
	(
    SELECT *,
			CASE
				-- we need to ROUND the average_transact_per_month to a whole number so it can fit the condition (10, 3-9, 2) and no value is missed
				WHEN ROUND(avg_transaction_per_month,0) >= 10 THEN 'High Frequency'
                WHEN ROUND(avg_transaction_per_month,0) BETWEEN 3 AND 9 THEN 'Medium Frequency'
                WHEN ROUND(avg_transaction_per_month,0) <=2 THEN 'Low Frequency'
            END AS frequency_category
	FROM average_transact_per_month
    )
-- finally,I got the total number of customers for each category and average of the transactions per month per category
SELECT 
		frequency_category,
		COUNT(*) AS customer_count,
		ROUND(AVG(avg_transaction_per_month),1) AS avg_transactions_per_month
FROM categorize_customer
GROUP BY frequency_category
ORDER BY avg_transactions_per_month DESC;
   
