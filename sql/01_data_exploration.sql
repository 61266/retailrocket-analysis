
-- 01. ИССЛЕДОВАТЕЛЬСКИЙ АНАЛИЗ ДАННЫХ
-- Проект: RetailRocket E-commerce Analytics

-- 1. Общее количество событий
SELECT
    COUNT(*) AS total_rows
FROM events;


-- 2. Распределение событий по типам
SELECT
    event,
    COUNT(*) AS total_events
FROM events
GROUP BY event
ORDER BY total_events DESC;


-- 3. Период наблюдений
-- В исходных данных timestamp хранится в миллисекундах
SELECT
    to_timestamp(MIN(timestamp) / 1000.0) AS first_date,
    to_timestamp(MAX(timestamp) / 1000.0) AS last_date
FROM events;


-- 4. Проверка пропусков
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) - COUNT(timestamp) AS missing_timestamp,
    COUNT(*) - COUNT(visitorid) AS missing_visitorid,
    COUNT(*) - COUNT(event) AS missing_event,
    COUNT(*) - COUNT(itemid) AS missing_itemid,
    COUNT(*) - COUNT(transactionid) AS missing_transactionid
FROM events;
