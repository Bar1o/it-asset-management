-- ЗАПРОСЫ

/* Задача: Обновить состояние активов, находящихся в ремонте, 
на "Working" и получить список сотрудников, которым они назначены, сгруппированный по департаментам (получим всех сотрудников, у которых сейчас в на руках есть оборудование).*/
UPDATE Asset
SET condition = 'Working'
WHERE condition = 'Repair';
SELECT d.name AS department, e.name, e.surname, COUNT(a.asset_id) AS assets_count
FROM Employee e
INNER JOIN Department d ON e.dept_id = d.dept_id
LEFT JOIN Assignment ass ON e.employee_id = ass.employee_id
LEFT JOIN Asset a ON ass.asset_id = a.asset_id
WHERE a.condition = 'Working'
GROUP BY d.name, e.name, e.surname
ORDER BY assets_count DESC;

/*Задача (вложенный): Добавить новое поле в таблицу Employee для хранения даты 
найма и получить список сотрудников, у которых максимальная дата обслуживания 
активов позже даты найма. То есть сотрудники могут пользоваться рабочим 
устройством и все хорошо.*/
ALTER TABLE Employee ADD COLUMN hire_date DATE;

UPDATE Employee SET hire_date = '2022-01-01' WHERE employee_id = 1;
UPDATE Employee SET hire_date = '2022-02-15' WHERE employee_id = 2;
UPDATE Employee SET hire_date = '2022-03-10' WHERE employee_id = 3;
UPDATE Employee SET hire_date = '2022-04-20' WHERE employee_id = 4;
UPDATE Employee SET hire_date = '2022-05-30' WHERE employee_id = 5;
UPDATE Employee SET hire_date = '2022-06-15' WHERE employee_id = 6;

SELECT e.name, e.surname, e.hire_date, MAX(m.date) AS last_maintenance
FROM Employee e
INNER JOIN Assignment ass ON e.employee_id = ass.employee_id
INNER JOIN Maintenance m ON ass.assignment_id = m.assignment_id
WHERE m.date > (SELECT hire_date FROM Employee WHERE employee_id = e.employee_id)
GROUP BY e.name, e.surname, e.hire_date
ORDER BY last_maintenance DESC;

/* Задача (вложенный): Получить список оборудования, которое 
не назначены сотрудникам с руководителями, и отсортировать по типу активов.*/
SELECT DISTINCT a.name, a.type
FROM Asset a
LEFT JOIN Assignment ass ON a.asset_id = ass.asset_id
WHERE ass.employee_id NOT IN (SELECT employee_id FROM Employee WHERE manager_id IS NOT NULL)
UNION
SELECT a.name, a.type
FROM Asset a
WHERE a.asset_id NOT IN (SELECT asset_id FROM Assignment)
ORDER BY type, name;

/* Задача: Подсчитать общее количество активов каждого 
типа в департаментах и вывести только те типы, где сумма активов больше 1. */
SELECT a.type, d.name AS department, COUNT(a.asset_id) AS asset_count
FROM Asset a
INNER JOIN Department d ON a.dept_id = d.dept_id
GROUP BY a.type, d.name
HAVING COUNT(a.asset_id) > 1
ORDER BY asset_count DESC;

/* Задача (вложенный): Обновить тип назначения оборудования на "Temporary" для сотрудников,
у которых есть подчиненные, и вывести их имена с количеством подчиненных.*/

UPDATE Assignment
SET type = 'Temporary'
WHERE employee_id IN (SELECT manager_id FROM Employee WHERE manager_id IS NOT NULL);

SELECT e.name, e.surname, COUNT(sub.employee_id) AS subordinates
FROM Employee e
LEFT JOIN Employee sub ON e.employee_id = sub.manager_id
WHERE e.employee_id IN (SELECT employee_id FROM Assignment WHERE type = 'Temporary')
GROUP BY e.name, e.surname
HAVING COUNT(sub.employee_id) > 0
ORDER BY subordinates DESC;

/*Задача:
Получить список городов, максимальную вместимость департаментов и 
среднюю стоимость оборудования, которым владеет департамент.
Добавить столбец big_city (True / False), еслит суммарная вместимость в городе 
по департаментам не менее 40 человек.
*/

SELECT l.city,  MAX(d.capacity) AS max_capacity, AVG(a.cost) AS avg_asset_cost,
CASE 
  WHen MAX(d.capacity) >= 40 then 'True'
  ELSE 'False'
  END as big_city
FROM Location l
INNER JOIN Department d ON l.location_id = d.location_id
INNER JOIN Asset a ON d.dept_id = a.dept_id
GROUP BY l.city
ORDER BY max_capacity DESC;

/* Задача: Объединить списки активов в состоянии 'Working' и 'New', 
отсортированных по департаментам.*/

SELECT a.name, a.condition, d.name AS department
FROM Asset a
INNER JOIN Department d ON a.dept_id = d.dept_id
WHERE a.condition = 'Working'
UNION
SELECT a.name, a.condition, d.name AS department
FROM Asset a
INNER JOIN Department d ON a.dept_id = d.dept_id
WHERE a.condition = 'New'
ORDER BY department, condition;

