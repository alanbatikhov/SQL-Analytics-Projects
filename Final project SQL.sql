create database customers_transactions;

SET SQL_SAFE_UPDATES = 0;
update customers set Gender = null where Gender ='';
SET SQL_SAFE_UPDATES = 1;

SET SQL_SAFE_UPDATES = 0;
update customers set age = null where age ='';
SET SQL_SAFE_UPDATES = 1;

alter table customers modify age int null;

select * from transactions;

create table transactions
(date_new date,
Id_check int,
ID_client int,
Count_products decimal(10,3),
Sum_payment decimal(10,2));

load data infile "C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\TRANSACTIONS_final.csv.csv"
into table transactions 
fields terminated by ','
lines terminated by '\n'
ignore 1 rows ;


show variables like 'secure_file_priv';
-- 1 zadanie --
WITH monthly_activity AS (
    SELECT
        ID_client,
        DATE_FORMAT(date_new, '%Y-%m') AS ym
    FROM transactions
    WHERE date_new >= '2015-06-01'
      AND date_new <  '2016-06-01'
    GROUP BY ID_client, ym
),
continuous_clients AS (
    SELECT ID_client
    FROM monthly_activity
    GROUP BY ID_client
    HAVING COUNT(*) = 12
)
SELECT
    t.ID_client,
    AVG(t.Sum_payment) AS avg_check_year,
    SUM(t.Sum_payment) / 12 AS avg_month_amount,
    COUNT(*) AS total_operations
FROM transactions t
JOIN continuous_clients c
    ON t.ID_client = c.ID_client
WHERE t.date_new >= '2015-06-01'
  AND t.date_new <  '2016-06-01'
GROUP BY t.ID_client;

-- 2 zadanie --

-- a) Средний чек в месяц -- 
SELECT
    DATE_FORMAT(date_new, '%Y-%m') AS month,
    AVG(Sum_payment) AS avg_check
FROM transactions
WHERE date_new >= '2015-06-01'
  AND date_new <  '2016-06-01'
GROUP BY month;

-- b) Количество операций в месяц --
SELECT
    DATE_FORMAT(date_new, '%Y-%m') AS month,
    COUNT(*) AS operations_cnt
FROM transactions
WHERE date_new >= '2015-06-01'
  AND date_new <  '2016-06-01'
GROUP BY month;

-- c) Количество активных клиентов в месяц -- 
SELECT
    DATE_FORMAT(date_new, '%Y-%m') AS month,
    COUNT(DISTINCT ID_client) AS active_clients
FROM transactions
WHERE date_new >= '2015-06-01'
  AND date_new <  '2016-06-01'
GROUP BY month;
 
 -- d) Доля операций и доля суммы -- 
SELECT
    DATE_FORMAT(date_new, '%Y-%m') AS month,

    COUNT(*) /
    (SELECT COUNT(*)
     FROM transactions
     WHERE date_new >= '2015-06-01'
       AND date_new <  '2016-06-01') AS ops_share_year,

    SUM(Sum_payment) /
    (SELECT SUM(Sum_payment)
     FROM transactions
     WHERE date_new >= '2015-06-01'
       AND date_new <  '2016-06-01') AS amount_share_month

FROM transactions
WHERE date_new >= '2015-06-01'
  AND date_new <  '2016-06-01'
GROUP BY month;

-- e) % M / F / NA + доля затрат -- 
SELECT
    DATE_FORMAT(t.date_new, '%Y-%m') AS month,
    IFNULL(c.Gender, 'NA') AS gender,
    COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY DATE_FORMAT(t.date_new, '%Y-%m')) AS gender_pct,
    SUM(t.Sum_payment) / 
        SUM(SUM(t.Sum_payment)) OVER (PARTITION BY DATE_FORMAT(t.date_new, '%Y-%m')) AS amount_share
FROM transactions t
LEFT JOIN customers c
    ON t.ID_client = c.Id_client
WHERE t.date_new >= '2015-06-01'
  AND t.date_new <  '2016-06-01'
GROUP BY month, gender;
 
-- 3 zadanie -- 

-- За весь период -- 
SELECT
    CASE
        WHEN age IS NULL THEN 'NA'
        WHEN age < 20 THEN '0-19'
        WHEN age < 30 THEN '20-29'
        WHEN age < 40 THEN '30-39'
        WHEN age < 50 THEN '40-49'
        WHEN age < 60 THEN '50-59'
        ELSE '60+'
    END AS age_group,
    SUM(t.Sum_payment) AS total_amount,
    COUNT(*) AS total_operations
FROM transactions t
LEFT JOIN customers c
    ON t.ID_client = c.Id_client
WHERE t.date_new >= '2015-06-01'
  AND t.date_new <  '2016-06-01'
GROUP BY age_group;

-- Поквартально (средние и %) -- 
WITH base AS (
    SELECT
        CONCAT(YEAR(date_new), '-Q', QUARTER(date_new)) AS quarter,
        CASE
            WHEN age IS NULL THEN 'NA'
            WHEN age < 20 THEN '0-19'
            WHEN age < 30 THEN '20-29'
            WHEN age < 40 THEN '30-39'
            WHEN age < 50 THEN '40-49'
            WHEN age < 60 THEN '50-59'
            ELSE '60+'
        END AS age_group,
        Sum_payment
    FROM transactions t
    LEFT JOIN customers c
        ON t.ID_client = c.Id_client
    WHERE date_new >= '2015-06-01'
      AND date_new <  '2016-06-01'
)
SELECT
    quarter,
    age_group,
    AVG(Sum_payment) AS avg_payment,
    COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY quarter) AS ops_pct
FROM base
GROUP BY quarter, age_group;


