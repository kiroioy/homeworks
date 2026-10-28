-- ============================================================
-- Домашнее задание к лекции «Продвинутый SQL»
-- Школа Аналитиков · учебная база hh_school
-- Автор: Рытикова Кирена Игоревна
-- ============================================================

SET search_path TO hh_school;

-- ============================================================
-- БЛОК А. Качество и подготовка данных
-- ============================================================

-- ЗАДАНИЕ 1 Аудит качества данных 

-- Смотрим на содержимое таблиц calls и messages
SELECT *
FROM hh_school.calls
LIMIT 10;

SELECT *
FROM hh_school.messages
LIMIT 10;

-- В запросах ниже выводим количество "проблемных" строк и массив с их id
-- Проверка связи звонков с откликом (response_id IS NULL)
SELECT 
	count(*) AS problem_rows_count, 
	array_agg(call_id) AS record_ids
FROM calls
WHERE response_id IS NULL;
-- Обнаружено 8 строк с id={700244,700245,700246,700247,700248,700249,700250,700251}

-- Проверка звонков с откликом, которого нет в таблице responses (несуществующие отклики)
SELECT 
	count(*) AS problem_rows_count, 
	array_agg(c.call_id) AS record_ids
FROM hh_school.calls c
WHERE response_id IS NOT NULL 
	AND NOT EXISTS (
		SELECT 1
    		FROM hh_school.responses AS r
    		WHERE r.response_id = c.response_id);
-- Обнаружено 0 строк

-- Проверка сообщений без отклика (response_id IS NULL)
SELECT 
	count(*) AS problem_rows_count,
	array_agg(message_id) AS record_ids
FROM hh_school.messages 
WHERE response_id IS NULL;
-- Обнаружено 0 строк

-- Проверка наличия сообщений с откликом, который не обнаружен в таблице responses
SELECT 
	count(*) AS problem_rows_count, 
	array_agg(message_id) AS record_ids
FROM hh_school.messages m
WHERE response_id IS NOT NULL 
	AND NOT EXISTS (
		SELECT 1
    		FROM hh_school.responses AS r
    		WHERE r.response_id = m.response_id);
-- Обнаружено 0 строк

-- Проверка на согласованность id: несовпадение employer_id в событии и вакансии
SELECT 
	count(*) AS problem_rows_count,
	array_agg(call_id) AS record_ids
FROM hh_school.calls c
JOIN hh_school.responses r ON c.response_id = r.response_id
JOIN hh_school.vacancies v ON r.vacancy_id = v.vacancy_id
WHERE c.employer_id IS DISTINCT FROM v.employer_id;
-- Обнаружено 0 строк

-- Проверка на согласованность id: несовпадение vacancy_id звонка с вакансией отклика
SELECT 
	count(*) AS problem_rows_count,
	array_agg(c.call_id) AS record_ids
FROM hh_school.calls c
JOIN hh_school.responses r ON c.response_id = r.response_id
WHERE c.vacancy_id IS DISTINCT FROM r.vacancy_id;
-- Обнаружено 0 строк

-- Проверка на согласованность id: несовпадение employer_id сообщения с работодателем вакансии
SELECT 
	count(*) AS problem_rows_count,
	array_agg(m.message_id) AS record_ids
FROM hh_school.messages m 
JOIN hh_school.responses r ON m.response_id = r.response_id
JOIN hh_school.vacancies v ON r.vacancy_id = v.vacancy_id
WHERE m.employer_id IS DISTINCT FROM v.employer_id;
-- Обнаружено 0 строк

-- Проверка на согласованность id: несовпадение vacancy_id сообщения с вакансией отклика
SELECT 
	count(*) AS problem_rows_count,
	array_agg(m.message_id) AS record_ids
FROM hh_school.messages m 
JOIN hh_school.responses r ON m.response_id = r.response_id
WHERE m.vacancy_id IS DISTINCT FROM r.vacancy_id;
-- Обнаружено 0 строк

-- Проверка аномалий во времени: звонок состоялся раньше отклика (call_at<created_at)
SELECT 
	count(*) AS problem_rows_count,
	array_agg(c.call_id) AS record_ids
FROM hh_school.calls c
JOIN hh_school.responses r ON c.response_id = r.response_id
WHERE c.call_at < r.created_at;
-- Обнаружено 0 строк

-- Проверка аномалий во времени: сообщение отправлено раньше отклика (sent_at<created_at)
SELECT 
	count(*) AS problem_rows_count,
	array_agg(m.message_id) AS record_ids
FROM hh_school.messages m 
JOIN hh_school.responses r ON m.response_id = r.response_id
WHERE m.sent_at < r.created_at;
-- Обнаружено 0 строк

-- Проверка звонков со статусом 'error' (ошибка/сбой вызова)
SELECT 
	count(*) AS problem_rows_count,
	array_agg(c.call_id) AS record_ids
FROM hh_school.calls c
WHERE status = 'error';
-- Обнаружена 1 запись с id={700163}

-- Проверка согласованности внутри строки: успешный звонок с пустой/нулевой длительностью
SELECT 
	count(*) AS problem_rows_count,
	array_agg(c.call_id) AS record_ids
FROM hh_school.calls c 
WHERE c.status = 'successful' 
	AND (c.call_duration IS NULL OR c.call_duration <= 0);
-- Обнаружено 0 строк

-- Проверка согласованности внутри строки: неуспешный звонок с заполненной длительностью
SELECT 
	count(*) AS problem_rows_count,
	array_agg(c.call_id) AS record_ids
FROM hh_school.calls c 
WHERE c.status = 'unsuccessful' 
	AND c.call_duration IS NOT NULL;
-- Обнаружено 0 строк

