
-- 02. ПРОВЕРКА КАЧЕСТВА ДАННЫХ
-- Проект: RetailRocket E-commerce Analytics

-- 1. Проверка пропусков по типам событий
SELECT
    event,
    COUNT(*) AS total_events,
    COUNT(transactionid) AS events_with_transactionid,
    COUNT(*) - COUNT(transactionid) AS events_without_transactionid
FROM events
GROUP BY event
ORDER BY total_events DESC;


-- 2. Проверка уникальных пользователей по типам событий
SELECT
    event,
    COUNT(DISTINCT visitorid) AS unique_visitors
FROM events
GROUP BY event
ORDER BY unique_visitors DESC;


-- 3. Проверка количества уникальных товаров
SELECT
    COUNT(DISTINCT itemid) AS unique_items
FROM events;


-- 4. Проверка дубликатов событий
SELECT
    COUNT(*) AS duplicate_groups
FROM (
    SELECT
        timestamp,
        visitorid,
        event,
        itemid,
        transactionid,
        COUNT(*) AS row_count
    FROM events
    GROUP BY
        timestamp,
        visitorid,
        event,
        itemid,
        transactionid
    HAVING COUNT(*) > 1
) AS duplicates;

/*
РЕЗУЛЬТАТЫ ПРОВЕРКИ КАЧЕСТВА ДАННЫХ:

1. В основных полях timestamp, visitorid, event и itemid
   пропуски отсутствуют.

2. transactionid заполнен только для событий transaction.
   Для view и addtocart отсутствие transactionid ожидаемо.

3. Найдено 458 групп полностью совпадающих записей
   по полям timestamp, visitorid, event, itemid и transactionid.

4. Повторяющиеся записи не удалялись:
   перед удалением необходимо выяснить причину их появления.
*/
