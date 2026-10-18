-- ============================================================
-- Домашнее задание к лекции «SQL. Введение»
-- Школа Аналитиков · учебная база hh_school
-- Автор: Рытикова Кирена Игоревна
-- ============================================================
-- Формат: задания по порядку, каждое начинается с комментария
-- с номером; под каждым запросом — вывод (2–3 предложения).
-- Запрос без вывода не засчитывается.
-- ============================================================
 SET search_path = hh_school;
-- ============================================================
-- БЛОК А. Разминка: термины и структура (текстом)
-- ============================================================

-- ЗАДАНИЕ А1
-- 1. Категория и конкретный тип колонок:
--    vacancies.salary_from        — категория: числовой      тип: INTEGER
--    vacancies.vacancy_name       — категория: строковый     тип: TEXT
--    vacancies.published_at       — категория: дата и время  тип: TIMESTAMP
--    employers.is_accredited_it   — категория: логический    тип: BOOLEAN
--    responses.created_at         — категория: дата и время  тип: TIMESTAMP
--
-- 2. Первичные ключи таблиц:
--    areas: area_id
--    employers: employer_id
--    vacancies: vacancy_id
--    vacancy_details: vacancy_id (чем особенный: одновременно является и первичным ключом, и внешним ключом (FOREIGN KEY REFERENCES vacancies(vacancy_id)), реализуя отношение связи 1:1, и гарантируя, что у каждой вакансии существует не более одного описания)
--    responses: response_id
--
-- 3. Почему vacancy_name не может быть первичным ключом:
--    Первичный ключ - это колонка или набор колонок, которая уникально идентифицирует строку (первичный ключ уникален для каждой записи в таблице и не может быть NULL). 
--    Названия вакансий (vacancy_name) часто дублируются, поэтому если бы колонка vacancy_name была первичным ключом, 
--    БД запретила бы добавить вторую вакансию с аналогичным названием.
		 
--    Запрос для подтверждения числом: запрос, который покажет, сколько раз в базе встречается самое частое название вакансии
-- запрос:
SELECT
	vacancy_name,
	count(*) AS vacancy_count
FROM
	vacancies
GROUP BY
	vacancy_name
ORDER BY
	vacancy_count DESC
LIMIT 1;
-- Вывод:
-- Наименование «Стажёр: аналитик данных» повторяется 6 раз, что доказывает отсутствие уникальности текстового названия
-- Использование повторяющихся строк в качестве первичного ключа привело бы к невозможности завести несколько однотипных позиций и к потере целостности связей.
--
--
-- 4. Что произойдёт при записи строки «по договорённости» в salary_from:
-- Возникнет ошибка несовместимости типов.
-- Такое поведение СУБД защищает целостность данных. Так как если бы строковые значения попали в числовую колонку,мы не смогли бы применять математические функции, фильтрацию диапазонов и сортировку.
-- Для отсутствующих или несогласованных значений предусмотрен NULL, что предотвращает ошибки в расчетах.

-- ============================================================
-- БЛОК Б. Первые запросы: SELECT, WHERE, ORDER BY
-- ============================================================
-- ЗАДАНИЕ Б1
-- Запрос: experience
SELECT
	DISTINCT v.experience
FROM
	vacancies v;
-- От 3 до 6 лет
-- Нет опыта
-- От 1 года до 3 лет

-- Запрос: employment
SELECT
	DISTINCT v.employment
FROM
	vacancies v;
-- Частичная занятость
-- Стажировка
-- Полная занятость

-- Запрос: professional_role
SELECT
	DISTINCT v.professional_role
FROM
	vacancies v;
-- Дата-инженер
-- Разработчик
-- Продуктовый аналитик
-- Аналитик данных
-- Тестировщик

