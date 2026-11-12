CREATE TABLE item_properties_1 AS
SELECT *
FROM read_csv_auto(
    '/Users/omarzohroev/Downloads/archive/item_properties_part1.csv'
);

SHOW TABLES;

CREATE TABLE item_properties_2 AS
SELECT *
FROM read_csv_auto(
    '/Users/omarzohroev/Downloads/archive/item_properties_part2.csv'
);

CREATE TABLE category_tree AS
SELECT *
FROM read_csv_auto(
    '/Users/omarzohroev/Downloads/archive/category_tree.csv'
);

SHOW TABLES;

SELECT *
FROM category_tree
LIMIT 10;

SELECT
    COUNT(*) AS total_categories,
    COUNT(parentid) AS categories_with_parent,
    COUNT(*) - COUNT(parentid) AS categories_without_parent
FROM category_tree;

SELECT *
FROM item_properties_1
LIMIT 10;

SELECT
    COUNT(*) AS total_property_rows,

    COUNT(*) FILTER (
        WHERE property = 'categoryid'
    ) AS category_rows,

    COUNT(*) FILTER (
        WHERE property = 'available'
    ) AS availability_rows

FROM item_properties_1;

SELECT
    COUNT(*) AS total_property_rows,
    COUNT(*) FILTER (WHERE property = 'categoryid') AS category_rows,
    COUNT(*) FILTER (WHERE property = 'available') AS availability_rows
FROM item_properties_2;

CREATE TABLE item_properties AS
SELECT * FROM item_properties_1
UNION ALL
SELECT * FROM item_properties_2;

SELECT
    COUNT(*) AS category_records,
    COUNT(DISTINCT itemid) AS unique_items
FROM item_properties
WHERE property = 'categoryid';

SELECT
    COUNT(*) AS items_with_multiple_categories
FROM (
    SELECT itemid
    FROM item_properties
    WHERE property = 'categoryid'
    GROUP BY itemid
    HAVING COUNT(DISTINCT value) > 1
) t;

WITH latest_categories AS (
    SELECT
        itemid,
        value AS categoryid,
        ROW_NUMBER() OVER (
            PARTITION BY itemid
            ORDER BY timestamp DESC
        ) AS rn
    FROM item_properties
    WHERE property = 'categoryid'
)
SELECT
    COUNT(*) AS total_items,
    COUNT(ct.categoryid) AS matched_categories,
    COUNT(*) - COUNT(ct.categoryid) AS unmatched_categories
FROM latest_categories lc
LEFT JOIN category_tree ct
    ON TRY_CAST(lc.categoryid AS INTEGER) = ct.categoryid
WHERE lc.rn = 1;

CREATE TABLE item_latest_category AS
SELECT
    itemid,
    TRY_CAST(value AS INTEGER) AS categoryid
FROM (
    SELECT
        itemid,
        value,
        ROW_NUMBER() OVER (
            PARTITION BY itemid
            ORDER BY timestamp DESC
        ) AS rn
    FROM item_properties
    WHERE property = 'categoryid'
) t
WHERE rn = 1;

SELECT *
FROM item_latest_category
LIMIT 10;

SELECT
    lc.categoryid,
    COUNT(*) FILTER (WHERE e.event = 'view') AS views,
    COUNT(*) FILTER (WHERE e.event = 'addtocart') AS add_to_cart,
    COUNT(*) FILTER (WHERE e.event = 'transaction') AS purchases
FROM events e
JOIN item_latest_category lc
    ON e.itemid = lc.itemid
GROUP BY lc.categoryid
ORDER BY views DESC
LIMIT 10;

SELECT *
FROM category_tree
WHERE categoryid IN (1051, 1483, 491, 959, 342);

SELECT
    child.categoryid,
    child.parentid,
    parent.parentid AS grandparentid
FROM category_tree child
LEFT JOIN category_tree parent
    ON child.parentid = parent.categoryid
WHERE child.categoryid IN (1051, 1483, 491, 959, 342);

WITH category_hierarchy AS (
    SELECT
        categoryid,
        parentid
    FROM category_tree
)
SELECT
    ct.parentid AS parent_category,
    COUNT(*) FILTER (WHERE e.event = 'view') AS views,
    COUNT(*) FILTER (WHERE e.event = 'addtocart') AS add_to_cart,
    COUNT(*) FILTER (WHERE e.event = 'transaction') AS purchases