-- Проверка звонков с отрицательной длительностью
SELECT 
	count(*) AS problem_rows_count,
	array_agg(call_id) AS record_ids
FROM hh_school.calls c 
WHERE c.call_duration < 0;
-- Обнаружено 0 строк

-- Проверка пропусков: в строке звонка пропущено время/роль/статус
SELECT 
	count(*) AS problem_rows_count,
	array_agg(c.call_id) AS record_ids
FROM hh_school.calls c 
WHERE 
	c.call_at IS NULL 
	OR c.caller_role IS NULL 
	OR c.status IS NULL;
-- Обнаружено 0 строк

-- Проверка пропусков: в строке сообщения пропущено время/роль отправителя/содержимое
SELECT 
	count(*) AS problem_rows_count,
	array_agg(m.message_id) AS record_ids
FROM hh_school.messages m 
WHERE m.sent_at IS NULL 
	OR m.sender_role IS NULL 
	OR m.message_text IS NULL;
-- Обнаружено 0 строк

-- Проверка на дубликаты в таблице calls
SELECT 
	count(*) AS problem_rows_count,
	array_agg(call_id) AS record_ids
FROM (
	SELECT call_id 
	FROM hh_school.calls c 
	GROUP BY c.call_id 
	HAVING count(*)>1
	) AS duplicates;
-- Обнаружено 0 строк

-- Проверка на дубликаты в таблице messages
SELECT 
	count(*) AS problem_rows_count,
	array_agg(message_id) AS record_ids
FROM (
	SELECT message_id FROM hh_school.messages m 
	GROUP BY m.message_id  
	HAVING count(*)>1) AS duplicates;
-- Обнаружено 0 строк
  
-- Проверка пропусков в тегах звонков
SELECT 
	count(*) AS problem_rows_count,
	array_agg(call_id) AS record_ids
FROM hh_school.calls
WHERE call_tags IS NULL;
-- Обнаружено 0 строк

-- Проверка отсутствия метаданных сообщений
SELECT 
	count(*) AS problem_rows_count,
	array_agg(message_id) AS record_ids
FROM hh_school.messages
WHERE message_meta IS NULL;
-- Обнаружено 0 строк

-- Проверка звонков, у которых отсутствует ожидаемый технический тег
SELECT
    count(*) AS problem_rows_count,
	array_agg(call_id) AS record_ids
FROM hh_school.calls
WHERE
    (status = 'successful' AND NOT ('connected' = ANY(call_tags)))
    OR (status = 'unsuccessful' AND NOT ('no_answer' = ANY(call_tags)))
    OR (status = 'error' AND NOT ('technical_error' = ANY(call_tags)));
-- Обнаружено 0 строк

-- Итоговый сводный запрос по выявленным проблемам качества данных
SELECT 
    count(*) AS problem_rows_count,
    array_agg(call_id ORDER BY call_id) AS problem_record_ids
FROM hh_school.calls
WHERE response_id IS NULL
UNION ALL
SELECT 
    count(*) AS problem_rows_count,
    array_agg(call_id ORDER BY call_id) AS problem_record_ids
FROM hh_school.calls
WHERE status = 'error';

-- Исследование call_duration успешных звонков
WITH calls_stats AS (
	SELECT 
		round(avg(call_duration)::NUMERIC, 2) AS avg_duration,
		round(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY call_duration)::NUMERIC, 2) AS median_duration,
		round(PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY call_duration)::NUMERIC, 2) AS p99_duration
	FROM hh_school.calls
	WHERE status = 'successful') 
SELECT 
	calls_stats.avg_duration,
	calls_stats.median_duration,
	calls_stats.p99_duration,
	count(c.call_id) FILTER (WHERE call_duration > calls_stats.p99_duration) AS count_above_p99,
	round(avg(c.call_duration) FILTER (WHERE call_duration <= calls_stats.p99_duration), 2) AS avg_duration_below_p99
FROM hh_school.calls AS c CROSS JOIN calls_stats
WHERE c.status = 'successful'
GROUP BY 1, 2, 3;

-- Запрос звонков, длительность которых выше 99-го перцентиля
WITH p99_duration AS (
    SELECT percentile_cont(0.99) WITHIN GROUP (ORDER BY call_duration) AS p99_duration
    FROM hh_school.calls
    WHERE status = 'successful' AND call_duration > 0)
SELECT c.call_id, c.call_duration
FROM hh_school.calls c
CROSS JOIN p99_duration d
WHERE c.status = 'successful'
  AND c.call_duration > d.p99_duration
ORDER BY c.call_duration, c.call_id;
-- Контрольные значения:
-- 1. Найденные проблемы качества данных:
-- При проверке связи звонков с откликом было обнаружено 8 строк, где response_id IS NULL (id={700244,700245,700246,700247,700248,700249,700250,700251}). Звонки невозможно привязать к конкретному отклику.
-- При проверке звонков со статусом 'error' (ошибка/сбой вызова) была обнаружена 1 запись (id={700163}). Технический сбой вызова (тег technical_error), контакт сорвался.
-- В таблице messages и остальных связях нарушений, пропусков обязательных атрибутов и аномалий по времени не обнаружено.
-- 2. Статистика длительности успешных звонков (call_duration):
-- средняя длительность: 467.28 секунд (примерно 7.8 мин)
-- медиана длительности (p50): 438 секунд (примерно 7.3 минут)
-- 99-й перцентиль длительности (p99): 890.40 секунд (примерно 14.8 минут)
-- количество звонков выше 99-го перцентиля: 2 звонка (call_id 700159 - 892 секунд и call_id 700199 - 899 секунд)
-- средняя длительность без экстремальных значений (после исключения значений выше 99-го перцентиля): 462.49 секунд (примерно 7.7 минут)

