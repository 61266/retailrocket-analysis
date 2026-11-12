
-- 06. АНАЛИЗ ТОВАРОВ
-- Проект: RetailRocket E-commerce Analytics

-- 1. Топ-10 товаров по просмотрам
SELECT
    itemid,
    COUNT(*) FILTER (WHERE event = 'view') AS views,
    COUNT(*) FILTER (WHERE event = 'addtocart') AS add_to_cart,
    COUNT(*) FILTER (WHERE event = 'transaction') AS purchases
FROM events
GROUP BY itemid
ORDER BY views DESC
LIMIT 10;


-- 2. Топ-10 товаров по количеству событий покупки
SELECT
    itemid,
    COUNT(*) AS purchases
FROM events
WHERE event = 'transaction'
GROUP BY itemid
ORDER BY purchases DESC
LIMIT 10;


-- 3. Топ-10 товаров по отношению покупок к просмотрам
-- Учитываются товары минимум с 100 просмотрами.
-- Метрика основана на количестве событий, а не уникальных пользователях.
SELECT
    itemid,
    COUNT(*) FILTER (WHERE event = 'view') AS views,
    COUNT(*) FILTER (WHERE event = 'transaction') AS purchases,
    ROUND(
        COUNT(*) FILTER (WHERE event = 'transaction') * 100.0 /
        NULLIF(COUNT(*) FILTER (WHERE event = 'view'), 0),
        2
    ) AS purchase_to_view_pct
FROM events
GROUP BY itemid
HAVING COUNT(*) FILTER (WHERE event = 'view') >= 100
ORDER BY purchase_to_view_pct DESC
LIMIT 10;
