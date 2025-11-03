USE adashi_staging;

/* High-Value Customers with Multiple Products
Scenario: The business wants to identify customers who have both a savings and an investment plan (cross-selling opportunity).
Task: Write a query to find customers with at least one funded savings plan AND one funded investment plan, sorted by total deposits. */

-- 1st: obtain the customer ful name from the user table
WITH customer_name AS
			(
			SELECT 
				 id,
				 CONCAT(first_name, ' ', last_name) AS `name`
			FROM users_customuser
			),
-- 2nd: I join the subquery result table with the customer_name table from first CTE using INNER join so we only get customers with savings and investment
customer_sav_inv AS 
		(
		SELECT 
				t.owner_id,
				`name`,
				savings_count,
				investment_count
		FROM customer_name  as c
		INNER JOIN 
				 (-- Subquery to get customer with at least one investment AND savings account
                   SELECT 
						owner_id,
						COUNT(NULLIF(is_regular_savings,0)) AS savings_count, 	-- only count when is_regular_savings > 0 
						COUNT(NULLIF(is_a_fund,0)) AS investment_count  	  	-- only count when is_a_fund > 0 
					FROM plans_plan
                    WHERE is_regular_savings > 0 OR				-- This will prevent when is_regular_savings and is_a_fund are both 0
						   is_a_fund > 0
					GROUP BY owner_id
                    HAVING COUNT(NULLIF(is_regular_savings,0)) > 0 AND
							COUNT(NULLIF(is_a_fund,0)) 
				 ) AS t
		ON c.id = t.owner_id 
		)
-- finally, I had to output the desired columns
SELECT 
		i.owner_id,
        `name`,
        i.savings_count,
        i.investment_count,
        d.total_deposits
FROM customer_sav_inv AS i
-- I need to get the amount field from the savings table so I have to Inner Join it to the customer_sav_inv table
INNER JOIN 
			(-- subquery to get the total inflow amount(deposit) from each user
			SELECT 
				s.owner_id,
                COUNT(NULLIF(p.is_regular_savings,0)),
                COUNT(NULLIF(p.is_a_fund,0)),
				CAST(SUM(s.confirmed_amount) AS DECIMAL(18,2)) AS total_deposits
				--  MAX(LENGTH(SUM(s.confirmed_amount))) OVER()
			FROM plans_plan as p
			INNER JOIN savings_savingsaccount as s
			ON p.id = s.plan_id
			WHERE	p.is_regular_savings > 0 OR
					p.is_a_fund > 0
			GROUP BY s.owner_id
            HAVING COUNT(NULLIF(is_regular_savings,0)) > 0 AND
					COUNT(NULLIF(is_a_fund,0))
			) AS d
ON i.owner_id = d.owner_id
ORDER BY total_deposits ASC;