-- Вывод:
-- В ходе аудита было выявлено 8 звонков без привязки к отклику (NULL в response_id) и 1 звонок со статусом технической ошибки (call_id 700163).
-- Звонки без идентификатора отклика нельзя использовать для анализа коммуникаций в разрезе откликов, поскольку невозможно установить, к какому отклику они относятся.
-- Значения выше 99-го пперцентиля (892 и 899 секунд, около 15 минут) считаю допустимыми выбросами: превышение перцентиля само по себе не доказывает ошибку; в остальных метриках эти звонки сохраняю. 
-- Однако при расчете типичной длительности звонка лучше использовать медиану (438 секунд), так как она менее чувствительна к отдельным большим значениям, чем среднее.
-- После исключения двух наиболее длинных звонков средняя длительность составляет 462.49 секунды.


-- ============================================================
-- БЛОК Б. История коммуникаций
-- ============================================================

-- ЗАДАНИЕ 2 Единый слой коммуникаций

WITH calls_7d AS (
	SELECT 
		c.response_id,
		c.employer_id,
		c.call_id::text AS event_id,
		c.call_at AS event_at,
		'call' AS event_type
	FROM hh_school.calls c
	JOIN hh_school.responses r ON c.response_id = r.response_id
	WHERE c.caller_role = 'employer'
		AND c.call_at >= r.created_at 
		AND c.call_at <= r.created_at + INTERVAL '7 days'
		AND c.status <> 'error'),
messages_7d AS (
	SELECT 
		m.response_id,
		m.employer_id,
		m.message_id::text AS event_id,
		m.sent_at AS event_at,
		'message' AS event_type
	FROM hh_school.messages m
	JOIN hh_school.responses r ON m.response_id = r.response_id 
	WHERE m.sender_role = 'employer'
	AND m.sent_at >= r.created_at 
	AND m.sent_at <= r.created_at + INTERVAL '7 days'),
events AS (
	SELECT response_id, employer_id, event_id, event_at, event_type FROM calls_7d 
    UNION ALL
    SELECT response_id, employer_id, event_id, event_at, event_type FROM messages_7d)
SELECT 
	count(*) AS total_events_count,
	count(DISTINCT response_id) AS responses_with_communication_count,
	count(*) FILTER (WHERE event_type='call') AS calls_count,
	count(*) FILTER (WHERE event_type='message') AS messages_count
FROM events;
-- Контрольные значения:
-- общее количество событий: 1095
-- количество различных откликов с коммуникацией: 382
-- количество звонков: 107
-- количество сообщений: 988

-- Вывод: 
-- Из единого аналитического слоя коммуникации со стороны работодателей за первые 7 дней после отклика видно:
-- из 1095 событий большинство (988, 90.2%) приходится на сообщения, а звонки (107, 9.8%) используются гораздо реже;
-- всего коммуникацией охвачено 382 уникальных отклика (в среднем на 1 активный отклик приходится около 2.87 взаимодействий).


-- ЗАДАНИЕ 3 Таймлайн коммуникаций и витрина отклика
-- ШАГ 1 Слой уровня события
WITH calls_7d AS (
	SELECT 
		c.response_id,
		c.employer_id,
		c.call_id::text AS event_id,
		c.call_at AS event_at,
		'call' AS event_type
	FROM hh_school.calls c
	JOIN hh_school.responses r ON c.response_id = r.response_id
	WHERE c.caller_role = 'employer'
		AND c.call_at >= r.created_at 
		AND c.call_at <= r.created_at + INTERVAL '7 days'
		AND c.status <> 'error'),
messages_7d AS (
	SELECT 
		m.response_id,
		m.employer_id,
		m.message_id::text AS event_id,
		m.sent_at AS event_at,
		'message' AS event_type
	FROM hh_school.messages m
	JOIN hh_school.responses r ON m.response_id = r.response_id 
	WHERE m.sender_role = 'employer'
	AND m.sent_at >= r.created_at 
	AND m.sent_at <= r.created_at + INTERVAL '7 days'),
events AS (
	SELECT response_id, employer_id, event_id, event_at, event_type FROM calls_7d 
    UNION ALL
    SELECT response_id, employer_id, event_id, event_at, event_type FROM messages_7d),
timeline AS (
	SELECT 
		response_id,
		employer_id,
		event_id,
		event_at,
		event_type,
		ROW_NUMBER() OVER (
			PARTITION BY response_id
			ORDER BY event_at, event_type, event_id
			) AS event_sequences,
		LAG(event_at) OVER (
			PARTITION BY response_id
			ORDER BY event_at, event_type, event_id
			) AS previous_event_at,
		LEAD(event_type) OVER ( 
			PARTITION BY response_id
			ORDER BY event_at, event_type, event_id
			) AS next_event_type,
		count(*) OVER (
			PARTITION BY response_id
			ORDER BY event_at, event_type, event_id
			ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
			) AS total_events_count,
		FIRST_VALUE(event_type) OVER (
			PARTITION BY response_id
			ORDER BY event_at, event_type, event_id
			) AS first_event_type,
		LAST_VALUE(event_type) OVER (
			PARTITION BY response_id
			ORDER BY event_at, event_type, event_id
			ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
			) AS last_event_type
		FROM events),