FROM events e
JOIN item_latest_category lc
    ON e.itemid = lc.itemid
JOIN category_hierarchy ct
    ON lc.categoryid = ct.categoryid
GROUP BY ct.parentid
ORDER BY views DESC
LIMIT 10;

WITH category_stats AS (
    SELECT
        ct.parentid AS parent_category,
        COUNT(*) FILTER (WHERE e.event = 'view') AS views,
        COUNT(*) FILTER (WHERE e.event = 'transaction') AS purchases
    FROM events e
    JOIN item_latest_category lc
        ON e.itemid = lc.itemid
    JOIN category_tree ct
        ON lc.categoryid = ct.categoryid
    GROUP BY ct.parentid
)
SELECT
    parent_category,
    views,
    purchases,
    ROUND(purchases * 100.0 / NULLIF(views, 0), 2) AS view_to_purchase_pct
FROM category_stats
WHERE views >= 10000
ORDER BY view_to_purchase_pct DESC
LIMIT 10;

WITH visitor_category AS (
    SELECT
        e.visitorid,
        ct.parentid AS parent_category,
        MAX(CASE WHEN e.event = 'view' THEN 1 ELSE 0 END) AS viewed,
        MAX(CASE WHEN e.event = 'transaction' THEN 1 ELSE 0 END) AS purchased
    FROM events e
    JOIN item_latest_category lc
        ON e.itemid = lc.itemid
    JOIN category_tree ct
        ON lc.categoryid = ct.categoryid
    GROUP BY e.visitorid, ct.parentid
)
SELECT
    parent_category,
    SUM(viewed) AS unique_viewers,
    SUM(purchased) AS unique_buyers,
    ROUND(
        SUM(purchased) * 100.0 / NULLIF(SUM(viewed), 0),
        2
    ) AS user_conversion_pct
FROM visitor_category
WHERE viewed = 1
GROUP BY parent_category
HAVING SUM(viewed) >= 1000
ORDER BY user_conversion_pct DESC
LIMIT 10;

WITH visitor_category AS (
    SELECT
        e.visitorid,
        ct.parentid AS parent_category,
        MIN(CASE WHEN e.event = 'view' THEN e.timestamp END) AS first_view,
        MIN(CASE WHEN e.event = 'transaction' THEN e.timestamp END) AS first_purchase
    FROM events e
    JOIN item_latest_category lc
        ON e.itemid = lc.itemid
    JOIN category_tree ct
        ON lc.categoryid = ct.categoryid
    GROUP BY e.visitorid, ct.parentid
)
SELECT
    parent_category,
    COUNT(*) FILTER (WHERE first_view IS NOT NULL) AS unique_viewers,
    COUNT(*) FILTER (
        WHERE first_view IS NOT NULL
          AND first_purchase > first_view
    ) AS buyers_after_view,
    ROUND(
        COUNT(*) FILTER (
            WHERE first_view IS NOT NULL
              AND first_purchase > first_view
        ) * 100.0 /
        NULLIF(COUNT(*) FILTER (WHERE first_view IS NOT NULL), 0),
        2
    ) AS user_conversion_pct
FROM visitor_category
GROUP BY parent_category
HAVING COUNT(*) FILTER (WHERE first_view IS NOT NULL) >= 1000
ORDER BY user_conversion_pct DESC
LIMIT 10;

SELECT
    itemid,
    COUNT(*) FILTER (WHERE event = 'view') AS views,
    COUNT(*) FILTER (WHERE event = 'addtocart') AS add_to_cart,
    COUNT(*) FILTER (WHERE event = 'transaction') AS purchases,
    ROUND(
        COUNT(*) FILTER (WHERE event = 'transaction') * 100.0 /
        NULLIF(COUNT(*) FILTER (WHERE event = 'view'), 0),
        2
    ) AS purchase_to_view_pct
FROM events
GROUP BY itemid
HAVING COUNT(*) FILTER (WHERE event = 'view') >= 500
ORDER BY purchase_to_view_pct ASC, views DESC
LIMIT 20;

WITH low_conversion AS (
    SELECT
        itemid,
        COUNT(*) FILTER (WHERE event = 'view') AS views,
        COUNT(*) FILTER (WHERE event = 'addtocart') AS add_to_cart
    FROM events
    GROUP BY itemid
    HAVING COUNT(*) FILTER (WHERE event = 'view') >= 500
       AND COUNT(*) FILTER (WHERE event = 'transaction') = 0
),
availability AS (
    SELECT
        itemid,
        value AS available,
        timestamp,
        ROW_NUMBER() OVER (
            PARTITION BY itemid
            ORDER BY timestamp DESC
        ) AS rn
    FROM item_properties
    WHERE property = 'available'
)
SELECT
    lc.itemid,
    lc.views,
    lc.add_to_cart,
    a.available AS latest_available
