-- 1. Объединяем две части таблицы свойств товаров
CREATE OR REPLACE TABLE item_properties AS
SELECT *
FROM item_properties_1

UNION ALL

SELECT *
FROM item_properties_2;


-- 2. Получаем последнюю известную категорию для каждого товара
CREATE OR REPLACE TABLE item_latest_category AS
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