-- агрегация истории до уровня отклика
agg_response_events AS (
	SELECT
		response_id,
		count(*) AS total_events,
        count(*) FILTER (WHERE event_type = 'call') AS calls_count,
        count(*) FILTER (WHERE event_type = 'message') AS messages_count,
        min(event_at) AS first_event_at,
        min(event_type) FILTER (WHERE event_sequences = 1) AS first_event_type,
        min(event_type) FILTER (WHERE event_sequences= 2) AS second_event_type,
        min(last_event_type) AS last_event_type,
        coalesce(max(CASE 
                WHEN previous_event_at IS NOT NULL 
                THEN extract(epoch from (event_at - previous_event_at)) / 3600.0 
                ELSE 0 
            END
        ), 0) AS max_interval_hours
    FROM timeline
    GROUP BY response_id),
 -- ШАГ 2 Витрина уровня отклика
 response_mart AS (
 	SELECT 
 		r.response_id,
 		v.employer_id,
        v.professional_role,
        r.status AS response_status,
        coalesce(are.total_events, 0) AS total_events,
        coalesce(are.calls_count, 0) AS calls_count,
        coalesce(are.messages_count, 0) AS messages_count,
        are.first_event_at,
        are.first_event_type,
        are.second_event_type,
        are.last_event_type,
        round((extract(epoch from (are.first_event_at - r.created_at)) / 3600.0)::numeric, 1) AS hours_to_first_event,
        round(coalesce(are.max_interval_hours, 0)::numeric, 1) AS max_interval_hours
    FROM hh_school.responses r
    JOIN hh_school.vacancies v ON r.vacancy_id = v.vacancy_id
    LEFT JOIN agg_response_events are ON r.response_id = are.response_id
 )
 SELECT 
    count(*) AS total_mart_rows,
    count(*) FILTER (WHERE total_events > 0) AS responses_with_comm_count,
    count(*) FILTER (WHERE total_events = 0) AS responses_without_comm_count,
    count(*) FILTER (WHERE first_event_type = 'message') AS first_is_message_count,
    count(*) FILTER (WHERE first_event_type = 'call') AS first_is_call_count
FROM response_mart;
-- Контрольные значения: 
-- количество строк: 628
-- количество откликов с коммуникацией: 382
-- количество откликов без коммуникации: 246
-- количество откликов, где первой коммуникацией было сообщение: 314
-- количество откликов, где первой коммуникацией был звонок: 68

-- Вывод:
-- Витрина уровня отклика объединила все 628 поступивших откликов без потери записей с нулевой активностью (благодаря LEFT JOIN).
-- По 39.2% откликов (246 из 628) работодатели вообще не выходили на связь в первые 7 дней после отклика.
-- Когда же коммуникация состоялась (382 отклика) работодатели в 82.2% случаев (314 откликов) начинали диалог с сообщения, звонок в качестве первого взаимодействия использовался лишь в 17.8% случаев (68 откликов).


-- ============================================================
-- БЛОК В. Сравнение работодателей
-- ============================================================

-- ЗАДАНИЕ 4 Рейтинг работодателей внутри направления

WITH calls_7d AS (
	SELECT 
		c.response_id,
		c.employer_id,
		c.call_id::text AS event_id,
		c.call_at AS event_at,
		'call' AS event_type
	FROM hh_school.calls c
	JOIN hh_school.responses r ON c.response_id = r.response_id
	WHERE c.caller_role = 'employer'
		AND c.call_at >= r.created_at 
		AND c.call_at <= r.created_at + INTERVAL '7 days'
		AND c.status <> 'error'),
messages_7d AS (
	SELECT 
		m.response_id,
		m.employer_id,
		m.message_id::text AS event_id,
		m.sent_at AS event_at,
		'message' AS event_type
	FROM hh_school.messages m
	JOIN hh_school.responses r ON m.response_id = r.response_id 
	WHERE m.sender_role = 'employer'
	AND m.sent_at >= r.created_at 
	AND m.sent_at <= r.created_at + INTERVAL '7 days'),
events AS (
	SELECT response_id, employer_id, event_id, event_at, event_type FROM calls_7d 
    UNION ALL
    SELECT response_id, employer_id, event_id, event_at, event_type FROM messages_7d),
timeline AS (
	SELECT 
		response_id,
		employer_id,
		event_id,
		event_at,
		event_type,
		ROW_NUMBER() OVER (
			PARTITION BY response_id
			ORDER BY event_at, event_type, event_id
			) AS event_sequences,
		LAG(event_at) OVER (
			PARTITION BY response_id
			ORDER BY event_at, event_type, event_id
			) AS previous_event_at,
		LEAD(event_type) OVER ( 
			PARTITION BY response_id
			ORDER BY event_at, event_type, event_id
			) AS next_event_type,
		count(*) OVER (
			PARTITION BY response_id
			ORDER BY event_at, event_type, event_id
			ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
			) AS total_events_count,
		FIRST_VALUE(event_type) OVER (
			PARTITION BY response_id
			ORDER BY event_at, event_type, event_id
			) AS first_event_type,
		LAST_VALUE(event_type) OVER (
			PARTITION BY response_id
			ORDER BY event_at, event_type, event_id
			ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
			) AS last_event_type
		FROM events),
