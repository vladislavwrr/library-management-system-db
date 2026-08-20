-- 1. Таблица для логирования
CREATE TABLE IF NOT EXISTS trigger_logs (
    log_id SERIAL PRIMARY KEY,
    event_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    trigger_name VARCHAR(100),
    table_name VARCHAR(100),
    operation VARCHAR(10),
    details JSONB
);

-- 2. Функции триггеров

-- Триггер 1: Обновление статуса книги + логирование
CREATE OR REPLACE FUNCTION update_book_status()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE Book_Status_Journal
        SET Status_Name = 'Выдана'
        WHERE Status_ID = (
            SELECT Status_ID FROM Book_Copy 
            WHERE Inventory_Number = NEW.Inventory_Number
        );
        
        INSERT INTO trigger_logs (trigger_name, table_name, operation, details)
        VALUES (TG_NAME, TG_TABLE_NAME, TG_OP, 
                jsonb_build_object('action', 'status_update', 'new_status', 'Выдана'));
                
    ELSIF TG_OP = 'UPDATE' AND OLD.Due_Date < CURRENT_DATE THEN
        UPDATE Book_Status_Journal
        SET Status_Name = 'Доступна'
        WHERE Status_ID = (
            SELECT Status_ID FROM Book_Copy 
            WHERE Inventory_Number = NEW.Inventory_Number
        );
        
        INSERT INTO trigger_logs (trigger_name, table_name, operation, details)
        VALUES (TG_NAME, TG_TABLE_NAME, TG_OP, 
                jsonb_build_object('action', 'status_update', 'new_status', 'Доступна'));
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Триггер 2: Проставление даты списания + логирование
CREATE OR REPLACE FUNCTION set_disposal_date()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.Status_Name = 'Непригодна' AND OLD.Status_Name != 'Непригодна' THEN
        NEW.Disposal_Date = CURRENT_DATE;
        INSERT INTO trigger_logs (trigger_name, table_name, operation, details)
        VALUES (TG_NAME, TG_TABLE_NAME, TG_OP, 
                jsonb_build_object('action', 'disposal', 'date', NEW.Disposal_Date));
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Триггер 3: Проверка доступности + логирование
CREATE OR REPLACE FUNCTION check_book_availability()
RETURNS TRIGGER AS $$
DECLARE
    current_status VARCHAR(50);
BEGIN
    SELECT Status_Name INTO current_status
    FROM Book_Status_Journal
    WHERE Status_ID = (
        SELECT Status_ID FROM Book_Copy 
        WHERE Inventory_Number = NEW.Inventory_Number
    );
    
    IF current_status != 'Доступна' THEN
        INSERT INTO trigger_logs (trigger_name, table_name, operation, details)
        VALUES (TG_NAME, TG_TABLE_NAME, TG_OP, 
                jsonb_build_object('error', 'Книга недоступна', 'inventory_number', NEW.Inventory_Number));
        RAISE EXCEPTION 'Книга % недоступна для выдачи', NEW.Inventory_Number;
    ELSE
        INSERT INTO trigger_logs (trigger_name, table_name, operation, details)
        VALUES (TG_NAME, TG_TABLE_NAME, TG_OP, 
                jsonb_build_object('action', 'availability_check', 'status', 'Доступна'));
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Триггер 4: Расчет Due_Date + логирование
CREATE OR REPLACE FUNCTION calculate_due_date()
RETURNS TRIGGER AS $$
DECLARE
    period INT;
BEGIN
    SELECT Loan_Period INTO period
    FROM Issue_Rule
    WHERE Hall_ID = (
        SELECT Hall_ID FROM Employee 
        WHERE Employee_ID = NEW.Employee_ID
    );
    
    NEW.Due_Date := NEW.Issue_Date + (period || ' days')::INTERVAL;
    
    INSERT INTO trigger_logs (trigger_name, table_name, operation, details)
    VALUES (TG_NAME, TG_TABLE_NAME, TG_OP, 
            jsonb_build_object('action', 'due_date_calculation', 'loan_period', period, 'result_date', NEW.Due_Date));
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Триггер 5: Генерация инв. номера + логирование
CREATE OR REPLACE FUNCTION generate_inventory_number()
RETURNS TRIGGER AS $$
DECLARE
    lib_code VARCHAR(10);
    hall_code VARCHAR(10);
