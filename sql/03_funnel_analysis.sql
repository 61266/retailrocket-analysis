
SELECT COUNT(*) AS total_rows
FROM events;

SELECT *
FROM events
LIMIT 10;

SELECT
    event,
    COUNT(*) AS total_events
FROM events
GROUP BY event
ORDER BY total_events DESC;

SELECT
    event,
    COUNT(DISTINCT visitorid) AS unique_visitors
FROM events
GROUP BY event
ORDER BY unique_visitors DESC;

SELECT
    event,
    COUNT(DISTINCT visitorid) AS unique_visitors
FROM events
GROUP BY event
ORDER BY unique_visitors DESC;

SELECT
    ROUND(
        37722.0 / 1404179 * 100, 2
    ) AS view_to_cart_pct,

    ROUND(
        11719.0 / 1404179 * 100, 2
    ) AS view_to_purchase_pct,

    ROUND(
        11719.0 / 37722 * 100, 2
    ) AS cart_to_purchase_pct;
SELECT
    MIN(timestamp) AS first_timestamp,
    MAX(timestamp) AS last_timestamp
FROM events;

SELECT
    to_timestamp(MIN(timestamp) / 1000.0) AS first_date,
    to_timestamp(MAX(timestamp) / 1000.0) AS last_date
FROM events;

SELECT
    COUNT(*) AS total_rows,
    COUNT(*) - COUNT(timestamp) AS missing_timestamp,
    COUNT(*) - COUNT(visitorid) AS missing_visitorid,
    COUNT(*) - COUNT(event) AS missing_event,
    COUNT(*) - COUNT(itemid) AS missing_itemid,
    COUNT(*) - COUNT(transactionid) AS missing_transactionid
FROM events;

SELECT
    event,
    COUNT(*) AS total_events,
    COUNT(transactionid) AS events_with_transactionid,
    COUNT(*) - COUNT(transactionid) AS events_without_transactionid
FROM events
GROUP BY event
ORDER BY total_events DESC;

WITH visitor_funnel AS (
    SELECT
        visitorid,
        MAX(CASE WHEN event = 'view' THEN 1 ELSE 0 END) AS viewed,
        MAX(CASE WHEN event = 'addtocart' THEN 1 ELSE 0 END) AS added_to_cart,
        MAX(CASE WHEN event = 'transaction' THEN 1 ELSE 0 END) AS purchased
    FROM events
    GROUP BY visitorid
)

SELECT
    COUNT(*) AS total_visitors,
    SUM(viewed) AS viewed_visitors,
    SUM(added_to_cart) AS cart_visitors,
    SUM(purchased) AS purchasing_visitors
FROM visitor_funnel;

WITH visitor_events AS (
    SELECT
        visitorid,
        MIN(CASE WHEN event = 'view'
            THEN timestamp END) AS first_view,
        MIN(CASE WHEN event = 'addtocart'
            THEN timestamp END) AS first_cart,
        MIN(CASE WHEN event = 'transaction'
            THEN timestamp END) AS first_purchase
    FROM events
    GROUP BY visitorid
)

SELECT
    COUNT(*) FILTER (
        WHERE first_view IS NOT NULL
          AND first_cart IS NOT NULL
          AND first_purchase IS NOT NULL
    ) AS all_three_events,

    COUNT(*) FILTER (
        WHERE first_view < first_cart
          AND first_cart < first_purchase
    ) AS correct_sequence

FROM visitor_events;

WITH visitor_events AS (
    SELECT
        visitorid,
        MIN(CASE WHEN event = 'view'
            THEN timestamp END) AS first_view,
        MIN(CASE WHEN event = 'addtocart'
            THEN timestamp END) AS first_cart,
        MIN(CASE WHEN event = 'transaction'
            THEN timestamp END) AS first_purchase
    FROM events
    GROUP BY visitorid
)

SELECT
    COUNT(*) FILTER (
        WHERE first_view IS NOT NULL
    ) AS viewed,

    COUNT(*) FILTER (
        WHERE first_view < first_cart
    ) AS viewed_then_cart,

    COUNT(*) FILTER (
        WHERE first_view < first_cart
          AND first_cart < first_purchase
    ) AS completed_funnel

FROM visitor_events;

SELECT
    itemid,

    COUNT(*) FILTER (
        WHERE event = 'view'
    ) AS views,

    COUNT(*) FILTER (
        WHERE event = 'addtocart'
    ) AS add_to_cart,

    COUNT(*) FILTER (
        WHERE event = 'transaction'
    ) AS purchases

FROM events

GROUP BY itemid

ORDER BY views DESC

LIMIT 10;

SELECT
    itemid,
    COUNT(*) AS purchases
FROM events
WHERE event = 'transaction'
GROUP BY itemid
ORDER BY purchases DESC
LIMIT 10;

SELECT
    itemid,

    COUNT(*) FILTER (
        WHERE event = 'view'
    ) AS views,

    COUNT(*) FILTER (
        WHERE event = 'transaction'
    ) AS purchases,

    ROUND(
        COUNT(*) FILTER (
            WHERE event = 'transaction'
        ) * 100.0 /
        NULLIF(COUNT(*) FILTER (
            WHERE event = 'view'
        ), 0),
        2
    ) AS view_to_purchase_pct

FROM events

GROUP BY itemid

HAVING COUNT(*) FILTER (
    WHERE event = 'view'
) >= 100

ORDER BY view_to_purchase_pct DESC

LIMIT 10;














