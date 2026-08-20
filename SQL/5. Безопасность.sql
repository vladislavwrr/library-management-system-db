CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    login VARCHAR(50) UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    role VARCHAR(20) CHECK (role IN ('admin', 'worker')) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Администратор БД
CREATE ROLE lib_admin WITH LOGIN PASSWORD 'secure_admin_pass';
ALTER ROLE lib_admin SUPERUSER;

-- Работник
CREATE ROLE lib_worker WITH LOGIN PASSWORD 'worker_pass';
GRANT SELECT, INSERT, UPDATE ON 
    Book, Book_Copy, Loan_Request, Author, Book_Author 
TO lib_worker;

-- Заполнение таблицы
INSERT INTO users (login, password_hash, role)
VALUES
('admin', '$2y$10$oaFnejz2ehC7UhKoZGlzauzqcf9tReN2ToTY8dxgJHOSDUWQ5KaX2', 'admin'),
('worker', '$2y$10$wU4HLXFyJYLV9k/xkskyx.9lBOdtf5D1nfJXV1whRfSSu8.anVQSC', 'worker');