/* Задача: Установить монитору Samsung состояние 'Repair'. 
Получить список поставщиков, оборудование которых сейчас в ремонте, 
указать кол-во единиц оборудования в ремонте.*/

UPDATE Asset SET condition = 'Repair' WHERE name = 'Монитор Samsung';

SELECT v.name AS vendor, COUNT(a.asset_id) AS repair_count
FROM Vendor v
INNER JOIN Asset_Vendor av ON v.vendor_id = av.vendor_id
INNER JOIN Asset a ON av.asset_id = a.asset_id
WHERE a.condition = 'Repair'
GROUP BY v.name
HAVING COUNT(a.asset_id) > 0
ORDER BY repair_count DESC;

/* Задача: Найти сотрудников, у которых количество оборудования больше или равно
минимальному по компании, с указанием их департамента.*/

SELECT e.name, e.surname, d.name AS department, COUNT(ass.asset_id) AS asset_count
FROM Employee e
INNER JOIN Department d ON e.dept_id = d.dept_id
LEFT JOIN Assignment ass ON e.employee_id = ass.employee_id
GROUP BY e.name, e.surname, d.name
HAVING COUNT(ass.asset_id) >= (
    SELECT MIN(asset_count)
    FROM (
        SELECT COUNT(ass2.asset_id) AS asset_count
        FROM Employee e2
        LEFT JOIN Assignment ass2 ON e2.employee_id = ass2.employee_id
        GROUP BY e2.employee_id
    ) AS min_assets
)
ORDER BY asset_count DESC;

/* Задача: Подсчитать суммарную вместимость департаментов в каждом городе и вывести только те, 
где есть активы 'Laptop'.*/

SELECT l.city, SUM(d.capacity) AS sum_capacity
FROM Location l
INNER JOIN Department d ON l.location_id = d.location_id
INNER JOIN Asset a ON d.dept_id = a.dept_id
WHERE a.type = 'Laptop'
GROUP BY l.city
ORDER BY sum_capacity DESC;

/* Запрос с рекурсивным CTE для построения иерархии сотрудников, начиная с тех, у кого нет руководителя, 
и рекурсивно добавляет подчинённых с указанием уровня в иерархии.*/

WITH RECURSIVE EmployeeHierarchy AS (
    SELECT employee_id, name, surname, manager_id, 0 AS level -- нач. ур. иерархии
    FROM Employee
    WHERE manager_id IS NULL -- самые верхние в иерархии
    UNION ALL
    SELECT e.employee_id, e.name, e.surname, e.manager_id, eh.level + 1
    FROM Employee e
    INNER JOIN EmployeeHierarchy eh ON e.manager_id = eh.employee_id
)
SELECT * FROM EmployeeHierarchy ORDER BY level, surname, name;

/* Запрос с подзапросами для анализа сотрудников возвращает информацию о сотрудниках, 
включая количество их назначений и дату последнего обслуживания оборудования.*/

SELECT 
    e.name,
    e.surname,
    (SELECT COUNT(*) FROM Assignment ass WHERE ass.employee_id = e.employee_id) AS assignment_count,
    (SELECT MAX(m.date) FROM Maintenance m 
     INNER JOIN Assignment ass ON m.assignment_id = ass.assignment_id 
     WHERE ass.employee_id = e.employee_id) AS last_maintenance
FROM Employee e
ORDER BY e.surname, e.name;

/* Задача: Создать представление для оборудования и поставщиков, 
затем вывести отчет с количеством оборудования по поставщикам.

Создаем VIEW для объединения активов и поставщиков. 
Затем выводим отчет с количеством активов по поставщикам, 
используя GROUP BY, HAVING и ORDER BY.*/

CREATE VIEW AssetVendorSummary AS
SELECT a.name AS asset_name, a.type, v.name AS vendor_name
FROM Asset a
INNER JOIN Asset_Vendor av ON a.asset_id = av.asset_id
INNER JOIN Vendor v ON av.vendor_id = v.vendor_id;

SELECT vendor_name, COUNT(asset_name) AS asset_count
FROM AssetVendorSummary
GROUP BY vendor_name
ORDER BY asset_count DESC;

/* Задача: Получить уникальное оборудование с "ASUS" в названии,
назначенное только сотрудникам без руководителей, отсортированное по типу.
*/
SELECT DISTINCT a.name, a.type
FROM Asset a
INNER JOIN Assignment ass ON a.asset_id = ass.asset_id
INNER JOIN Employee e ON ass.employee_id = e.employee_id
WHERE e.manager_id IS NULL AND a.name LIKE '%ASUS%'
EXCEPT
SELECT DISTINCT a.name, a.type
FROM Asset a
INNER JOIN Assignment ass ON a.asset_id = ass.asset_id
INNER JOIN Employee e ON ass.employee_id = e.employee_id
WHERE e.manager_id IS NOT NULL AND a.name LIKE '%ASUS%'
ORDER BY a.type;

