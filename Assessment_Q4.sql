USE adashi_staging;

/* Task: For each customer, assuming the profit_per_transaction is 0.1% of the transaction value, calculate:
Account tenure (months since signup)
Total transactions
Estimated CLV (Assume: CLV = (total_transactions / tenure) * 12 * avg_profit_per_transaction)
Order by estimated CLV from highest to lowest */


-- 1st: let remove duplicate from savings table
WITH duplicate_savings AS
(
SELECT 
		owner_id,
       DATE_FORMAT(transaction_date, '%Y-%m-%d %H:%i') AS tran_date, -- To truncate our date to minute
        confirmed_amount,
        ROW_NUMBER() OVER(PARTITION BY owner_id, DATE_FORMAT(transaction_date, '%Y-%m-%d %H:%i'),confirmed_amount ORDER BY confirmed_amount ASC) AS row_cus
FROM savings_savingsaccount
),
clean_savings_table AS
(
SELECT 
		owner_id,
        DATE(tran_date) as `date`, -- This is now our new transaction datetime
        confirmed_amount
FROM duplicate_savings
WHERE row_cus = 1
),
-- 2nd: to get the names of customers who have carried out a transaction
join_table_user_savings AS
(
SELECT 
	u.id AS customer_id,
    CONCAT(u.first_name, ' ', u.last_name) AS full_name,
    s.`date`,
    s.confirmed_amount
FROM users_customuser AS u
INNER JOIN clean_savings_table AS s
ON u.id = s.owner_id
),
-- get account that have performed transaction. I assume that transaction for profit merit will be confirmed amount >0 AND not null
transaction_account AS
(
SELECT 
	customer_id,
	full_name,
    `date`,
    confirmed_amount
FROM join_table_user_savings
WHERE confirmed_amount IS NOT NULL 
	   AND confirmed_amount != 0
),
-- get the profit for each confirmed amonut.
transaction_profit AS
(
SELECT 
	customer_id,
	full_name,
    `date`,
    CASE
		WHEN confirmed_amount > 0 THEN confirmed_amount * 0.001
        ELSE 0 -- This is for the negative -40000 in the table. I assumed it to be withdrawal
    END AS profit_per_transaction
FROM transaction_account
),
-- get signup date which is assumed to be first transaction date, lasttransaction date, no. of transaction, average profit per transaction
individual_details AS
(
SELECT 
	customer_id,
	MAX(full_name) AS `name`,
    COUNT(*) AS total_transactions,
    MIN(`date`) AS signup_date,
    MAX(`date`) AS last_transaction_date,
    AVG(profit_per_transaction) AS avg_profit_per_transaction
FROM transaction_profit 
GROUP BY customer_id
),
tenure_in_month AS
(
SELECT 
	customer_id,
    `name`,
	TIMESTAMPDIFF(MONTH, signup_date, last_transaction_date) AS tenure_months,
    total_transactions,
    avg_profit_per_transaction
FROM individual_details
)
-- finally
  SELECT 
		customer_id,
        `name`,
         tenure_months,
        total_transactions,
		CAST(ROUND(((total_transactions / tenure_months) * 12 * avg_profit_per_transaction),2) AS DECIMAL(10,2)) AS estimated_clv
        -- MAX(LENGTH(ROUND(((total_transactions / tenure_months) * 12 * avg_profit_per_transaction),2))) OVER()
 FROM tenure_in_month
 ORDER BY estimated_clv DESC ;