-- агрегация истории до уровня отклика
agg_response_events AS (
	SELECT
		response_id,
		count(*) AS total_events,
        count(*) FILTER (WHERE event_type = 'call') AS calls_count,
        count(*) FILTER (WHERE event_type = 'message') AS messages_count,
        min(event_at) AS first_event_at,
        min(event_type) FILTER (WHERE event_sequences = 1) AS first_event_type,
        min(event_type) FILTER (WHERE event_sequences= 2) AS second_event_type,
        min(last_event_type) AS last_event_type,
        coalesce(max(CASE 
                WHEN previous_event_at IS NOT NULL 
                THEN extract(epoch from (event_at - previous_event_at)) / 3600.0 
                ELSE 0 
            END
        ), 0) AS max_interval_hours
    FROM timeline
    GROUP BY response_id),
 -- ШАГ 2 Витрина уровня отклика
 response_mart AS (
 	SELECT 
 		r.response_id,
 		v.employer_id,
        v.professional_role,
        r.status AS response_status,
        coalesce(are.total_events, 0) AS total_events,
        coalesce(are.calls_count, 0) AS calls_count,
        coalesce(are.messages_count, 0) AS messages_count,
        are.first_event_at,
        are.first_event_type,
        are.second_event_type,
        are.last_event_type,
        (extract(epoch from (are.first_event_at - r.created_at)) / 3600.0)::numeric AS hours_to_first_event,
        round(coalesce(are.max_interval_hours, 0)::numeric, 1) AS max_interval_hours
    FROM hh_school.responses r
    JOIN hh_school.vacancies v ON r.vacancy_id = v.vacancy_id
    LEFT JOIN agg_response_events are ON r.response_id = are.response_id
 ),
 employer_role_stats AS (
 		SELECT 
 			professional_role,
 			employer_id,
 			count(*) AS total_responses,
 			count(first_event_at) AS responses_with_comm_count,
 			count(first_event_at)::numeric / count(*) AS comm_rate,
 			percentile_cont(0.5) WITHIN GROUP (ORDER BY hours_to_first_event)::numeric AS median_first_comm_hours,
 			percentile_cont(0.9) WITHIN GROUP (ORDER BY hours_to_first_event)::numeric AS p90_first_comm_hours,
 			count(*) FILTER (WHERE response_status = 'invited')::numeric / count(*) AS conversion_to_invitation_rate
 		FROM response_mart
 		GROUP BY 1, 2
 		HAVING count(*) >= 8
 ),
 employer_ranked AS (
 	SELECT
 		professional_role,
 		employer_id,
 		total_responses,
 		responses_with_comm_count,
 		comm_rate,
 		median_first_comm_hours,
 		p90_first_comm_hours,
 		conversion_to_invitation_rate,
 		DENSE_RANK() OVER (
 			PARTITION BY professional_role
 			ORDER BY comm_rate DESC, median_first_comm_hours
 		) AS place
 	FROM employer_role_stats
 )
 SELECT 
 	professional_role,
    place,
    employer_id,
    e.employer_name,
    total_responses,
    responses_with_comm_count,
    round(100.0 * comm_rate, 1) AS comm_rate_pct,
    round(median_first_comm_hours, 1) AS median_first_comm_hours,
 	round(p90_first_comm_hours, 1) AS p90_first_comm_hours,
 	round(100.0 * conversion_to_invitation_rate, 1) AS conversion_to_invitation_pct
 FROM employer_ranked
 LEFT JOIN hh_school.employers e USING (employer_id)
 WHERE place <= 2
 ORDER BY 1, 2, 3;
 
-- Вывод:
-- professional_role      | place | employer_id
-- Аналитик данных        | 1 |     109 (Академия Данных)
-- Аналитик данных        | 2 |     103 (DataWave)
-- Дата-инженер           | 1 |     106 (УралСофт)
-- Дата-инженер           | 2 |     101 (ТехноБанк)
-- Продуктовый аналитик   | 1 |     103 (DataWave)
-- Продуктовый аналитик   | 2 |     102 (Мосмаркет)
-- Разработчик            | 1 |     112 (Стартап Ноль)
-- Разработчик            | 2 |     104 (Северный Код)
-- Тестировщик            | 1 |     107 (Логистик Плюс)
-- Тестировщик            | 2 |     108 (СибирьТелеком)

-- Вывод:
-- Лидерами по доле обработанных откликов стали компании «Академия Данных» (89.5% в аналитике данных) и «Логистик Плюс» (88.2% в тестировании). 
-- При этом в дата-инженерии у компании «ТехноБанк» наблюдается низкий охват: ответили лишь на 45.8% откликов (11 из 24).
-- Время реакции различается между работодателями. Быстрый контакт демонстрируют «СибирьТелеком» (медиана 5.7 часов) и «УралСофт» (медиана 9.7 часов), тогда как «Мосмаркет» (74.0 часа) и «ТехноБанк» (76.3 часа) выходят на связь в среднем более чем через 3 суток.
-- 90-й перцентиль у большинства работодателей приближается к 120–148 часам (5–6 дней). 
-- В тестировании конверсия в приглашение высокая (37.5–41.2%), тогда как в аналитике и разработке держится строго в коридоре 10–20%. 


-- ЗАДАНИЕ 5 Скорость ответа работодателя в переписке

WITH messages_7d AS (
	SELECT 
		m.response_id,
		m.employer_id,
		m.message_id,
		m.sent_at,
		m.sender_role
	FROM hh_school.messages m
	JOIN hh_school.responses r ON m.response_id = r.response_id 
	WHERE m.sent_at >= r.created_at 
		AND m.sent_at <= r.created_at + INTERVAL '7 days'),
message_with_previous AS (
	SELECT 
		response_id,
		employer_id,
		message_id,
		sent_at,
		sender_role,
		lag(sender_role) OVER (
			PARTITION BY response_id
			ORDER BY sent_at, message_id
		) AS previous_sender_role,
		lag(sent_at) OVER (
			PARTITION BY response_id
			ORDER BY sent_at, message_id
		) AS previous_sent_at
	FROM messages_7d 
),
employer_replies AS (
	SELECT 
		employer_id,
		round((extract(epoch from (sent_at - previous_sent_at)) / 3600.0)::numeric, 2) AS reply_time_hours
	FROM message_with_previous
	WHERE sender_role = 'employer' 
      AND previous_sender_role = 'applicant')
