-- СОЗДАНИЕ ТАБЛИЦ
-- 1. Таблица Location
CREATE TABLE Location (
    location_id INTEGER PRIMARY KEY AUTOINCREMENT,
    city TEXT NOT NULL,
    address TEXT NOT NULL,
	UNIQUE(city, address)
);

-- 2. Таблица Department
CREATE TABLE Department (
    dept_id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
 	capacity INTEGER NOT NULL CHECK (capacity>0), -- макс. кол-во людей в департаменте
    location_id INTEGER NOT NULL,
    FOREIGN KEY (location_id) REFERENCES Location(location_id)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- 3. Таблица Employee с рекурсивной связью (руководитель - подчинённый)
CREATE TABLE Employee (
    employee_id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    surname TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    dept_id INTEGER NOT NULL,
    manager_id INTEGER,
    FOREIGN KEY (dept_id) REFERENCES Department(dept_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (manager_id) REFERENCES Employee(employee_id)
);

-- 4. Таблица Asset
CREATE TABLE Asset (
    asset_id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    type TEXT NOT NULL CHECK(type IN ('Laptop', 'Monitor', 'Software', 'Server', 'Peripheral')),
    condition TEXT NOT NULL CHECK(condition IN ('New', 'Working', 'Repair', 'Retired')),
	cost REAL NOT NULL CHECK(cost>=0),
    dept_id INTEGER NOT NULL,
    FOREIGN KEY (dept_id) REFERENCES Department(dept_id)
);

-- 5. Таблица Vendor
CREATE TABLE Vendor (
    vendor_id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
    email TEXT NOT NULL UNIQUE,
    licence TEXT NOT NULL
);

-- 6. Таблица связи Asset–Vendor (M:N)
CREATE TABLE Asset_Vendor (
    asset_id INTEGER NOT NULL,
    vendor_id INTEGER NOT NULL,
    PRIMARY KEY (asset_id, vendor_id),
    FOREIGN KEY (asset_id) REFERENCES Asset(asset_id) ON DELETE CASCADE,
    FOREIGN KEY (vendor_id) REFERENCES Vendor(vendor_id) ON DELETE CASCADE
);

-- 7. Таблица Assignment (тернарная связь Employee–Asset–Дата назначения)
CREATE TABLE Assignment (
    assignment_id INTEGER PRIMARY KEY AUTOINCREMENT,
    employee_id INTEGER NOT NULL,
    asset_id INTEGER NOT NULL,
    from_date DATE NOT NULL,
    to_date DATE,
    type TEXT CHECK(type IN ('Permanent', 'Temporary')),
    FOREIGN KEY (employee_id) REFERENCES Employee(employee_id) ON DELETE CASCADE,
    FOREIGN KEY (asset_id) REFERENCES Asset(asset_id) ON DELETE CASCADE
);

-- 8. Таблица Maintenance (слабая сущность, зависит от Assignment и Asset)
CREATE TABLE Maintenance (
    maintenance_id INTEGER PRIMARY KEY AUTOINCREMENT,
    assignment_id INTEGER NOT NULL,
    date DATE NOT NULL,
    capacity TEXT CHECK(capacity IN ('Full', 'Partial')), -- отражает объём или степень проведённого технического обслуживания
    FOREIGN KEY (assignment_id) REFERENCES Assignment(assignment_id) ON DELETE CASCADE
);

-- ДОБАВЛЕНИЕ ДАННЫХ

-- 1. Заполнение таблицы Location
INSERT INTO Location (city, address) VALUES
('Москва', 'ул. Тверская, д. 12'),
('Санкт-Петербург', 'пр. Лиговский, д. 45'),
('Краснодар', 'ул. Ставропольская, д. 78'),
('Екатеринбург', 'ул. Малышева, д. 19'),
('Казань', 'ул. Кремлевская, д. 3');

-- 2. Заполнение таблицы Department
INSERT INTO Department (name, capacity, location_id) VALUES
('Разработка', 60, 1),
('Кадры', 25, 2),
('Бухгалтерия', 15, 3),
('Маркетинг', 35, 4),
('Продажи', 50, 5);

-- 3. Заполнение таблицы Employee
INSERT INTO Employee (name, surname, email, dept_id, manager_id) VALUES
('Алексей', 'Соколов', 'sokolov@example.com', 1, NULL),
('Елена', 'Морозова', 'morozova@example.com', 2, 1),
('Дмитрий', 'Ковалев', 'kovalev@example.com', 3, 1),
('Ольга', 'Петрова', 'petrova@example.com', 4, 2),
('Игорь', 'Васильев', 'vasiliev@example.com', 5, 2),
('Татьяна', 'Иванова', 'ivanova@example.com', 1, 1);

-- 4. Заполнение таблицы Asset
INSERT INTO Asset (name, type, condition, cost, dept_id) VALUES
('Ноутбук ASUS', 'Laptop', 'New', 40000, 1),
('Монитор Samsung', 'Monitor', 'Working', 50000, 2),
('Windows 11', 'Software', 'Working', 14000, 3),
('Сервер IBM', 'Server', 'Repair', 40000, 4),
('Принтер Canon', 'Peripheral', 'Retired', 20000,5),
('MacBook Pro', 'Laptop', 'New', 120000, 1);

-- 5. Заполнение таблицы Vendor
INSERT INTO Vendor (name, email, licence) VALUES
('ASUS', 'asus@vendor.com', 'VEN001'),
('Samsung', 'samsung@vendor.com', 'VEN002'),
('Microsoft', 'ms@vendor.com', 'VEN003'),
('IBM', 'ibm@vendor.com', 'VEN004'),
('Canon', 'canon@vendor.com', 'VEN005');

-- 6. Заполнение таблицы Asset_Vendor
INSERT INTO Asset_Vendor (asset_id, vendor_id) VALUES
(1, 1),
(2, 2),
(3, 3),
(4, 4),
(5, 5),
(6, 1);

-- 7. Заполнение таблицы Assignment
INSERT INTO Assignment (employee_id, asset_id, from_date, to_date, type) VALUES
(1, 1, '2023-01-15', NULL, 'Permanent'),
(2, 2, '2023-03-10', '2023-12-01', 'Temporary'),
(3, 3, '2023-05-20', NULL, 'Permanent'),
(4, 4, '2023-07-01', '2023-11-30', 'Temporary'),
(5, 5, '2023-09-15', NULL, 'Permanent'),
(6, 6, '2023-02-01', NULL, 'Permanent');

-- 8. Заполнение таблицы Maintenance
INSERT INTO Maintenance (assignment_id, date, capacity) VALUES
(1, '2023-06-10', 'Full'),
(2, '2023-07-15', 'Partial'),
(3, '2023-08-20', 'Full'),
(4, '2023-09-25', 'Partial'),
(5, '2023-10-30', 'Full');
