<h1 align="center">DataAnalytics-Assessment-v2</h1>
<p align="center">
  A MySQL-based Data Analytics Project - Revisiting and Solving Real-World Business Questions
</p>


OVERVIEW

The DataAnalytics-Assessment-v2 project is a revisited version of a data analytics SQL challenge originally completed earlier in 2025. It contains four major business-driven questions that assess analytical thinking, SQL proficiency, and problem-solving ability using MySQL.
The database consists of four main tables:                                                                                                                                          
- users_customer,                                                                                                                                          
- plans_plan,                                                                                                                                         
- savings_savingsaccount, and                                                                                                                                         
- withdrawals_withdrawal.
                                                                                                                                                         
All connected to model customer savings behavior, transaction activities, and investment patterns. The analysis handled data from customer segmentation, behavior analysis, account monitoring, and profitability modeling.

TABLE BREAKDOWN

Before delving into the code breakdown, it is important to explain how each table connects to the others and what some of the more complex columns represent.

Firstly, users_customer table:   
This table holds basic customer details such as unique IDs and profile information used to identify account owners.
It contains one primary key:                                                                                                                                                         
- id : This is the unique identifier (primary key) for each customer. This id links to the owner_id column in other tables, allowing user-related data to be connected across the database.
                                                                                                                                                                                      
Secondly, plans table:                                                                                                                                                                
This table contains information on different financial plans linked to each customer.                                                                        
It contains 2 main key ids:
- id : This is the primary key of the plans table.
- owner id : This is a foreign key in the plans table which can be used to connect other table with the owner_id and also the users table id.

Thirdly, savings table:                                                                                                                                                               
This records all savings transactions, including plan ID, amount, and transaction date.                                                                          
It contains 3 main key ids:                                                                          
- id : Which is its own primary key.
- owner_id : Foreign key which can connect to the users table and other tables having the owner_id column
- Plan_id: This is a foreign key in the savings table and can be used to connect to the id column in the plans table.                                                                     

Finally, the withdrawals table: This records the withdrawal transactions.                                                                          
It contains 3 main key ids like the savings table. Its own id, owne_id, and plan_id. 

Summary of the above table breakdown
1. users_customer.id = plans_plan.owner_id  = withdrawals_withdrawal.owner_id = savings_savingsaccount.owner_id, also
2. plans_plan.id = withdrawals_withdrawal.plan_id = savings_savingsaccount.plan_id.
3. The column is_regular_saving mean savings_plan. It has Two values 1, 0
4. The column is_a_fund means investment_plan.  It has Two values 1, 0
5. Confirmed amount means inflow amount - savings table

PROJECT GOAL

This project was designed to revisit a previous SQL assessment and apply newly acquired analytical and technical knowledge to solve it more effectively.
The main goal was to evaluate user activity, spending patterns, and financial engagement while demonstrating structured SQL thinking through each query.

CONCEPTS COVERED 

I. Common Table Expressions (CTEs)                                                                                                                                                 
II. Aggregate and Window Functions (SUM, RANK, DENSE_RANK, ROW_NUMBER)                                                                                              
III. Date Manipulation and Interval Calculations                                                                                                                                           
IV. Conditional Logic with CASE Statements                                                                                                                                                 
V. Joins and Subqueries for Multi-table Analysis                                                                                                                                           
VI. Data Segmentation and Customer Behavior Tracking 
                                                                                                                                                                                          

<h1 align="center">PER-QUESTION EXPLANATIONS</h1>

<i> Q1. Task: Write a query to find customers with at least one funded savings plan AND one funded investment plan, sorted by total deposits.
    (High-Value Customers with Multiple Products
      Scenario: The business wants to identify customers who have both a savings and an investment plan (cross-selling opportunity)). </i>

  Expalnation - To solve this, I had to understand and breakdown the question.                                                                                                           
                1. The question requires that I output customers - this can be obtained from any table with owner_id or even the user table.                                            
                2. It says Atleast one funded savings and one funded investment. This means that I need to get customer sith both funded savings account and investment account. This  customer can must have atleast one or more of both accounts. 
                3. Lastly, I am required to Order By total_deposit. In the tables, there is no column as deposit but we have confirmed amount which is inflow amount in the savings table.
                
Steps taken to solve it -  

1st step: I obtained the customer full name from the user table. The user table had First_name and Last_name column and result want us to have "name" in one column, so I had to join the first and last_name columns using CONCAT. I used CTE because doing the joins and adding other query was causing MYSQL to output "Lost connection to Mysql server during query". CTE 
  
                                 USE adashi_staging -- This allows us to access the table in the database                                                                             
                                 
                                  WITH customer_name AS
                                  			(
                                  			SELECT 
                                  				 id,
                                  				 CONCAT(first_name, ' ', last_name) AS `name`
                                  			FROM users_customuser
                                  			),