--SELECT count(*) FROM employer_replies;
SELECT 
	employer_id,
	count(*) AS replies_measured_count,
	round(avg(reply_time_hours)::numeric, 2) AS avg_reply_hours,
    round(percentile_cont(0.5) WITHIN GROUP (ORDER BY reply_time_hours)::numeric, 2) AS median_reply_hours,
    round(percentile_cont(0.9) WITHIN GROUP (ORDER BY reply_time_hours)::numeric, 2) AS p90_reply_hours
FROM employer_replies
GROUP BY 1
ORDER BY median_reply_hours;

-- Контрольные значения:
-- общее количество найденных ответов: 749
-- у работодателя с employer_id=107 ("Логистик Плюс") минимальная медиана (3.93 часа)

-- Вывод:
-- Всего обнаружено 749 пар сообщений, где работодатель отвечал после сообщения соискателя в первые 7 дней после отклика.
-- Самым быстрым работодателям оказался работодатель с id=107 (компания "Логистик Плюс"), медианное время ответа которого состовляет 3.93 часа.
-- Максимальная медиана (у работодателя с id=102) составляет 4.93 часа.
-- У всех компаний среднее время (6–10 часов) превышает медиану (около 4 часов), а 90-й перцентиь достигает 13-20 часов. Это указывает на наличие более длительных задержек в части переписок.

-- ============================================================
-- БЛОК Г. Сложные типы данных
-- ============================================================

-- Задание 6 Сложные типы данных
-- 6.1. Теги звонков
WITH employer_calls_7d AS (
    SELECT 
        c.call_id,
        c.status,
        c.call_tags
    FROM hh_school.calls c
    JOIN hh_school.responses r ON c.response_id = r.response_id
    WHERE c.caller_role = 'employer'
      AND c.call_at >= r.created_at
      AND c.call_at <= r.created_at + INTERVAL '7 days'
),
valid_calls AS (
    SELECT *
    FROM employer_calls_7d
    WHERE NOT (
        (status = 'successful' AND NOT ('connected' = ANY(call_tags))) OR
        (status = 'unsuccessful' AND NOT ('no_answer' = ANY(call_tags))) OR
        (status = 'error' AND NOT ('technical_error' = ANY(call_tags))))
)
SELECT 
    count(*) FILTER (WHERE 'screening' = ANY(call_tags)) AS screening_calls_count,
    count(*) FILTER (WHERE 'interview' = ANY(call_tags)) AS interview_calls_count,
    count(*) FILTER (WHERE 'follow_up' = ANY(call_tags)) AS follow_up_calls_count,
    count(*) FILTER (WHERE 'details' = ANY(call_tags)) AS details_calls_count,
    count(*) FILTER (WHERE call_tags && ARRAY['screening', 'interview', 'follow_up', 'details']) AS valid_calls_with_any_business_tag,
    round(avg(cardinality(call_tags))::numeric, 2) AS avg_tags_per_valid_call
FROM valid_calls;
-- Полученыее значения:
-- screening: 25
-- interview: 31 
-- follow_up: 29
-- details: 23
-- Валидных звонков хотя бы с одним бизнес-тегом: 108 
-- Среднее количество тегов на один валидный звонок: 4

-- Вывод:
-- Анализ массива call_tags показал согласованность между техническими тегами и статусом звонка.
-- Среднее количество тегов на валидный звонок составляет 4.
-- Среди бизнес-тегов лидируют звонки формата собеседование (interview) - 31, и повторный контакт (follow_up) - 29, а первичный скрининг (screening) - 25 и уточнение деталей (details) - 23 применяются чуть реже.


-- 6.2. Метаданные сообщений
WITH employer_messages_7d AS (
    SELECT 
        m.message_id,
        coalesce(m.message_meta ->> 'channel', 'не указан') AS channel,
        ((m.message_meta ? 'is_read') AND (m.message_meta ->> 'is_read') IS NOT NULL) AS has_read_flag,
        (m.message_meta ->> 'is_read')::boolean AS is_read,
        coalesce(jsonb_array_length(m.message_meta -> 'attachments'), 0) AS attachments_count
    FROM hh_school.messages m
    JOIN hh_school.responses r ON m.response_id = r.response_id
    WHERE m.sender_role = 'employer'
      AND m.sent_at >= r.created_at
      AND m.sent_at <= r.created_at + INTERVAL '7 days'
)
SELECT 
    channel,
    count(*) AS total_messages_count,
    count(*) FILTER (WHERE has_read_flag) AS messages_with_read_flag_count,
    count(*) FILTER (WHERE has_read_flag AND NOT is_read) AS unread_messages_count,
    round(100.0 * count(*) FILTER (WHERE has_read_flag AND NOT is_read) / nullif(count(*) FILTER (WHERE has_read_flag), 0), 2) AS unread_share_pct,
    count(*) FILTER (WHERE attachments_count > 0) AS messages_with_attachments_count,
    round(100.0 * count(*) FILTER (WHERE attachments_count > 0) / count(*), 2) AS attachments_share_pct
FROM employer_messages_7d
GROUP BY channel
ORDER BY channel;

-- Контрольные значения по каналам:
-- 1. Канал mobile_app:
-- всего сообщений: 360
-- количество сообщений с признаком прочтения: 360
-- количество непрочитанных: 36
-- доля непрочитанных: 10.00%
-- количество сообщений с вложениями: 14
-- доля сообщений с вложением: 3.89%
-- 2. Канал web:
-- всего сообщений: 628
-- количество сообщений с признаком прочтения: 628
-- количество непрочитанных: 52
-- доля непрочитанных: 8.28%
-- количество сообщений с вложениями: 25
-- доля сообщений с вложением: 3.98%