BEGIN
    SELECT 
        LPAD(Library_ID::TEXT, 3, '0'),
        LPAD(Hall_ID::TEXT, 3, '0') 
    INTO lib_code, hall_code
    FROM Hall
    WHERE Hall_ID = (
        SELECT Hall_ID FROM Storage_Location 
        WHERE Storage_Location_ID = NEW.Storage_Location_ID
    );
    
    NEW.Inventory_Number := 'LIB-' || lib_code || '-' || hall_code || '-' || LPAD(NEW.Book_ID::TEXT, 5, '0');
    
    INSERT INTO trigger_logs (trigger_name, table_name, operation, details)
    VALUES (TG_NAME, TG_TABLE_NAME, TG_OP, 
            jsonb_build_object('action', 'inventory_generation', 'new_number', NEW.Inventory_Number));
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. Создание триггеров
-- Для Book_Status_Journal
CREATE TRIGGER status_disposal_date
BEFORE UPDATE ON Book_Status_Journal
FOR EACH ROW EXECUTE FUNCTION set_disposal_date();

-- Для Loan_Request
CREATE TRIGGER loan_request_status_update
AFTER INSERT OR UPDATE ON Loan_Request
FOR EACH ROW EXECUTE FUNCTION update_book_status();

CREATE TRIGGER loan_request_availability_check
BEFORE INSERT ON Loan_Request
FOR EACH ROW EXECUTE FUNCTION check_book_availability();

CREATE TRIGGER loan_request_due_date_calculation
BEFORE INSERT ON Loan_Request
FOR EACH ROW EXECUTE FUNCTION calculate_due_date();

-- Для Book_Copy
CREATE TRIGGER book_copy_inventory_number
BEFORE INSERT ON Book_Copy
FOR EACH ROW EXECUTE FUNCTION generate_inventory_number();

-- 4. Тестовые данные
-- Удаляем старые тестовые данные (если есть)
DELETE FROM Loan_Request WHERE Reader_ID IN (SELECT Reader_ID FROM Reader WHERE Last_Name = 'TestReader');
DELETE FROM Reader WHERE Last_Name = 'TestReader';
DELETE FROM Employee WHERE Last_Name = 'TestEmployee';
DELETE FROM Book_Copy WHERE Book_ID IN (SELECT Book_ID FROM Book WHERE Title = 'Test Book');
DELETE FROM Book_Status_Journal WHERE Status_Name = 'Доступна' AND Acquisition_Date = CURRENT_DATE;
DELETE FROM Book_Author WHERE Book_ID IN (SELECT Book_ID FROM Book WHERE Title = 'Test Book');
DELETE FROM Author WHERE Last_Name = 'TestAuthor';
DELETE FROM Book WHERE Title = 'Test Book';
DELETE FROM Storage_Location WHERE Hall_ID IN (SELECT Hall_ID FROM Hall WHERE Hall_Type = 'Test Hall');
DELETE FROM Issue_Rule WHERE Hall_ID IN (SELECT Hall_ID FROM Hall WHERE Hall_Type = 'Test Hall');
DELETE FROM Hall WHERE Hall_Type = 'Test Hall';
DELETE FROM Library WHERE Library_Name = 'Test Library';

-- Создаем новые тестовые данные
INSERT INTO Library (Library_Name, Address) 
VALUES ('Test Library', 'Test Address') RETURNING Library_ID;

INSERT INTO Hall (Library_ID, Hall_Type) 
VALUES (currval('library_library_id_seq'), 'Test Hall') RETURNING Hall_ID;

INSERT INTO Issue_Rule (Hall_ID, Description, Loan_Period) 
VALUES (currval('hall_hall_id_seq'), 'Test Rules', 14);