FROM low_conversion lc
LEFT JOIN availability a
    ON lc.itemid = a.itemid
   AND a.rn = 1
ORDER BY lc.views DESC
LIMIT 20;

WITH low_conversion AS (
    SELECT
        itemid,
        COUNT(*) FILTER (WHERE event = 'view') AS views
    FROM events
    GROUP BY itemid
    HAVING COUNT(*) FILTER (WHERE event = 'view') >= 500
       AND COUNT(*) FILTER (WHERE event = 'transaction') = 0
),
latest_availability AS (
    SELECT
        itemid,
        value AS available,
        ROW_NUMBER() OVER (
            PARTITION BY itemid
            ORDER BY timestamp DESC
        ) AS rn
    FROM item_properties
    WHERE property = 'available'
)
SELECT
    COALESCE(a.available, 'unknown') AS availability_status,
    COUNT(*) AS number_of_items
FROM low_conversion lc
LEFT JOIN latest_availability a
    ON lc.itemid = a.itemid
   AND a.rn = 1
GROUP BY COALESCE(a.available, 'unknown')
ORDER BY number_of_items DESC;

WITH latest_availability AS (
    SELECT
        itemid,
        value AS available,
        ROW_NUMBER() OVER (
            PARTITION BY itemid
            ORDER BY timestamp DESC
        ) AS rn
    FROM item_properties
    WHERE property = 'available'
),
product_stats AS (
    SELECT
        itemid,
        COUNT(*) FILTER (WHERE event = 'view') AS views,
        COUNT(*) FILTER (WHERE event = 'addtocart') AS add_to_cart,
        COUNT(*) FILTER (WHERE event = 'transaction') AS purchases
    FROM events
    GROUP BY itemid
)
SELECT
    p.itemid,
    p.views,
    p.add_to_cart,
    p.purchases,
    a.available
FROM product_stats p
JOIN latest_availability a
    ON p.itemid = a.itemid
   AND a.rn = 1
WHERE a.available = '1'
  AND p.views >= 500
  AND p.purchases = 0
ORDER BY p.views DESC
LIMIT 20;

WITH latest_availability AS (
    SELECT
        itemid,
        value AS available,
        ROW_NUMBER() OVER (
            PARTITION BY itemid
            ORDER BY timestamp DESC
        ) AS rn
    FROM item_properties
    WHERE property = 'available'
),
product_stats AS (
    SELECT
        itemid,
        COUNT(*) FILTER (WHERE event = 'view') AS views,
        COUNT(*) FILTER (WHERE event = 'addtocart') AS add_to_cart,
        COUNT(*) FILTER (WHERE event = 'transaction') AS purchases
    FROM events
    GROUP BY itemid
)
SELECT
    a.available,
    COUNT(*) AS number_of_products,
    ROUND(AVG(p.views), 2) AS avg_views,
    ROUND(AVG(p.add_to_cart), 2) AS avg_add_to_cart
FROM product_stats p
JOIN latest_availability a
    ON p.itemid = a.itemid
   AND a.rn = 1
WHERE p.views >= 500
  AND p.purchases = 0
GROUP BY a.available
ORDER BY a.available;
/*
ОСНОВНЫЕ РЕЗУЛЬТАТЫ:

1. Найдено 40 товаров, у которых:
   - не менее 500 просмотров;
   - отсутствуют события покупки.

2. Последняя запись о доступности:
   - 30 товаров: available = 0;
   - 5 товаров: available = 1;
   - 5 товаров: статус неизвестен.

3. Среднее количество добавлений в корзину:
   - Недоступные товары: 0.63;
   - Доступные товары: 7.40.

4. Доступные товары чаще добавляли в корзину,
   однако покупок не было ни в одной из двух групп.

ОГРАНИЧЕНИЯ АНАЛИЗА:

- Используется последняя известная запись о доступности,
  а не статус на момент взаимодействия с товаром.
- В группе доступных товаров всего 5 наблюдений.
- Результаты показывают взаимосвязь,
  но не доказывают причинно-следственную связь.
*/








