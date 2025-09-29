/* ========================
   1. DATA QUALITY CHECKS
   ======================== */
   
SELECT * FROM ecommerce_data.dataset2;

SELECT count(*)  FROM ecommerce_data.dataset2;

-- Check for missing values (nulls)
SELECT 
  SUM(CASE WHEN user_id IS NULL THEN 1 ELSE 0 END) AS null_user_id,
  SUM(CASE WHEN signup_time IS NULL THEN 1 ELSE 0 END) AS null_signup_time,
  SUM(CASE WHEN purchase_time IS NULL THEN 1 ELSE 0 END) AS null_purchase_time,
  SUM(CASE WHEN purchase_value IS NULL THEN 1 ELSE 0 END) AS null_purchase_value
FROM ecommerce_data.dataset2;

-- Check duplicates
SELECT user_id, COUNT(*) 
FROM ecommerce_data.dataset2
GROUP BY user_id
HAVING COUNT(*) > 1;

/* ========================
   2. DESCRIPTIVE STATISTICS
   ======================== */

-- Purchase value stats
SELECT 
  MIN(purchase_value) AS min_purchase,
  MAX(purchase_value) AS max_purchase,
  AVG(purchase_value) AS avg_purchase
FROM ecommerce_data.dataset2;

-- Age stats
SELECT 
  MIN(age) AS min_age,
  MAX(age) AS max_age,
  AVG(age) AS avg_age
FROM ecommerce_data.dataset2;

/* ========================
   3. DEMOGRAPHICS
   ======================== */
-- Gender distribution
SELECT sex, COUNT(*) AS user_count
FROM ecommerce_data.dataset2
GROUP BY sex;

-- Avg purchase by gender
SELECT sex, AVG(purchase_value) AS avg_purchase
FROM ecommerce_data.dataset2
GROUP BY sex;

-- What age groups are most active?.....
SELECT 
  CASE 
    WHEN age < 25 THEN '18-24'
    WHEN age BETWEEN 25 AND 34 THEN '25-34'
    WHEN age BETWEEN 35 AND 44 THEN '35-44'
    WHEN age BETWEEN 45 AND 54 THEN '45-54'
    ELSE '55+'
  END AS age_group,
  COUNT(*) AS user_count,
  AVG(purchase_value) AS avg_purchase
FROM ecommerce_data.dataset2
GROUP BY age_group
ORDER BY user_count desc;

-- Gender split: Male vs. Female engagement and purchase value.
SELECT sex , count(user_id) as user_count, avg(purchase_value) FROM ecommerce_data.dataset2
group by sex;

-- Age × Gender trends: e.g., do younger females spend more than younger males?
SELECT 
    sex,
    (CASE 
    WHEN age < 25 THEN '18-24'
    WHEN age BETWEEN 25 AND 34 THEN '25-34'
    WHEN age BETWEEN 35 AND 44 THEN '35-44'
    WHEN age BETWEEN 45 AND 54 THEN '45-54'
    ELSE '55+'
  END )
  AS age_group,
    AVG(purchase_value) AS average_purchase_value
FROM 
    ecommerce_data.dataset2
GROUP BY 
    sex,
    age_group
ORDER BY 
    age_group;
    
/* ========================
SELECT 
    gender,
    FLOOR(age / 10) * 10 AS age_group,
    AVG(purchase_value) AS average_purchase_value
FROM 
    ecommerce_data.dataset2
GROUP BY 
    gender,
    age_group
ORDER BY 
    gender,
    age_group;
      ======================== */


/* ========================
   4. MARKETING SOURCE ANALYSIS, DEVICE & BROWSER
   ======================== */

-- Compare Ads, SEO, Direct:
SELECT count(user_id) as number_of_users, source FROM ecommerce_data.dataset2
group by source;

-- Which channel brings the highest number of users?
SELECT browser, count(user_id) as number_of_users FROM ecommerce_data.dataset2
group by browser
order by number_of_users desc;

-- Which channel brings the highest purchase value?
SELECT browser , sum(purchase_value) as value FROM ecommerce_data.dataset2
group by browser
order by value desc;