-- Вывод:
-- Работодатели отправляют сообщения через два канала: web (628 сообщений, 63.6%) и mobile_app (360 сообщений, 36.4%). Сообщений с не указанным каналом не обнаружено.
-- В обоих каналах признак прочтения присутствует и валиден (не содержит JSON-значений null) в 100% сообщений. 
-- Доля сообщений с признаком непрочитанного сообщения составляет 8.28% в веб-канале и 10.00% в мобильном приложении. 
-- При этом доля сообщений с вложениями практически одинакова: 3.98% в web и 3.89% в mobile_app. 


-- ============================================================
-- БЛОК Д. Самостоятельное исследование
-- ============================================================
-- ЗАДАНИЕ 7 Что связано с приглашением?

-- Формулировка гипотез:
-- Гипотеза 1 Оперативность первого контакта:
-- Доля приглашений выше у откликов, по которым работодатель установил первый контакт с кандидатом в течение 24 часов, чем у откликов с более поздней коммуникацией или вообще без коммуникации в первые 7 дней.

-- Гипотеза 2 Использование двух каналов:
-- Доля приглашений выше среди откликов, по которым работодатель использовал оба канала связи: и звонки, и сообщения в первые 7 дней, чем среди откликов с использованием только одного канала (только звонки или только сообщения) или без коммуникации.

-- Гипотеза 3 Интенсивность коммуникации:
-- Доля приглашений выше среди откликов с высокой интенсивностью коммуникации со стороны работодателя (3 и более событияь за первые 7 дней), чем среди откликов с низкой интенсивностью (1-2 события) или без коммуникации (0 событий).


-- Проверка Гипотезы 1: влияние времени первого контакта на долю приглашений
WITH valid_calls AS (
    SELECT 
        c.response_id,
        c.call_at AS event_at,
        'call' AS event_type
    FROM hh_school.calls c
    JOIN hh_school.responses r ON c.response_id = r.response_id
    WHERE c.caller_role = 'employer'
      AND c.call_at >= r.created_at
      AND c.call_at <= r.created_at + INTERVAL '7 days'
      AND c.status != 'error'
),
valid_messages AS (
    SELECT 
        m.response_id,
        m.sent_at AS event_at,
        'message' AS event_type
    FROM hh_school.messages m
    JOIN hh_school.responses r ON m.response_id = r.response_id
    WHERE m.sender_role = 'employer'
      AND m.sent_at >= r.created_at
      AND m.sent_at <= r.created_at + INTERVAL '7 days'
),
events AS (
    SELECT response_id, event_at, event_type FROM valid_calls
    UNION ALL
    SELECT response_id, event_at, event_type FROM valid_messages
),
response_events_agg AS (
	SELECT 
		response_id,
		count(*) AS total_events,
		min(event_at) AS first_event_at
	FROM events
	GROUP BY response_id
),
responses_with_speed AS (
	SELECT 
		r.response_id,
		r.status,
		coalesce(rea.total_events, 0) AS total_events,
		round((extract(epoch from (rea.first_event_at - r.created_at)) / 3600.0)::numeric, 1) AS hours_to_first_comm,
		CASE 
			WHEN rea.first_event_at IS NULL THEN 'Без коммуникации'
			WHEN extract(epoch from (rea.first_event_at - r.created_at)) / 3600.0 <= 24.0 THEN 'До 24 часов'
            WHEN extract(epoch from (rea.first_event_at - r.created_at)) / 3600.0 <= 72.0 THEN 'От 24 до 72 часов'
            ELSE 'Более 72 часов'
        END AS speed_group
	FROM hh_school.responses r 
	LEFT JOIN response_events_agg AS rea ON r.response_id = rea.response_id
)
SELECT 
	speed_group,
	count(*) AS total_responses,
	count(*) FILTER (WHERE status = 'invited') AS invited_responses,
	round(100.0 * count(*) FILTER (WHERE status = 'invited') / count(*), 1) AS conversion_to_invitation_pct,
    round(percentile_cont(0.5) WITHIN GROUP (ORDER BY hours_to_first_comm)::numeric, 1) AS median_hours_to_first_comm,
    round(avg(total_events)::numeric, 2) AS avg_events_per_response
FROM responses_with_speed
GROUP BY speed_group
ORDER BY speed_group;

-- Вывод:
-- Доля приглашений среди откликов с ответом до 24 часов составляет 14.8% (18 из 122). 
-- Доля приглашений среди откликов с ответом через 24–72 часа составляет 13.6% (14 из 103), а позже 72 часов - 14% (22 из 157).
-- Даже среди откликов без коммуникации доля приглашений составляет 15.4% (38 из 246).
-- Доля в группе до 24 часов выше, чем в двух группах более позднего первого события, но ниже, чем в группе без учтенных событий.
-- Среднее число коммуникаций при наличии контакта держится на уровне 2.7–3.03 события на отклик независимо от того, как быстро работодатель отреагировал (медианы 7.5, 50.7 и 106.3 часов).
-- Гипотеза 1 НЕ ПОДТВЕРЖДАЕТСЯ.