2nd step: In other for me to get customers having atleast one investment AND savings account, I have to write a subquery that can output columns for the number of investment_account and number of savings_account for each individual customer. In the code below, I used the count(column_name) but with the NULLIF. This was done because COUNT(column_name) will count all the rows with values in the column but won't count null, which is great but I only want to count where the column has a value greater than 0 and that is why I used NULLIF(column_name,0) because this nullif function will turen all 0's to null and then we can count values greater than 0. Also, I used two filters, first was the WHERE clause and the second was the HAVING clause. The where clause will help remove all the rows where we have is_regular_savings = 0 and is_a_fund = 0 thereby leaving either values in the columns to be 1 or 0, and also both being 1. After this is achieved, the HAVING now filters the rows in the savings_count and investment_count columns to eliminate the row where either is 0, thereby leaving rows where  savings_count and investment_count columns are both > 1.

    SELECT
				owner_id,
				COUNT(NULLIF(is_regular_savings,0)) AS savings_count,   -- only count when is_regular_savings > 0 
				COUNT(NULLIF(is_a_fund,0)) AS investment_count          -- only count when is_a_fund > 0
    FROM plans_plan
    WHERE is_regular_savings > 0 OR -- This filters when is_regular_savings and is_a_fund are both 0 but allow either to be 0
					is_a_fund > 0                                                                                                                                                    
	GROUP BY owner_id
    HAVING COUNT(NULLIF(is_regular_savings,0)) > 0               -- This will filter the entire rows where either column is 0  
           AND COUNT(NULLIF(is_a_fund,0))  > 0 
Now that the subquery is ready, we can now join it to the result of our first CTE (customer_name) using INNER JOIN. I am using Inner Join to only output where there is a match.
                            
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
				              COUNT(NULLIF(is_regular_savings,0)) AS savings_count, 
			                COUNT(NULLIF(is_a_fund,0)) AS investment_count      
                FROM plans_plan
                WHERE is_regular_savings > 0 OR 
					            is_a_fund > 0                                                                                                               
                GROUP BY owner_id
                HAVING COUNT(NULLIF(is_regular_savings,0)) > 0 
                       AND COUNT(NULLIF(is_a_fund,0))  > 0 
                ) AS t
    ON c.id = t.owner_id 
                                                                                                                                                                                 
3rd step: To output the total_deposit, I will need to output the confirmed amount (inflow amount) column from the savings table after which I'll join it to the cus_sav_inv table (CTE2).
To get the confirmed amount column in the savings table, I will have to ensure that this amount is only for customers with atleast one savings AND investment account, which means I will be joinung the savings to the plan table and like we did in the second CTE, we will do same here by doing the count as well as the filters: WHERE and HAVING. The purpose of doing this is so we can calculate the total confirmed amount for customers who have atleast one saving AND investment. After running the code, I got the total amount per customer however, I realised that some customers total deposit were without kobo and instruction and result were having kobo, I had to convert the data type to decimal using CAST. The MAX(LENGTH()) function was to obtain the highest number of character in the total_deposit column so I can now use it in the CAST expression. 

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
Finally, I did the Inner Join of the customer_sav_inv and the result of this 3rd step subquery to get the desired column after which I ORDERed BY total_deposits in ASCending order

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
    ORDER BY d.total_deposits ASC;

Insight:                                                                                                                                                                      
While solving the assessment, I explored the dataset further to uncover patterns and customer behaviors. Here are a few key insights I derived from the analysis:
1. The customer with the highest total deposits contributed 33,631,711,883.37, while the least contributed 10,000.00.
2. The top customer based on total_deposit holds 3 savings and 9 investment accounts.
3. The highest number of savings accounts owned by one person is 312, while highest investment 92.                                                                                

Image Result of Query:
<img width="1357" height="611" alt="image" src="https://github.com/user-attachments/assets/9b8acba8-c9b1-4ddc-8efe-ec1b2de7b030" />
NB: Run SQL code to view all result.



<i> Q2. Task: Calculate the average number of transactions per customer per month and categorize them:
		  	"High Frequency" (≥10 transactions/month) | "Medium Frequency" (3-9 transactions/month) | "Low Frequency" (≤2 transactions/month) </i>