-- Purchase Behavior - exploring what users buy, how often, and with what patterns.
#How many users purchase once vs multiple times?
SELECT 
    user_id,
    COUNT(*) AS total_purchases
FROM ecommerce_data.dataset2
WHERE purchase_time IS NOT NULL
GROUP BY user_id
ORDER BY total_purchases DESC;

# Average Purchases per User
SELECT 
    AVG(total_purchases) AS avg_purchases_per_user
FROM (
    SELECT user_id, COUNT(*) AS total_purchases
    FROM ecommerce_data.dataset2
    WHERE purchase_time IS NOT NULL
    GROUP BY user_id
) AS t;

-- Correlation between age and purchase_value.
SELECT 
    (AVG(age * purchase_value) - AVG(age) * AVG(purchase_value)) /
    (STDDEV(age) * STDDEV(purchase_value)) AS correlation_age_purchase_value
FROM ecommerce_data.dataset2
WHERE purchase_value IS NOT NULL 
  AND age IS NOT NULL;

-- Device & Browser Analysis
SELECT browser , count(device_id) as no_of_devices FROM ecommerce_data.dataset2
group by browser;

-- Which device/browser combinations are most common?
SELECT 
    device_id,
    browser,
    COUNT(*) AS occurrence_count
FROM 
    ecommerce_data.dataset2
GROUP BY 
    device_id,
    browser
ORDER BY 
    occurrence_count DESC
    LIMIT 1;

-- Most common browsers
SELECT browser, COUNT(*) AS user_count
FROM ecommerce_data.dataset2
GROUP BY browser
ORDER BY user_count DESC;

-- Avg purchase by browser
SELECT browser, AVG(purchase_value) AS avg_purchase
FROM ecommerce_data.dataset2
GROUP BY browser;

-- Do Chrome users spend more than Safari/IE/Opera/Firefox users?
SELECT browser , sum(purchase_value) as value FROM ecommerce_data.dataset2
group by browser
order by sum(purchase_value) desc ;


/* ========================
   6. TIME-BASED ANALYSIS
   ======================== */
   
   -- change text format to date
   SELECT 
    STR_TO_DATE(purchase_time, '%m/%d/%Y %H:%i') AS purchase_datetime
FROM 
    ecommerce_data.dataset2;

-- Conversion rate (signup → purchase)
-- Assuming class = 1 means purchased, 0 means not purchased
SELECT source,
  SUM(CASE WHEN class = 1 THEN 1 ELSE 0 END) * 1.0 / COUNT(*) AS conversion_rate
FROM ecommerce_data.dataset2
GROUP BY source;

-- Conversion rate by source (if signup_time vs. purchase_time difference is used)
SELECT 
    source,
    COUNT(DISTINCT user_id) AS total_signups,
    COUNT(DISTINCT CASE 
                      WHEN purchase_time IS NOT NULL 
                      THEN user_id 
                   END) AS converted_users,
    ROUND(
        COUNT(DISTINCT CASE 
                          WHEN purchase_time IS NOT NULL 
                          THEN user_id 
                       END) 
        / COUNT(DISTINCT user_id) * 100, 2
    ) AS conversion_rate_percentage
FROM ecommerce_data.dataset2
GROUP BY source
ORDER BY conversion_rate_percentage DESC;
    
-- Signup vs. Purchase lag: How long do users take to make their first purchase?
SELECT 
timestampdiff( 
day,
    STR_TO_DATE(signup_time, '%m/%d/%Y %H:%i'),
    STR_TO_DATE(purchase_time, '%m/%d/%Y %H:%i')
    ) as day_to_purchase
FROM 
    ecommerce_data.dataset2;

-- Time-of-day or day-of-week patterns in signup_time and purchase_time.
#signup_time
SELECT 
    HOUR(STR_TO_DATE(signup_time, '%m/%d/%Y %H:%i')) AS signup_hour,
    COUNT(*) AS signup_count
FROM ecommerce_data.dataset2
GROUP BY signup_hour
ORDER BY signup_hour;