-- Вывод:
-- В колонке experience обнаружено 3 различных значения ('От 3 до 6 лет', 'Нет опыта', 'От 1 года до 3 лет').
-- В колонке employment также 3 различные значения ('Частичная занятость, 'Стажировка', 'Полная занятость').
-- В колонке professional_role обнаружено 5 значений ('Дата-инженер', 'Разработчик', 'Продуктовый аналитик', 'Аналитик данных', 'Тестировщик').
-- Признаков проблем с качеством данных не обнаружено: отсутствуют неожиданные значения NULL, нет опечаток и дубликатов из-за разного регистра, пробелов.

-- ЗАДАНИЕ Б2
-- Запрос 1: стажировки в Москве без опыта, вакансия открыта
SELECT 
	v.vacancy_id, 
	v.vacancy_name, 
	v.salary_from, 
	v.published_at
FROM
	vacancies v
JOIN areas a
		USING (area_id)
WHERE 
	a.area_name = 'Москва'
	AND
	v.experience = 'Нет опыта'
	AND v.employment = 'Стажировка'
	AND v.closed_at IS NULL
ORDER BY
	published_at DESC;
-- Запрос 2: топ-10 вакансий по salary_from
SELECT
	v.vacancy_name,
	v.professional_role ,
	v.salary_from
FROM
	vacancies v
WHERE
	v.salary_from IS NOT NULL
ORDER BY
	salary_from DESC
LIMIT 10;
-- Вывод:
-- Первый запрос нашел 8 вакансий. Если убрать условие про Москву (a.area_name = 'Москва'), то количество открытых вакансий вырастет всего до 10.
-- 80% вакансий стажировок находятся в Москве. Это означает, что найти стажировку не в столице сложно.
--

-- ЗАДАНИЕ Б3
-- Ловушка 1. NULL — выполнить и объяснить результат
SELECT
	count(*)
FROM
	vacancies
WHERE
	closed_at = NULL;

SELECT
	count(*)
FROM
	vacancies
WHERE
	closed_at IS NULL;
-- Ловушка 2. AND / OR — выполнить и объяснить результат
SELECT
	count(*)
FROM
	vacancies
WHERE
	area_id = 1
	OR area_id = 2
	AND experience = 'Нет опыта';

SELECT
	count(*)
FROM
	vacancies
WHERE
	(area_id = 1
		OR area_id = 2)
	AND experience = 'Нет опыта';
-- Вывод:
-- Первый запрос с NULL возвращает 0 строк без ошибки, так как в SQL любое сравнение с NULL даёт UNKNOWN, который фильтр WHERE всегда отсекает.
-- Это опаснее синтаксической ошибки, поскольку запрос выполняется и выдаёт ложную цифру, создавая иллюзию отсутствия открытых вакансий; содержательно же NULL в closed_at означает отсутствие даты закрытия (вакансия ещё активна).
-- Во второй паре оператор AND имеет приоритет перед OR, поэтому первое условие звучит как: «все вакансии Москвы с любым опытом ИЛИ вакансии Санкт-Петербурга без опыта» (31 строка). 
-- На вопрос соискателя ("вакансии из Москвы или Санкт-Петербурга, но обязательно без опыта") корректно отвечает только второй запрос, в котором расставлены скобки (он вывел 20 строк), который строго объединяет города до фильтрации по опыту.

-- ============================================================
-- БЛОК В. Агрегации и метрики
-- ============================================================
-- ЗАДАНИЕ В1
-- Запрос 1: счётчики (строки, зарплата указана, направления, работодатели)
SELECT 
	count(*) AS total_vacancies,
	count(v.salary_from) AS vacancies_with_salary,
	count(DISTINCT v.professional_role) AS total_roles,
	count(DISTINCT employer_id) AS total_employers
FROM
	vacancies v;
-- Запрос 2: доля активных вакансий (без JOIN)
SELECT 
	count(*) FILTER (
	WHERE closed_at IS NULL) AS open_vacancies,
	count(*) FILTER (
	WHERE closed_at IS NOT NULL) AS closed_vacancies,
	round(100.0 * count(*) FILTER (WHERE closed_at IS NULL) / count(*), 1) AS percent_open_vacancies
FROM
	vacancies v;
-- Вывод:
-- Разница между count(*), count(колонка) и count(DISTINCT колонка) видна на конкретных числах: count(*) возвращает общее число строк в таблице (52), count(salary_from) считает только строки с заполненной зарплатой (44, игнорирует 8 значений NULL), а count(DISTINCT employer_id) находит 12 уникальных работодателей.
-- Сейчас у нас активны 33 вакансии из 52, что составляет 63.5% от всей базы (остальные 19 вакансий уже закрыты)

-- ЗАДАНИЕ В2
-- Запрос 1: направления — вакансии, работодатели, средняя зарплата
SELECT 
	v.professional_role,
	count(*) AS vacancies_count,
	count(DISTINCT v.employer_id) AS employers_count,
	round(avg(v.salary_from)) AS avg_salary_from
FROM
	vacancies v
GROUP BY
	professional_role
ORDER BY
	vacancies_count DESC;
-- Запрос 2: то же, только направления с ≥ 5 открытыми вакансиями (WHERE + HAVING)
SELECT 
	v.professional_role,
	count(*) AS vacancies_count,
	count(DISTINCT v.employer_id) AS employers_count,
	round(avg(v.salary_from)) AS avg_salary_from
FROM
	vacancies v
WHERE
	v.closed_at IS NULL
GROUP BY
	professional_role
HAVING
	count(*) >= 5
ORDER BY
	vacancies_count DESC;
-- Вывод:
-- Больше половины рынка учебной базы (31 вакансию из 52, или 59.6%) занимают два направления: «Аналитик данных» (16) и «Разработчик» (15).
-- На основании этой таблицы соискатель сделал бы вывод, что идти в разработку выгоднее всего (много позиций и высокая средняя зарплата от 89 тысяч). Такой вывод нельзя считать обоснованным, так как не хватет уровня конкуренции (число соискателей на место) и распределения по грейдам.
-- Условие «closed_at is null» («только открытые вакансии») пишется в where, так как фильтрует отдельные строки до группировки, а «count(*) >= 5» пишется в having, так как нужна фильтрация групп после агрегации. 
-- Если попытаться написать "WHERE count(*) >= 5", то возникнет ошибка, так как агрегатные функции в where запрещены.
-- Метрика avg(salary_from) отвечает на вопрос о средней минимальной зарплате (среди вакансий с раскрытой зарплатой), но она не показывает реальную зарплату, которую человек будет получать на руки, верхний предел (salary_to) и уровень дохода в скрытых вакансиях.

-- ============================================================
-- БЛОК Г. Соединение таблиц
-- ============================================================
-- ЗАДАНИЕ Г1
-- Запрос: топ-5 по salary_from с названием компании и городом (псевдонимы таблиц)
SELECT 
	v.vacancy_name,
	e.employer_name,
	a.area_name,
	v.salary_from
FROM
	vacancies v
JOIN employers e ON
	v.employer_id = e.employer_id
JOIN areas a ON
	v.area_id = a.area_id
ORDER BY
	salary_from DESC NULLS LAST
LIMIT 5;
-- Вывод:
-- Если убрать псевдонимы и написать просто area_id, то возникнет ошибка неоднозначности («column reference is ambiguous»)
-- Это происходит из-за того, что колонка area_id присутствует в нескольких участвующих в запросе таблицах (vacancies, employers, areas), PostgreSQL не может определить, из какой именно таблицы брать значение без явного указания.

-- ЗАДАНИЕ Г2
-- Запрос 1: все работодатели, число вакансий и откликов (LEFT JOIN)
SELECT 
	e.employer_name,
	count(DISTINCT v.vacancy_id) AS vacancies_count,
	count(r.response_id) AS responses_count
FROM
	employers e
LEFT JOIN vacancies v ON
	e.employer_id = v.employer_id
LEFT JOIN responses r ON
	v.vacancy_id = r.vacancy_id
GROUP BY
	e.employer_name
ORDER BY
	responses_count DESC;
-- Запрос 2: тот же запрос с INNER JOIN
SELECT 
	e.employer_name,
	count(DISTINCT v.vacancy_id) AS vacancies_count,
	count(r.response_id) AS responses_count
FROM
	employers e
INNER JOIN vacancies v ON
	e.employer_id = v.employer_id
INNER JOIN responses r ON
	v.vacancy_id = r.vacancy_id
GROUP BY
	e.employer_name
ORDER BY
	responses_count DESC;
-- Вывод:
-- Количество вакансий считается через count(distinct v.vacancy_id), так как соединение с таблицей responses размножает строки вакансии пропорционально числу поступивших откликов; обычный count(*) посчитал бы количество откликов, а не вакансий.
-- Во втором запросе (inner join) исчезла компания «ГринЭнерго» (число строк изменилось с 12 до 11). Это содержательная потеря, поскольку это компания с нулевым числом откликов, с которой и требовалось обсудить причины отсутствия интереса соискателей.
-- Правило выбора inner join и left join: inner join используется, когда нужны только связанные записи без пропусков (совпадение в обеих таблицых), а left join используется, если необходимо сохранить все строки основной (левой) таблицы (при отсутствии совпадений поля правой заполняются NULL).

-- Проверка компании «ГринЭнерго» (действительно ли у нее 0 отклика из-за отсутсвия интереса со стороны соискателей):
-- Проверка наличия открытых вакансий
SELECT 
	vacancy_id, 
	v.vacancy_name, 
	employer_name
FROM 
	hh_school.vacancies v 
JOIN hh_school.employers e using (employer_id)
WHERE e.employer_name = 'ГринЭнерго' 
	AND v.closed_at IS NULL;
-- Обнаружено 0 открытых вакансий у компании «ГринЭнерго». У компании физически нет открытых вакансий для отклика, говорить об "отсутствии интереса" неккоректно.
SELECT 
	e.employer_name,
	v.vacancy_id,
	v.vacancy_name,
	v.salary_from,
	v.salary_to,
	v.published_at,
	v.closed_at,
	count(r.response_id) AS responses_count
FROM hh_school.employers e
LEFT JOIN hh_school.vacancies v ON e.employer_id = v.employer_id
LEFT JOIN hh_school.responses r ON v.vacancy_id = r.vacancy_id
WHERE e.employer_name = 'ГринЭнерго'
GROUP BY 1, 2, 3, 4, 5, 6, 7;
-- Почему единственная вакансия компании не получила откликов за почти месяц публикации (06.04.2026–04.05.2026): 
-- Проверим, получали ли отклики похожие вакансии стажеров разработчиков:
SELECT 
	v.vacancy_id,
	e.employer_name,
	e.is_accredited_it,
	a.area_name,
	v.professional_role,
	v.vacancy_name,
	COALESCE(v.salary_from::text ||'-' || v.salary_to::text, 'не указана') AS salary_range,
	v.published_at::date AS published_date,
	v.closed_at::date AS closed_date,
	count(r.response_id) AS responses_count
FROM hh_school.vacancies v
JOIN hh_school.employers e ON v.employer_id = e.employer_id
JOIN hh_school.areas a ON v.area_id = a.area_id
LEFT JOIN hh_school.responses r ON v.vacancy_id = r.vacancy_id
WHERE 
	v.professional_role = 'Разработчик' AND (v.employment = 'Стажировка' OR v.experience = 'Нет опыта') 
GROUP BY 
	v.vacancy_id, e.employer_name, e.is_accredited_it, a.area_name, v.professional_role, v.vacancy_name, salary_range, v.published_at, v.closed_at
ORDER BY responses_count DESC;
-- Из этого запроса видно, что вакансии компании "СибирьТелеком" также получили 0 откликов за продолжительный период публикации.
-- Можно выдвинуть гипотезу о недостаточной видимости вакансий от неакредитованных it-компаний (причем детали вакансий одинаковые). 
-- Также в вакансии не указана заработная плата, что тоже немного влияет на привлекательность и отклики (в среднем вакансии без указанной зарплаты получают 9.5 откликов, с указанием зарплаты 12.5).

-- Запрос для сравнения вакансий вакансий с зарплатой и без зарплаты:
WITH vacancy_responses AS (
    SELECT 
        v.vacancy_id,
        CASE 
            WHEN v.salary_from IS NULL AND v.salary_to IS NULL THEN 'без указанной зарплаты'
            ELSE 'с указанной зарплатой'
        END AS salary_status,
        count(r.response_id) AS responses_count
    FROM vacancies v
    LEFT JOIN responses r ON v.vacancy_id = r.vacancy_id
    GROUP BY v.vacancy_id, v.salary_from, v.salary_to)
SELECT 
    salary_status,
    count(*) AS vacancies_count,
    sum(responses_count) AS total_responses,
    round(avg(responses_count), 1) AS avg_responses_per_vacancy
FROM vacancy_responses
GROUP BY salary_status
ORDER BY avg_responses_per_vacancy DESC;


-- ============================================================
-- БЛОК Д. Функции и финальный кейс
-- ============================================================
-- ЗАДАНИЕ Д1
-- Запрос: помесячная динамика откликов и конверсия
-- (месяц как дата, условный агрегат, nullif в знаменателе)
SELECT 
	date_trunc('month', r.created_at)::date AS MONTH, 
	count(*) AS responses_count,
	count(*) FILTER (
	WHERE r.status = 'invited') AS invitations_count,
	round(100.0 * count(*) FILTER (WHERE r.status = 'invited') / NULLIF(count(*), 0), 1) AS conversion
FROM
	responses r
GROUP BY
	date_trunc('month', r.created_at)::date
ORDER BY
	MONTH;
-- Вывод:
-- Максимальная конверсия зафиксирована в июне 2026 года (2026-06-01) и составила 19.5% (23 приглашения на 118 откликов).
-- Этому месяцу можно доверять при оценке, так как он подтверждён внушительным объёмом данных (118 откликов), в отличие от января и февраля (24 и 55 откликов), где проценты подвержены погрешности малой выборки.
-- Последний месяц (август 2026) необходимо исключить из выводов потому что он представлен неполными данными (только первая половина месяца, до 15 августа), отклики ещё не успели перейти в статус приглашений, что искусственно занижает конверсию до 7.3%.

-- Подтвержающий запрос, что август 2026 необходимо исключить из выводов (проверка неполноты данных):
SELECT 
	date_trunc('month', r.created_at)::date AS MONTH,
	min(r.created_at)::date AS first_response_date,
	max(r.created_at)::date AS last_response_date,
	(date_trunc('month', r.created_at) + INTERVAL '1 month' - INTERVAL '1 day')::date AS month_end_date,
	count(DISTINCT r.created_at::date) AS active_days,
	count(*) AS responses_count,
	count(*) FILTER (WHERE r.status='invited') AS invitations_count,
	round(100.0 * count(*) FILTER (WHERE r.status = 'invited') / NULLIF(count(*), 0), 1) AS conversion
FROM hh_school.responses r 
GROUP BY date_trunc('month', r.created_at)::date, 4
ORDER BY MONTH;
-- Обоснование на основе подтверждающего запроса:
-- По результатам запроса: первый отклик зарегистрирован 1 августа, а последний 15 августа (то есть ровно середина месяца, конец месяца 31 августа), что указывпет на вероятную неполноту периода наблюдения за август.
-- За этот период поступил 41 отклик (против 142 в июле и 118 в июне), из которых 2 имеют статус "invited", конверсия составляет 7.3%.
-- Так как август охватывает только часть календарного меясца, его показатели нельзя сопостовлять с показателями полных месяцев. 


-- ЗАДАНИЕ Д2
-- Запрос: таблица по направлениям (вакансии, отклики, приглашения, откликов на вакансию, конверсия)
SELECT 
	v.professional_role,
	count(DISTINCT v.vacancy_id) AS vacancies_count,
	count(r.response_id) AS responses_count,
	count(r.response_id) FILTER (WHERE r.status = 'invited') AS invitations_count,
	round(count(r.response_id)::NUMERIC / NULLIF(count(DISTINCT v.vacancy_id), 0), 1) AS responses_per_vacancy,
	round(100.0 * count(r.response_id) FILTER (WHERE r.status = 'invited')/ NULLIF(count(r.response_id), 0), 1) AS CONVERSION
FROM
	vacancies v
LEFT JOIN responses r ON
	v.vacancy_id = r.vacancy_id
GROUP BY
	professional_role
ORDER BY
	vacancies_count DESC;
-- Письменные ответы:
-- 1. Совпадает ли направление с наибольшим числом вакансий с направлением с наибольшей конверсией?
-- Нет, направление с наибольшим числом вакансий не совпадает с направлением с наибольшей конверсией. 
-- Направление с наибольшим числом вакансий: «Аналитик данных» (16 позиций) показало одну из самых низких конверсий(12.1%) из-за высокой конкуренции. 
-- Наибольшая конверсия зафиксирована у направления «Тестировщик» (35.9%), где открыто всего 7 вакансий.
-- 2. Какое направление выбрать и почему (опираясь на два столбца):
-- Для отклика перспективным выбором является направление «Тестировщик», потому что данное направление показало низкую конкуренцию (всего 5.6 отклика на вакансию) и максимальную конверсию в приглашения (35.9%).
-- 3. Оговорка к выводу:
-- В данных отсутствует разделения по грейдам и реальному уровню зарплат. Высокая конверсия в тестировании может отражать низкий порог входа на позиции с невысокой оплатой; приглашение на собеседование не являются грантией трудоустройства.

-- Проверка, действительно ли вакансии тестировщиков отличаются по зарплате и требованиям к опыту:
SELECT 
	v.professional_role,
	count(DISTINCT v.vacancy_id) AS total_vacancies,
	count(DISTINCT v.vacancy_id) FILTER (WHERE v.experience = 'Нет опыта') AS no_experience_vacancies,
	round(100.0 * count(DISTINCT v.vacancy_id) FILTER (WHERE v.experience = 'Нет опыта') / count(DISTINCT v.vacancy_id), 1) AS no_experience_pct,
	round(avg(v.salary_from)) AS avg_salary_from,
	min(v.salary_from) AS min_salary_from,
	max(v.salary_to) AS max_salary_to
FROM vacancies v
GROUP BY 1
ORDER BY avg_salary_from;
-- Гипотеза о том, что высокая конверсия в тестировании связана с низким порог входа на позиции с невысокой оплатой, подтверждается данными.
-- Средняя зарплата в тестировании самая низкая среди всех 5 направлений базы: 56429 (в аналитике данных - 77000, в разработке - 89167).
-- 57.1% вакансий тестировщиков (4 из 7) являются позициями для кандидатов без опыта с зарплатой от 30000.


-- ============================================================
-- БЛОК Е. Со звёздочкой
-- ============================================================
-- ЗАДАНИЕ Е1
-- Исходный запрос (выполнить и посмотреть результат):
 SELECT 
	 v.professional_role,
	 count(*) AS vacancies,
	 sum(v.salary_from) AS total_salary,
	 count(r.response_id) / count(*) AS responses_per_vacancy
FROM
	vacancies v
JOIN responses r ON
	v.vacancy_id = r.vacancy_id
WHERE
	v.closed_at = NULL
GROUP BY
	1;
--
-- Ошибки (минимум четыре):
-- 1. Неверное условие 'WHERE v.closed_at = NULL'. Правильный вариант: WHERE v.closed_at IS NULL. Так как нельзя сравнивать сравнение с NULL через равенство, запрос возвращает 0 строк.
-- 2. Использование INNER JOIN. Вакансии без откликов отсекаются, что искажает расчет рынка открытых вакансий (необходимо использовать LEFT JOIN, чтобы сохранить все открытые вакансии).
-- 3. count(*) AS vacancies считает отклики, а не вакансии (из-за того, что строки вакансий дублируются по числу откликов). Количество вакансий необходимо считать так: count(DISTINCT v.vacancy_id).
-- 4. count(r.response_id) / count(*) делит отклики на отклики (результат 1), отсутствует зашита от деления на 0.
-- 5. sum(v.salary_from) складывает зарплату одной вакансии по несколько раз, завышая сумму. Необходима агрегация откликов до соединения (подзапрос).
-- Метрика sum(v.salary_from) складывает нижние границы зарплат всех вакансий каждого направления. Сумма зависит от количества вакансий в каждой категории, поэтому на основе этих данных нельзя сказать, что, например, аналитики зарабатывают в 2.4 раза больше, чем тестировщики.
-- Метрика не показывает типичную зарплату и не позволяет сравнить оплату труда в разных направлениях (так как зависит от количества вакансий). Сумма может быть занижена (из-за пропусков в вакансиях), а также она не репрезентует реальный доход специалистов разных грейдов. Метрика обладает низкой валидностью и не подходит для сравнения уровня зарплаты по направлениям.
-- Чтобы получить реальную картину, можно посмотреть на:
-- среднюю зарплату от (avg(salary_from)), которая позволит сравнить среднюю стартовую зарплату направлений между собой, но данная метрика чувствительна к выбросам; 
-- медианную зарплату от (percentile_cont(0.5)), которая покажет середину распределения нижних границ; 
-- min(salary_from) и max(salary_from) - вилка рынка;

SELECT 
	 v.professional_role,
	 count(DISTINCT v.vacancy_id ) AS vacancies,
	 sum(v.salary_from) AS total_salary,
	 round(avg(v.salary_from)) AS avg_salary_from,
	 PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY v.salary_from) AS mediana_salary_from,
	 min(v.salary_from) AS min_salary_from,
	 max(v.salary_from) AS max_salary_from,
	 round(sum(COALESCE(t.responses_count, 0))::NUMERIC / NULLIF(count(DISTINCT v.vacancy_id), 0), 1) AS responses_per_vacancy