INSERT INTO Book_Category (Book_Name) 
VALUES ('Test Category') RETURNING Book_Category_ID;

INSERT INTO Book (Book_Category_ID, Title, Year, ISBN) 
VALUES (currval('book_category_book_category_id_seq'), 'Test Book', 2023, 'TEST-ISBN') RETURNING Book_ID;

INSERT INTO Author (Last_Name, First_Name, Birth_Year) 
VALUES ('TestAuthor', 'Test', 1900) RETURNING Author_ID;

INSERT INTO Book_Author (Book_ID, Author_ID) 
VALUES (currval('book_book_id_seq'), currval('author_author_id_seq'));

INSERT INTO Book_Status_Journal (Status_Name, Acquisition_Date) 
VALUES ('Доступна', CURRENT_DATE) RETURNING Status_ID;

INSERT INTO Storage_Location (Hall_ID, Room_Number, Rack_Number, Shelf_Number) 
VALUES (currval('hall_hall_id_seq'), 1, 1, 1) RETURNING Storage_Location_ID;

INSERT INTO Book_Copy (Book_ID, Status_ID, Storage_Location_ID) 
VALUES (currval('book_book_id_seq'), currval('book_status_journal_status_id_seq'), currval('storage_location_storage_location_id_seq'));

INSERT INTO Employee (Hall_ID, First_Name, Last_Name) 
VALUES (currval('hall_hall_id_seq'), 'Test', 'Employee') RETURNING Employee_ID;

INSERT INTO Reader (Reader_Category_ID, Library_ID, First_Name, Last_Name, Registration_Date) 
VALUES (
    (SELECT Reader_Category_ID FROM Reader_Category LIMIT 1),
    currval('library_library_id_seq'),
    'Test',
    'Reader',
    CURRENT_DATE
) RETURNING Reader_ID;

-- 5. Проверка всех триггеров
-- Триггер 5 (сработает здесь)
INSERT INTO Loan_Request (Reader_ID, Inventory_Number, Employee_ID, Issue_Date)
VALUES (
    currval('reader_reader_id_seq'),
    (SELECT Inventory_Number FROM Book_Copy WHERE Book_ID = currval('book_book_id_seq')),
    currval('employee_employee_id_seq'),
    CURRENT_DATE
);

-- Триггер 2 (сработает здесь)
UPDATE Book_Status_Journal
SET Status_Name = 'Непригодна'
WHERE Status_ID = (
    SELECT Status_ID FROM Book_Copy 
    WHERE Book_ID = currval('book_book_id_seq')
);

-- 6. Просмотр логов
SELECT * FROM trigger_logs ORDER BY event_time DESC;

-- 7. Очистка
DELETE FROM Loan_Request WHERE Reader_ID = currval('reader_reader_id_seq');
DELETE FROM Book_Copy WHERE Book_ID = currval('book_book_id_seq');
DELETE FROM Book_Status_Journal WHERE Status_ID = currval('book_status_journal_status_id_seq');
DELETE FROM Storage_Location WHERE Storage_Location_ID = currval('storage_location_storage_location_id_seq');
DELETE FROM Book_Author WHERE Book_ID = currval('book_book_id_seq');
DELETE FROM Author WHERE Author_ID = currval('author_author_id_seq');
DELETE FROM Book WHERE Book_ID = currval('book_book_id_seq');
DELETE FROM Book_Category WHERE Book_Category_ID = currval('book_category_book_category_id_seq');
DELETE FROM Issue_Rule WHERE Hall_ID = currval('hall_hall_id_seq');
DELETE FROM Employee WHERE Employee_ID = currval('employee_employee_id_seq');
DELETE FROM Reader WHERE Reader_ID = currval('reader_reader_id_seq');
DELETE FROM Hall WHERE Hall_ID = currval('hall_hall_id_seq');
DELETE FROM Library WHERE Library_ID = currval('library_library_id_seq');