#purchase_time
SELECT 
    HOUR(STR_TO_DATE(purchase_time, '%m/%d/%Y %H:%i')) AS purchase_hour,
    COUNT(*) AS purchase_count
FROM ecommerce_data.dataset2
WHERE purchase_time IS NOT NULL
GROUP BY purchase_hour
ORDER BY purchase_hour;

#Day-of-Week Patterns – Signups vs Purchases
SELECT 
    DAYNAME(STR_TO_DATE(signup_time, '%m/%d/%Y %H:%i')) AS signup_day,
    COUNT(*) AS signup_count
FROM ecommerce_data.dataset2
GROUP BY signup_day
ORDER BY FIELD(signup_day,'Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday');

SELECT 
    DAYNAME(STR_TO_DATE(purchase_time, '%m/%d/%Y %H:%i')) AS purchase_day,
    COUNT(*) AS purchase_count
FROM ecommerce_data.dataset2
WHERE purchase_time IS NOT NULL
GROUP BY purchase_day
ORDER BY FIELD(purchase_day,'Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday');

-- Create time_to_purchase in days
SELECT 
    user_id,
    STR_TO_DATE(signup_time, '%m/%d/%Y %H:%i') AS signup_dt,
    STR_TO_DATE(purchase_time, '%m/%d/%Y %H:%i') AS purchase_dt,
    DATEDIFF(
        STR_TO_DATE(purchase_time, '%m/%d/%Y %H:%i'),
        STR_TO_DATE(signup_time, '%m/%d/%Y %H:%i')
    ) AS time_to_purchase_days
FROM ecommerce_data.dataset2
WHERE purchase_time IS NOT NULL;

-- Avg time to purchase by source
SELECT 
    source,
    ROUND(AVG(DATEDIFF(
        STR_TO_DATE(purchase_time, '%m/%d/%Y %H:%i'),
        STR_TO_DATE(signup_time, '%m/%d/%Y %H:%i')
    )), 2) AS avg_time_to_purchase_days
FROM ecommerce_data.dataset2
WHERE purchase_time IS NOT NULL
GROUP BY source
ORDER BY avg_time_to_purchase_days;

-- Purchases by hour of day
SELECT 
    HOUR(STR_TO_DATE(purchase_time, '%m/%d/%Y %H:%i')) AS purchase_hour,
    COUNT(*) AS purchase_count
FROM ecommerce_data.dataset2
WHERE purchase_time IS NOT NULL
GROUP BY purchase_hour
ORDER BY purchase_hour;

-- Cohort analysis: Users who signed up in Jan vs. Jul — how do their purchases differ?
SELECT 
    CASE 
        WHEN MONTH(STR_TO_DATE(signup_time, '%m/%d/%Y %H:%i')) = 1 THEN 'January Cohort'
        WHEN MONTH(STR_TO_DATE(signup_time, '%m/%d/%Y %H:%i')) = 7 THEN 'July Cohort'
    END AS cohort,
    COUNT(DISTINCT user_id) AS total_users,
    COUNT(purchase_time) AS total_purchases,
    ROUND(AVG(purchase_value), 2) AS avg_purchase_value,
    ROUND(SUM(purchase_value), 2) AS total_revenue
FROM ecommerce_data.dataset2
WHERE MONTH(STR_TO_DATE(signup_time, '%m/%d/%Y %H:%i')) IN (1, 7)
GROUP BY cohort;

-- Do repeat purchases exist (same user_id multiple purchase_time entries)?
SELECT 
    COUNT(DISTINCT user_id) AS total_users,
    SUM(CASE WHEN purchase_count > 1 THEN 1 ELSE 0 END) AS repeat_purchasers,
    ROUND(SUM(CASE WHEN purchase_count > 1 THEN 1 ELSE 0 END) / COUNT(DISTINCT user_id) * 100, 2) AS repeat_purchase_rate
FROM (
    SELECT 
        user_id,
        COUNT(purchase_time) AS purchase_count
    FROM ecommerce_data.dataset2
    WHERE purchase_time IS NOT NULL
    GROUP BY user_id
) AS sub;

/* ========================
   7. FRAUD / ANOMALY CHECKS
   ======================== */