-- Проверка Гипотез 2 и 3: влияние каналов и интенсивности на приглашение
WITH valid_calls AS (
    SELECT 
        c.response_id,
        c.call_at AS event_at,
        'call' AS event_type
    FROM hh_school.calls c
    JOIN hh_school.responses r ON c.response_id = r.response_id
    WHERE c.caller_role = 'employer'
      AND c.call_at >= r.created_at
      AND c.call_at <= r.created_at + INTERVAL '7 days'
      AND c.status != 'error'
),
valid_messages AS (
    SELECT 
        m.response_id,
        m.sent_at AS event_at,
        'message' AS event_type
    FROM hh_school.messages m
    JOIN hh_school.responses r ON m.response_id = r.response_id
    WHERE m.sender_role = 'employer'
      AND m.sent_at >= r.created_at
      AND m.sent_at <= r.created_at + INTERVAL '7 days'
),
events AS (
    SELECT response_id, event_at, event_type FROM valid_calls
    UNION ALL
    SELECT response_id, event_at, event_type FROM valid_messages
),
response_summary AS (
    SELECT 
        r.response_id,
        r.status,
        count(e.event_type) AS total_events,
        count(e.event_type) FILTER (WHERE e.event_type = 'call') AS calls_count,
        count(e.event_type) FILTER (WHERE e.event_type = 'message') AS messages_count
    FROM hh_school.responses r
    LEFT JOIN events e ON r.response_id = e.response_id
    GROUP BY r.response_id, r.status
),
responses_classified AS (
    SELECT 
        response_id,
        status,
        total_events,
        CASE 
            WHEN total_events = 0 THEN 'Без коммуникации'
            WHEN calls_count > 0 AND messages_count > 0 THEN 'Оба канала'
            WHEN messages_count > 0 AND calls_count = 0 THEN 'Только сообщения'
            WHEN calls_count > 0 AND messages_count = 0 THEN 'Только звонки'
        END AS channel_group,
        CASE 
            WHEN total_events = 0 THEN 'Без коммуникации (0 событий)'
            WHEN total_events < 3 THEN 'Низкая интенсивность (1–2 события)'
            ELSE 'Высокая интенсивность (3+ событий)'
        END AS intensity_group
    FROM response_summary
)
-- срез 1: каналы коммуникации (проверка гипотезы 2)
SELECT 
	'Каналы коммуникации' AS aspect,
	channel_group AS group_name,
	count(*) AS total_responses,
	count(*) FILTER (WHERE status = 'invited') AS invited_responses,
	round(100.0 * count(*) FILTER (WHERE status = 'invited') / count(*), 1) AS conversion_to_invitation_pct,
    round(avg(total_events)::numeric, 2) AS avg_events_per_response
FROM responses_classified
GROUP BY channel_group

UNION ALL
-- срез 2: интенсивность взаимодействия (проверка гипотезы 3)
SELECT 
	'Интенсивность взаимодействия' AS aspect,
    intensity_group AS group_name,
    count(*) AS total_responses,
    count(*) FILTER (WHERE status = 'invited') AS invited_responses,
    round(100.0 * count(*) FILTER (WHERE status = 'invited') / count(*), 1) AS conversion_to_invitation_pct,
    round(avg(total_events)::numeric, 2) AS avg_events_per_response
FROM responses_classified
GROUP BY intensity_group

ORDER BY aspect, group_name;

-- Вывод по гипотезе 2:
-- Использование обоих каналов связи (звонки + сообщения) не увеличивает долю приглашений. В группе «Оба канала» зафиксирована самая низкая конверсия - 12.5% (8 из 64). При этом в группе без коммуникаций конверсия равна 15.4%.
-- В моноканале «Только сообщения» конверсия составляет 13.9% (39 из 280), а наибольшая конверсия наблюдается при использовании «Только звонков» - 18.4% (7 из 38). 
-- Гипотеза 2 НЕ ПОДТВЕРЖДАЕТСЯ.

-- Вывод по гипотезе 3:
-- Высокая интенсивность общения не приводит к увеличению доли приглашений. В группе с высокой интенсивностью (3 и более событий) конверсия в приглашенин составляет 13.8% (43 из 312). Это число ниже, чем в группе с низкой интенсивностью (1–2 события) - 15.7% (11 из 70), а в группе вообще без коммуникации - 15.4% (38 из 246). 
-- Гипотеза 3 НЕ ПОДТВЕРЖДАЕТСЯ.


-- Задание 8. Итог исследования (7-10 предложений)

-- За первые 7 дней после отклика работодатели выходят на связь по 60.8% откликов (382 из 628), при этом большинство взаимодействий (90.2%, 988 из 1095) приходится на сообщения, 39.2% откликов остаются без контакта.
-- Среди 988 сообщений работодателей 628 отправлены через веб-канал и 360 через мобильное приложение; доля сообщений с признаком непрочитанного составляет 8.28% и 10% соответственно, а доля сообщений с вложениями в обоих каналах близка к 4%. 
-- Между работодателями наблюдаются различия в обработке откликов: «Академия Данных» обработала 89.5% откликов, а «ТехноБанк» ответил лишь на 45.8%; медианное время первого контакта также различается между компаниями и направлениями: 5.7 часа у «СибирьТелеком» против 76.3 часа у «ТехноБанка». 
-- В переписке найдено 749 случаев, когда сообщение работодателя следовало непосредственно после сообщения кандидата; минимальная медиана времени ответа составила 3.93 часа у «Логистик Плюс», тогда как максимальная среди работодателей достигла 4.93 часа. 
-- Проверка гипотез не подтвердила связь коммуникации с конверсией в приглашение: контакт до 24 часов дает 14.8% приглашений (против 15.4% без коммуникации), использование двух каналов показало лишь 12.5% (против 18.4% у звонков), а высокая интенсивность от 3 событий - 13.8% (против 15.7% при 1–2 событиях).
-- Анализ ограничен семидневным окном наблюдения (учитывались только звонки и сообщения от работодателя в первые 7 дней после отклика), то есть контакты за пределами 7 дней, коммуникация по инициативе кандидата и общение по другим каналам (почта, мессенджеры) не попали в срез.
-- Для следующего этапа исследования стоит проверить, как конверсия в приглашение связана с профессиональным направлением, требованиями вакансии и характеристиками кандидата. 
-- Также стоит выяснить, есть ли различия вероятности приглашения при одинаковых условиях, но разной скорости первого контакта.