Explanation -                                                                                                                                                                          1st step: 	To solve this question, I started by Join the savings table to the user table using INNER JOIN (to get only users who have carried out a transaction) this was so that I can EXTRACT MONTH of transaction for each customer in the transaction_date column of the savings table. Once I obtained the result, I created a CTE to help my query run faster and better.

						-- 1st: Let's Extract month of customer transaction from transaction_date
										WITH month_extraction AS
											(
											SELECT 
													s.owner_id,
													MONTH(transaction_date) AS transaction_month
											FROM savings_savingsaccount AS s
											INNER JOIN users_customuser AS u
										    ON s.owner_id = u.id
										    ),
 2nd Step: Once I had the MONTH where EACH individual customers carried out a transaction, I counted the number of transaction carried per month for that unique customer. In the code below, I used both owner_id and transaction_month(month from transaction date) in the GROUP BY. This was done so that I could get the COUNT of transaction for each unique customer using owner_id and also the particular month. {Example of expected result: customer A carried out 5 transaction in may, 10 transactions in june }
 
						-- 2nd:I can now obtain the count of transactions per month by each customer
						transact_count AS
						 	(
						  SELECT 
									owner_id,
						            transaction_month,
						            COUNT(*) AS transaction_per_month
						    FROM month_extraction
						    GROUP BY owner_id, transaction_month
						    ORDER BY owner_id, transaction_month
							),
3rd step: After I was able to obtain the number of transactions carried out per month for each individual customer, I went on to get the AVERAGE number of transaction by each customer for months where they carried out a transaction. {From our example in step 2, this 3rd step is to get the average total transaction for each which will be (5+10)/2, where two is the number of months (may and june) customer A carried out a transaction. }

					-- 3rd: I went ahead to get the average transactions per month for each customer
					average_transact_per_month AS
						( 
						 SELECT owner_id,
								AVG(transaction_per_month) AS avg_transaction_per_month
						 FROM transact_count
						 GROUP BY owner_id
		                ),
4th step: In this step, I had to categorise the average transaction per customer per month into three different category, namely: High, Medium, and Low. In the code below, I used ROUND function because the condition for grouping was a whole number whereas the values I got after average in step 3 was in decimal. If I didn't, some number will be out of the range. For instance, if I had 9.7, it won't be included because my condition included only numbers within 3 and 9 with the both included excluding 9.01 - 9.99. 

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
Finally, in other to have only three rows showing the three categories, I did the average of the transaction per category

					- finally,I got the total number of customers for each category and average of the transactions per month per category
					SELECT 
							frequency_category,
							COUNT(*) AS customer_count,
							ROUND(AVG(avg_transaction_per_month),1) AS avg_transactions_per_month
					FROM categorize_customer
					GROUP BY frequency_category
					ORDER BY avg_transactions_per_month DESC;
Insight:                                                                                                                                                                                
1. The number of customer with High Frequency i.e. with transaction average >= 10 were leat with a count of 177 while customer with average transaction <=2 had the highest count with 499.
2. Top 2 category based on the average transaction per month are High Frequency and Medium Frequency with value 76.2 and 4.5 respectively.

Result:
<img width="1360" height="615" alt="image" src="https://github.com/user-attachments/assets/eee7227b-aae1-43b4-9d58-b73a814243bd" />
NB: Run SQL code to view all result.


<i> Q3. Task: Find all active accounts (savings or investments) with no transactions in the last 1 year (365 days) </i>                                                                

Explanation: -                                                                                                                                                                    
This question is my favorite among the four because, back in May when I first attempted this assessment, I interpreted it wrongly. That’s why I’ll take a moment to explain what the question wants us to solve. The question said customer with NO transaction in last 1 year, that means if we consider for instance this day (2025/11/04) as the last transaction date in the table, last 1 year will be 365days from today's date which is 2024/11/04 this means that any transaction date less than this 2024/11/04 is what we will be looking out for. 






<h1 align="center">CHALLENGES</h1>

1. In task 1, MySQL showed me "Lost connection to Mysql server during query" after running for 30.011sec when I was writing the code line by line without CTE, so I decided to use Common Table Expression (CTE), because it will help me extract the important fields I needed after then I can now use it as my new table. With that, I have less data for MYSQL to run and it can now be faster.                                                                                                                                                                                                                                                                                         
2. To get customers with atleast one investment and savings in task 1. At first, I only used the Where filter but I realised that my final result had 0 appearing under the columns which isn't what the task asked so I decided to use the HAVING filter with the WHERE filter since in the order of SQL execution WHERE will happen before HAVING. The HAVING condition worked because the WHERE had filtered both columns to having either of them being 1, 0 or both being 1 but both can't be 0. 

3. 
