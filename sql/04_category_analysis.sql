
-- 04. АНАЛИЗ КАТЕГОРИЙ ТОВАРОВ
-- Проект: RetailRocket E-commerce Analytics

-- 1. Количество категорий
SELECT
    COUNT(*) AS total_categories,
    COUNT(parentid) AS categories_with_parent,
    COUNT(*) - COUNT(parentid) AS categories_without_parent
FROM category_tree;


-- 2. Проверка сопоставления товаров с категориями
SELECT
    COUNT(*) AS total_items,
    COUNT(ct.categoryid) AS matched_categories,
    COUNT(*) - COUNT(ct.categoryid) AS unmatched_categories
FROM item_latest_category lc
LEFT JOIN category_tree ct
    ON lc.categoryid = ct.categoryid;


-- 3. Топ-10 категорий по просмотрам, добавлениям в корзину и покупкам
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
