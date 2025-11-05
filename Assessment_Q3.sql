USE adashi_staging;

/* Task: Find all active accounts (savings or investments) with no transactions in the last 1 year (365 days) . */

-- 1st step: identify the transaction date of customers

WITH ref_transaction AS
		(
		SELECT 
				plan_id,
				owner_id,
				confirmed_amount,
				DATE(transaction_date) AS customer_transaction_date,
				MAX(DATE(transaction_date)) OVER() AS maximum_transaction_date, -- To get the up to date transaction_date in the table
                DATE_SUB(MAX(DATE(transaction_date)) OVER(), INTERVAL 1 YEAR) AS Reference_transaction_date 
		FROM savings_savingsaccount
		),
-- 2nd step: getting the day(s) difference between the reference_transaction_date and transaction_date
days_of_transaction AS
		(
		SELECT 
				plan_id,
				owner_id,
				confirmed_amount,
				customer_transaction_date,
				Reference_transaction_date,
				DATEDIFF(Reference_transaction_date,customer_transaction_date  ) AS days
		FROM ref_transaction
		),
-- 3rd: getting all transaction over 1 year
over_one_year_transaction AS 
		(
		SELECT 
				plan_id,
				owner_id,
				confirmed_amount,
                customer_transaction_date,
				days
		FROM days_of_transaction
        WHERE days > 365
		),
-- 4th: We can now get all active account. 
active_account AS 
		(
		SELECT 
				s.plan_id,
				s.owner_id,
				s.confirmed_amount,
                s.customer_transaction_date,
				s.days,
				p.is_regular_savings,
				p.is_a_fund
		FROM over_one_year_transaction AS s
		INNER JOIN plans_plan AS p
		ON s.plan_id = p.id
		WHERE p.is_regular_savings = 1 	-- this was to get active savings account
			  OR p.is_a_fund = 1 		-- this was to get active investment account
		ORDER BY s.days ASC
		),
-- 5th: obtain all accounts with no transactions, i.e, confirmed amount = inflow amount is 0 or null
no_transaction_over_one_year AS
		(
		SELECT 
				plan_id,
				owner_id,
				confirmed_amount,
                customer_transaction_date,
				days,
				is_regular_savings,
				is_a_fund
		FROM active_account
        WHERE confirmed_amount IN (0, NULL)
		),
-- 6th: categorise account type
type_of_account AS
		(
		SELECT 
				plan_id,
				owner_id,
				confirmed_amount,
                customer_transaction_date,
				days,
				is_regular_savings,
				is_a_fund,
                CASE
					WHEN is_regular_savings = 1 AND is_a_fund = 0 THEN 'Savings'
					WHEN is_regular_savings = 0 AND is_a_fund = 1 THEN  'Investment'
                    ELSE 'Not Specified'
                END AS `type`
		FROM no_transaction_over_one_year
		),
-- 7th: Get the maximum inactivity_days per customer and their account_type
max_inactivity_day_percustomer_accounttype AS
		(
        SELECT 
			plan_id,
			owner_id,
			`type`,      
			days,
			customer_transaction_date,
			MAX(days) OVER(PARTITION BY  `type`, owner_id ORDER BY days DESC) AS inactivity_days
		FROM type_of_account
        ),
-- 8th: identify duplicates per account type for each unique owner id
duplicates AS
(
 SELECT 
		plan_id,
		owner_id,
		`type`,            
		customer_transaction_date AS last_transaction_date,
		inactivity_days,
		ROW_NUMBER() OVER(PARTITION BY owner_id, `type` ORDER BY inactivity_days DESC) AS row_cus 
 FROM max_inactivity_day_percustomer_accounttype
)
-- Finally, I removed duplicates 
SELECT 
		plan_id,
		owner_id,
		`type`,            
		last_transaction_date,
		inactivity_days
FROM duplicates
WHERE row_cus =1 
ORDER BY inactivity_days;


/*
Insight code: 
	SELECT 
				plan_id,
				owner_id,
				`type`,            
				last_transaction_date,
				inactivity_days,
                COUNT(*) OVER() -- Number of Inactive account from the final code
		CONCAT(ROUND(((COUNT(*) OVER(PARTITION BY `type`))/(COUNT(*) OVER())) * 100,0), '%') AS percentage_of_type -- Percentage of savings and investment 
	FROM duplicates
	WHERE row_cus =1 
	ORDER BY inactivity_days;

/*