/* Задача: Обновить состояние активов на 'Working' для тех, что были в ремонте более месяца назад, и вывести отчет.*/
UPDATE Asset
SET condition = 'Working'
WHERE condition = 'Repair' AND asset_id IN (
    SELECT asset_id
    FROM Maintenance
    WHERE date < DATE('now', '-1 month')
);

SELECT a.name, a.type, COUNT(m.maintenance_id) AS maintenance_count
FROM Asset a
NATURAL JOIN Maintenance m
WHERE a.condition = 'Working'
GROUP BY a.name, a.type
ORDER BY maintenance_count DESC;


/* Задача: Получить сотрудников, у которых есть общие активы типа 
'Laptop' и 'Printer', с количеством активов.

Примечание: таких сотрудников нет, но запрос корректен.
Используем INTERSECT для поиска сотрудников с активами обоих типов (вложенный запрос).
*/
SELECT e.name, e.surname, COUNT(ass.asset_id) AS asset_count
FROM Employee e
INNER JOIN Assignment ass ON e.employee_id = ass.employee_id
INNER JOIN Asset a ON ass.asset_id = a.asset_id
WHERE e.employee_id IN (
    SELECT employee_id
    FROM Assignment ass1
    INNER JOIN Asset a1 ON ass1.asset_id = a1.asset_id
    WHERE a1.type = 'Laptop'
    INTERSECT
    SELECT employee_id
    FROM Assignment ass2
    INNER JOIN Asset a2 ON ass2.asset_id = a2.asset_id
    WHERE a2.type = 'Printer'
)
GROUP BY e.name, e.surname
ORDER BY asset_count DESC;



---- ТРИГГЕРЫ

/* Триггер для проверки вместимости департамента: 
предотвращает добавление сотрудника в департамент, если его вместимость уже 
превышена.*/

CREATE TRIGGER check_department_capacity
BEFORE INSERT ON Employee
FOR EACH ROW
WHEN (
    (SELECT COUNT(*) FROM Employee WHERE dept_id = NEW.dept_id) >=
    (SELECT capacity FROM Department WHERE dept_id = NEW.dept_id)
)
BEGIN
    SELECT RAISE(FAIL, 'Department capacity exceeded');
END;

-- Проверка

INSERT INTO Department (name, capacity, location_id) VALUES
('Аналитика', 2, 1);


INSERT INTO Employee (name, surname, email, dept_id, manager_id) VALUES
('Илья', 'Желтый', 'yellow@example.com', 6, NULL),
('Кирилл', 'Зеленый', 'green@example.com', 6, 1),
('Михайло', 'Оранжевый', 'orange@example.com', 6, 1); -- вылезет ошибка


/* Задача: Создать триггер для обновления состояния актива на 'Working' 
после записи об обслуживании.
После добавления записи в Maintenance триггер автоматически обновляет состояние актива на 'Working', 
если ранее оно было 'Repair'.
*/
CREATE TRIGGER update_asset_condition
AFTER INSERT ON Maintenance
FOR EACH ROW
BEGIN
    UPDATE Asset
    SET condition = 'Working'
    WHERE asset_id = (
        SELECT asset_id 
        FROM Assignment 
        WHERE assignment_id = NEW.assignment_id
    )
    AND condition = 'Repair';
END;

-- Проверка

INSERT INTO Asset (name, type, condition, cost, dept_id) 
VALUES ('HP EliteBook', 'Laptop', 'Repair', 50000, 1);
SELECT * FROM Asset;

INSERT INTO Assignment (employee_id, asset_id, from_date, to_date, type) VALUES
(1, 7, '2023-01-20', NULL, 'Permanent');
SELECT * FROM Assignment;

INSERT INTO Maintenance (assignment_id, date, capacity) VALUES
(7, '2023-06-10', 'Partial');
SELECT * FROM Maintenance;

SELECT * FROM Asset;

---- ОКОННЫЕ ФУНКЦИИ

/* Ранжирование департаментов по количеству оборудования с использованием оконной функции RANK()*/

SELECT 
    d.name AS department,
    COUNT(a.asset_id) AS asset_count,
    RANK() OVER (ORDER BY COUNT(a.asset_id) DESC) AS rank
FROM Department d
LEFT JOIN Asset a ON d.dept_id = a.dept_id
GROUP BY d.name
ORDER BY rank;

/* Для каждого департамента вывести список сотрудников с их порядковым номером (по алфавиту имени).*/

SELECT 
    e.name || ' ' || e.surname AS full_name,
    d.name AS department_name,
    ROW_NUMBER() OVER (PARTITION BY e.dept_id ORDER BY e.name, e.surname) AS rank_in_department
FROM Employee e
JOIN Department d ON e.dept_id = d.dept_id;

/* Для каждого актива посчитать, насколько его цена отличается от средней по департаменту.*/
SELECT 
    a.name AS asset_name,
    d.name AS department_name,
    a.cost,
    ROUND(AVG(a.cost) OVER (PARTITION BY a.dept_id), 2) AS avg_cost_in_dept,
    ROUND(a.cost - AVG(a.cost) OVER (PARTITION BY a.dept_id), 2) AS diff_from_avg
FROM Asset a
JOIN Department d ON a.dept_id = d.dept_id;