FROM
	vacancies v
LEFT JOIN 
 	(
	SELECT
		vacancy_id,
		count(*) AS responses_count
	FROM
		responses r
	GROUP BY
		vacancy_id) t ON
	v.vacancy_id = t.vacancy_id
WHERE
	v.closed_at IS NULL
GROUP BY
	1
ORDER BY
	2 DESC;
-- Получаем результат: наибольшая конкуренция наблюдается на направлении «Аналитик данных» (21.5 отклика на вакансию) и «Продуктовый аналитик» (17.8). 
-- Наибольшая средняя нижняя граница наблюдается у разработчиков (95000), а наибольшая медианная нижняя граница у продуктовых аналитиков (95000). 
-- Минимальные и максимальные нижние границы зарплат показывают разброс предложений: например, у разработчиков эти значения варьируются от 50000 до 195000, а у тестировщиков от 30000 до 130000.

-- Какие два правила из лекции защитили бы от этих ошибок при написании запроса:
-- 1. Учет связей и подсчет реальных сущностей через первичный ключ. Связь 1:N ("один ко многим"): у одной вакансии может быть много откликов. При соединении таблиц через JOIN строки родительской таблицы (vacancies) дублируются столько раз, сколько записей нашлось в responses. LEFT JOIN сохраняет все строки левой таблицы, когда нельзя потерять строки основной таблицы.
-- 2. Работа с NULL и операцией деления. NULL — это не специальное значение вроде 0 или пустой строки, это отсутствие значения, поэтому нельзя написать WHERE closed_at = NULL. Защита знаменателя через nullif().

