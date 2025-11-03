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

Firstly, users_customer table
This table holds basic customer details such as unique IDs and profile information used to identify account owners.
It contains one primary key:                                                                                                                                                         
- id : This is the unique identifier (primary key) for each customer. This id links to the owner_id column in other tables, allowing user-related data to be connected across the database.
                                                                                                                                                                                      
Secondly, plans table. This table contains information on different financial plans linked to each customer.                                                                          
It contains 2 main key ids:
- id : This is the primary key of the plans table.
- owner id : This is a foreign key in the plans table which can be used to connect other table with the owner_id and also the users table id.

Thirdly, savings table: This records all savings transactions, including plan ID, amount, and transaction date.                                                                          
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

Q1. Task: Write a query to find customers with at least one funded savings plan AND one funded investment plan, sorted by total deposits.
    (High-Value Customers with Multiple Products
      Scenario: The business wants to identify customers who have both a savings and an investment plan (cross-selling opportunity)).

  Expalnation - To solve this, I had to understand and breakdown the question.                                                                                                           
                1. The question requires that I output customers - this can be obtained from any table with owner_id or even the user table.                                            
                2. It says Atleast one funded savings and one funded investment. This means that I need to get customer that have both a funded savings account as well as an investment   
                    account. This customer can must have one or more of both. 
                3. Lastly, I am required to Order By total_deposit. In the tables, there is no column as deposit but we have confirmed amount which is inflow amount in the savings table.
                
  Steps taken to solve it -  

  1st: Obtain the customer full name from the user table. The user table had First_name and Last_name column and result want us to have "name" in one column, so I had to join the first and last_name columns using CONCAT. I used CTE because doing the joins and adding other query was causing MYSQL to output "Lost connection to Mysql server during query". CTE 
  
                                  WITH customer_name AS
                                  			(
                                  			SELECT 
                                  				 id,
                                  				 CONCAT(first_name, ' ', last_name) AS `name`
                                  			FROM users_customuser
                                  			),
 2nd: I joined our subquery result table with the customer_name table from first CTE using INNER join so we only get customers with savings and investment
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
                            							COUNT(is_regular_savings) AS savings_count,
                            							COUNT(is_a_fund) AS investment_count
                            					FROM plans_plan
                            					GROUP BY owner_id
                                                HAVING COUNT(is_regular_savings) >=1 AND
                            							COUNT(is_a_fund) >= 1
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
                            -- I need to get the amount field from the savings table so I have to inner joining it to the customer_sav_inv table
                            INNER JOIN 
                            			(-- subquery to get the total inflow amount(deposit) from each user
                            			SELECT 
                            					owner_id,
                                                -- LENGTH(SUM(confirmed_amount)) - this confirms that the highest number of character is 18, so we can now do the casting to decimals
                            					ROUND(CAST(SUM(confirmed_amount) AS DECIMAL(18,2)),2) AS total_deposits
                            			FROM savings_savingsaccount
                            			GROUP BY owner_id
                            			-- ORDER BY LENGTH(SUM(confirmed_amount)) desc;
                            			ORDER BY total_deposits DESC
                            			) AS d
                            ON i.owner_id = d.owner_id
                            ORDER BY d.total_deposits DESC;
                                                       
                            /*
                            SELECT 
                            		COUNT(is_regular_savings),
                                    COUNT(is_a_fund)
                            FROM plans_plan;
                            
                            This confirms we have equal number of savings and investment account (9641)
                            
                            */

<h1 align="center">CHALLENGES</h1>

1. In task 1, MySQL showed me "Lost connection to Mysql server during query" after running for 30.011sec when I was writing the code line by line without CTE, so I decided to use Common Table Expression (CTE), because it will help me extract the important fields I needed after then I can now use it as my new table. With that, I have less data for MYSQL to run and it can now be faster. 