-- Does device_id repeat across multiple users → possible fraud detection?
SELECT 
    device_id,
    COUNT(DISTINCT user_id) AS user_count
FROM ecommerce_data.dataset2
WHERE device_id IS NOT NULL
GROUP BY device_id
HAVING COUNT(DISTINCT user_id) > 1
ORDER BY user_count DESC;

-- Fraud or Suspicious Activity Detection , Users with purchase_time = signup_time → possible bots/anomalies
SELECT 
    user_id,
    signup_time,
    purchase_time
FROM ecommerce_data.dataset2
WHERE STR_TO_DATE(signup_time, '%m/%d/%Y %H:%i') = STR_TO_DATE(purchase_time, '%m/%d/%Y %H:%i');

 -- Repeated ip_address across different user_ids → multiple accounts? 
SELECT 
    ip_address,
    COUNT(DISTINCT user_id) AS user_count
FROM ecommerce_data.dataset2
WHERE ip_address IS NOT NULL
GROUP BY ip_address
HAVING COUNT(DISTINCT user_id) > 1
ORDER BY user_count DESC;

-- Outlier analysis: Very high purchase_value vs. normal range. 
SELECT *
FROM ecommerce_data.dataset2
WHERE purchase_value > (
    SELECT AVG(purchase_value) + 3 * STDDEV(purchase_value) 
    FROM ecommerce_data.dataset2
);

-- By value (high-value vs. low-value customers).
SELECT 
    user_id,
    SUM(purchase_value) AS total_spent,
    CASE 
        WHEN SUM(purchase_value) >= 500 THEN 'High-Value'
        WHEN SUM(purchase_value) BETWEEN 100 AND 499 THEN 'Medium-Value'
        ELSE 'Low-Value'
    END AS segment
FROM ecommerce_data.dataset2
GROUP BY user_id;

-- By engagement (fast purchasers vs. long waiting users). 
SELECT 
    user_id,
    DATEDIFF(
        MAX(STR_TO_DATE(purchase_time, '%m/%d/%Y %H:%i')),
        MIN(STR_TO_DATE(signup_time, '%m/%d/%Y %H:%i'))
    ) AS time_to_first_purchase
FROM ecommerce_data.dataset2
GROUP BY user_id
ORDER BY time_to_first_purchase;

-- Users with signup but no purchase (class=0?). 
SELECT 
    COUNT(DISTINCT user_id) AS users_signed_up,
    SUM(CASE WHEN purchase_time IS NULL THEN 1 ELSE 0 END) AS no_purchase_users
FROM ecommerce_data.dataset2;

-- Users with only one low-value purchase vs. repeat higher-value customers.
SELECT 
    user_id,
    COUNT(purchase_time) AS purchase_count,
    SUM(purchase_value) AS total_spent,
    CASE 
        WHEN COUNT(purchase_time) = 1 AND SUM(purchase_value) < 50 THEN 'Low-Value One-Timer'
        WHEN COUNT(purchase_time) > 1 AND SUM(purchase_value) >= 100 THEN 'Valuable Repeat Customer'
        ELSE 'Other'
    END AS customer_type
FROM ecommerce_data.dataset2
GROUP BY user_id;

-- Time gap between purchases as an indicator of loyalty.
WITH purchases AS (
    SELECT 
        user_id,
        STR_TO_DATE(purchase_time, '%m/%d/%Y %H:%i') AS purchase_dt
    FROM ecommerce_data.dataset2
    WHERE purchase_time IS NOT NULL
),
ranked AS (
    SELECT 
        user_id,
        purchase_dt,
        LAG(purchase_dt) OVER (PARTITION BY user_id ORDER BY purchase_dt) AS prev_purchase
    FROM purchases
)
SELECT 
    user_id,
    ROUND(AVG(TIMESTAMPDIFF(DAY, prev_purchase, purchase_dt)), 2) AS avg_days_between_purchases,
    COUNT(*) AS total_purchases
FROM ranked
WHERE prev_purchase IS NOT NULL
GROUP BY user_id
ORDER BY avg_days_between_purchases;