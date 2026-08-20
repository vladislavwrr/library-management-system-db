-- Библиотека
CREATE TABLE Library (
	Library_ID SERIAL PRIMARY KEY, 
	Library_Name VARCHAR(100) NOT NULL,
	Address TEXT DEFAULT 'Не указан'
);

COMMENT ON TABLE Library IS 'Основная таблица библиотек в системе';
COMMENT ON COLUMN Library.Library_ID IS 'Уникальный идентификатор библиотеки (автоинкрементный)';
COMMENT ON COLUMN Library.Library_Name IS 'Название библиотеки (обязательное поле, макс. 100 символов)';
COMMENT ON COLUMN Library.Address IS 'Физический адрес библиотеки (необязательное поле)';

-- Зал
CREATE TABLE Hall (
	Hall_ID SERIAL PRIMARY KEY,
	Library_ID INTEGER NOT NULL, --FK
	Hall_Type VARCHAR(50) NOT NULL DEFAULT 'Читальный',
	CONSTRAINT FK_Library_ID
		FOREIGN KEY (Library_ID)
		REFERENCES Library(Library_ID)
		ON DELETE CASCADE
);

COMMENT ON TABLE Hall IS 'Таблица залов библиотеки';
COMMENT ON COLUMN Hall.Hall_ID IS 'Уникальный идентификатор зала (автоинкрементный)';
COMMENT ON COLUMN Hall.Library_ID IS 'Идентификатор библиотеки, к которой относится зал (внешний ключ)';
COMMENT ON COLUMN Hall.Hall_Type IS 'Тип зала (читальный, абонементный, обязательное поле)';
COMMENT ON CONSTRAINT FK_Library_ID ON Hall IS 'Связь с таблицей Library. Каскадное удаление при удалении библиотеки';

-- Правила выдачи
CREATE TABLE Issue_Rule (
	Rule_ID SERIAL PRIMARY KEY,
	Hall_ID INTEGER, --FK
	Description TEXT DEFAULT 'Стандартные правила выдачи', 
	Loan_Period INTEGER DEFAULT 14,
	CONSTRAINT FK_Hall_ID
		FOREIGN KEY (Hall_ID)
		REFERENCES Hall(Hall_ID)
		ON DELETE CASCADE
);

COMMENT ON TABLE Issue_Rule IS 'Таблица правил выдачи материалов в библиотеке';
COMMENT ON COLUMN Issue_Rule.Rule_ID IS 'Уникальный идентификатор правила (автоинкрементный)';
COMMENT ON COLUMN Issue_Rule.Hall_ID IS 'Идентификатор зала, для которого действует правило (внешний ключ, может быть NULL для общих правил)';
COMMENT ON COLUMN Issue_Rule.Description IS 'Описание правила выдачи материалов';
COMMENT ON COLUMN Issue_Rule.Loan_Period IS 'Срок выдачи материалов в днях';
COMMENT ON CONSTRAINT FK_Hall_ID ON Issue_Rule IS 'Связь с таблицей Hall. Каскадное удаление при удалении зала';

-- Место хранения
CREATE TABLE Storage_Location (
	Storage_Location_ID SERIAL PRIMARY KEY,
	Hall_ID INTEGER NOT NULL, --FK 
	Room_Number INTEGER NOT NULL DEFAULT 1,
	Shelf_Number INTEGER NOT NULL DEFAULT 1,
	Rack_Number INTEGER NOT NULL DEFAULT 1,
	CONSTRAINT FK_Hall_ID
		FOREIGN KEY (Hall_ID)
		REFERENCES Hall(Hall_ID)
		ON DELETE CASCADE
);

COMMENT ON TABLE Storage_Location IS 'Физические места хранения библиотечных материалов (стеллажи и полки)';
COMMENT ON COLUMN Storage_Location.Storage_Location_ID IS 'Уникальный идентификатор места хранения';
COMMENT ON COLUMN Storage_Location.Hall_ID IS 'Идентификатор зала, в котором расположен стеллаж';
COMMENT ON COLUMN Storage_Location.Shelf_Number IS 'Номер полки на стеллаже (начиная с 1)';
COMMENT ON COLUMN Storage_Location.Rack_Number IS 'Номер стеллажа в зале (начиная с 1)';
COMMENT ON CONSTRAINT FK_Hall_ID ON Storage_Location IS 'Связь с таблицей Hall. Каскадное удаление при удалении зала';

--  Работники
CREATE TABLE Employee (
	Employee_ID SERIAL PRIMARY KEY,
	Hall_ID INTEGER NOT NULL, --FK
	First_Name VARCHAR(30) NOT NULL,
	Middle_Name VARCHAR(30) DEFAULT '',
	Last_Name VARCHAR(40) NOT NULL,
	CONSTRAINT FK_Hall_ID
		FOREIGN KEY (Hall_ID)
		REFERENCES Hall(Hall_ID)
		ON DELETE CASCADE
);

COMMENT ON TABLE Employee IS 'Таблица сотрудников библиотеки';
COMMENT ON COLUMN Employee.Employee_ID IS 'Уникальный идентификатор сотрудника (автоинкрементный)';
COMMENT ON COLUMN Employee.Hall_ID IS 'Идентификатор зала, за которым закреплен сотрудник (внешний ключ)';
COMMENT ON COLUMN Employee.First_Name IS 'Имя сотрудника (обязательное поле, макс. 30 символов)';
COMMENT ON COLUMN Employee.Middle_Name IS 'Отчество сотрудника (необящательное поле, макс. 30 символов)';
COMMENT ON COLUMN Employee.Last_Name IS 'Фамилия сотрудника (обязательное поле, макс. 40 символов)';
COMMENT ON CONSTRAINT FK_Hall_ID ON Employee IS 'Связь с таблицей Hall. Каскадное удаление при удалении зала';

-- Категория читателя
CREATE TABLE Reader_Category (
	Reader_Category_ID SERIAL PRIMARY KEY,
	Reader_Category_Name VARCHAR(50) NOT NULL
);

COMMENT ON TABLE Reader_Category IS 'Категории читателей библиотеки (студенты, преподаватели и др.)';
COMMENT ON COLUMN Reader_Category.Reader_Category_ID IS 'Уникальный идентификатор категории читателя (автоинкрементный)';
COMMENT ON COLUMN Reader_Category.Reader_Category_Name IS 'Наименование категории читателей (обязательное поле, макс. 50 символов)';

-- Читатель
CREATE TABLE Reader (
	Reader_ID SERIAL PRIMARY KEY,
	Reader_Category_ID INTEGER NOT NULL, --FK
	Library_ID INTEGER NOT NULL, --FK
	First_Name VARCHAR(30) NOT NULL,
	Middle_Name VARCHAR(30) DEFAULT '',
	Last_Name VARCHAR(40) NOT NULL,
	Address TEXT DEFAULT 'Не указан',
	Phone VARCHAR(20) DEFAULT 'Не указан',
	Registration_Date DATE NOT NULL DEFAULT CURRENT_DATE,
	CONSTRAINT FK_Reader_Category_ID
		FOREIGN KEY (Reader_Category_ID)
		REFERENCES Reader_Category(Reader_Category_ID)
		ON DELETE CASCADE,
	CONSTRAINT FK_Library_ID
		FOREIGN KEY (Library_ID)
		REFERENCES Library(Library_ID)
		ON DELETE CASCADE
);

COMMENT ON TABLE Reader IS 'Таблица зарегистрированных читателей библиотеки';
COMMENT ON COLUMN Reader.Reader_ID IS 'Уникальный идентификатор читателя (автоинкрементный)';
COMMENT ON COLUMN Reader.Reader_Category_ID IS 'Идентификатор категории читателя (внешний ключ)';
COMMENT ON COLUMN Reader.Library_ID IS 'Идентификатор библиотеки, где зарегистрирован читатель (внешний ключ)';
COMMENT ON COLUMN Reader.First_Name IS 'Имя читателя (обязательное поле, макс. 30 символов)';
COMMENT ON COLUMN Reader.Middle_Name IS 'Отчество читателя (обязательное поле, макс. 30 символов)';
COMMENT ON COLUMN Reader.Last_Name IS 'Фамилия читателя (обязательное поле, макс. 40 символов)';
COMMENT ON COLUMN Reader.Address IS 'Адрес проживания читателя';
COMMENT ON COLUMN Reader.Phone IS 'Контактный телефон читателя (макс. 20 символов)';
COMMENT ON COLUMN Reader.Registration_Date IS 'Дата регистрации читателя в библиотеке (обязательное поле)';
COMMENT ON CONSTRAINT FK_Reader_Category_ID ON Reader IS 'Связь с таблицей категорий читателей';
COMMENT ON CONSTRAINT FK_Library_ID ON Reader IS 'Связь с таблицей библиотек';

-- Описание аттрибута категории читателя
CREATE TABLE Reader_Category_Attribute (
	Reader_Category_Attribute_ID SERIAL PRIMARY KEY,
	Reader_Category_Attribute_Name TEXT NOT NULL 
);

COMMENT ON TABLE Reader_Category_Attribute IS 'Дополнительные атрибуты и описания категорий читателей';
COMMENT ON COLUMN Reader_Category_Attribute.Reader_Category_Attribute_ID IS 'Уникальный идентификатор атрибута категории (автоинкрементный)';
COMMENT ON COLUMN Reader_Category_Attribute.Reader_Category_Attribute_Name IS 'Подробное описание категории читателей (обязательное поле)';

-- Дополнительная таблица (Reader - Reader_Category_Attribute) 
CREATE TABLE Reader_Attribute_Value (
	Value_ID SERIAL PRIMARY KEY,
	Value TEXT NOT NULL,
	Reader_ID INTEGER NOT NULL,--FK 
	Reader_Category_Attribute_ID INTEGER NOT NULL,--FK
	CONSTRAINT FK_Reader_ID
		FOREIGN KEY (Reader_ID)
		REFERENCES Reader(Reader_ID)
		ON DELETE CASCADE,
	CONSTRAINT FK_Reader_Category_Attribute_ID
		FOREIGN KEY (Reader_Category_Attribute_ID)
		REFERENCES Reader_Category_Attribute(Reader_Category_Attribute_ID)
		ON DELETE CASCADE
);

COMMENT ON TABLE Reader_Attribute_Value IS 'Таблица значений дополнительных атрибутов читателей';
COMMENT ON COLUMN Reader_Attribute_Value.Value_ID IS 'Уникальный идентификатор значения атрибута (автоинкрементный)';
COMMENT ON COLUMN Reader_Attribute_Value.Value IS 'Значение атрибута (обязательное поле)';
COMMENT ON COLUMN Reader_Attribute_Value.Reader_ID IS 'Идентификатор читателя (внешний ключ)';
COMMENT ON COLUMN Reader_Attribute_Value.Reader_Category_Attribute_ID IS 'Идентификатор атрибута категории (внешний ключ)';
COMMENT ON CONSTRAINT FK_Reader_ID ON Reader_Attribute_Value IS 'Связь с таблицей Reader. Каскадное удаление при удалении читателя';
COMMENT ON CONSTRAINT FK_Reader_Category_Attribute_ID ON Reader_Attribute_Value IS 'Связь с таблицей атрибутов категорий. Каскадное удаление при удалении атрибута';

-- Категория книги
CREATE TABLE Book_Category (
	Book_Category_ID SERIAL PRIMARY KEY,
	Book_Name VARCHAR(50) NOT NULL
);

COMMENT ON TABLE Book_Category IS 'Категории книг в библиотеке (художественная литература, научная и др.)';
COMMENT ON COLUMN Book_Category.Book_Category_ID IS 'Уникальный идентификатор категории книги (автоинкрементный)';
COMMENT ON COLUMN Book_Category.Book_Name IS 'Наименование категории книг (обязательное поле, макс. 50 символов)';

-- Книга
CREATE TABLE Book (
	Book_ID SERIAL PRIMARY KEY,
	Book_Category_ID INTEGER NOT NULL, --FK
	Title TEXT DEFAULT 'Не указан',
	Year INTEGER DEFAULT EXTRACT(YEAR FROM CURRENT_DATE),
	ISBN VARCHAR(20) DEFAULT 'Не указан',
	CONSTRAINT FK_Book_Category_ID
		FOREIGN KEY (Book_Category_ID)
		REFERENCES Book_Category(Book_Category_ID)
		ON DELETE CASCADE
);

COMMENT ON TABLE Book IS 'Таблица для хранения основной информации о книгах библиотеки';
COMMENT ON COLUMN Book.Book_ID IS 'Уникальный идентификатор книги (суррогатный ключ)';
COMMENT ON COLUMN Book.Book_Category_ID IS 'Идентификатор категории из таблицы Book_Category';
COMMENT ON COLUMN Book.Title IS 'Название книги с дефолтным значением "Не указан"';
COMMENT ON COLUMN Book.Year IS 'Год издания с дефолтом текущего года';
COMMENT ON COLUMN Book.ISBN IS 'Международный стандартный книжный номер в формате ISBN-10 или ISBN-13';

-- Жанр
CREATE TABLE Genre (
	Genre_ID SERIAL PRIMARY KEY,
	Genre_Name VARCHAR(50) NOT NULL
);

COMMENT ON TABLE Genre IS 'Таблица жанров литературных произведений';
COMMENT ON COLUMN Genre.Genre_ID IS 'Уникальный идентификатор жанра (автоинкрементный)';
COMMENT ON COLUMN Genre.Genre_Name IS 'Наименование жанра (обязательное поле, макс. 50 символов)';

-- Дополнительная таблица (Genre - Book)
CREATE TABLE Book_Genre (
	BookGenre_ID SERIAL PRIMARY KEY,
	Genre_ID INTEGER NOT NULL, --FK
	Book_ID INTEGER NOT NULL, --FK
	CONSTRAINT FK_Genre_ID 
		FOREIGN KEY (Genre_ID)
		REFERENCES Genre(Genre_ID)
		ON DELETE CASCADE,
	CONSTRAINT FK_Book_ID
		FOREIGN KEY (Book_ID)
		REFERENCES Book(Book_ID)
		ON DELETE CASCADE
);

COMMENT ON TABLE Book_Genre IS 'Таблица связи книг с жанрами (многие-ко-многим)';
COMMENT ON COLUMN Book_Genre.BookGenre_ID IS 'Уникальный идентификатор связи (автоинкрементный)';
COMMENT ON COLUMN Book_Genre.Genre_ID IS 'Идентификатор жанра (внешний ключ)';
COMMENT ON COLUMN Book_Genre.Book_ID IS 'Идентификатор книги (внешний ключ)';
COMMENT ON CONSTRAINT FK_Genre_ID ON Book_Genre IS 'Связь с таблицей жанров. Каскадное удаление при удалении жанра';
COMMENT ON CONSTRAINT FK_Book_ID ON Book_Genre IS 'Связь с таблицей книг. Каскадное удаление при удалении книги';

-- Описание аттрибута категории книги
CREATE TABLE Book_Attribute (
	Book_Attribution_ID SERIAL PRIMARY KEY,
	Book_Attribute_Name VARCHAR(100) NOT NULL
);

COMMENT ON TABLE Book_Attribute IS 'Дополнительные атрибуты и описания категорий книги';
COMMENT ON COLUMN Book_Attribute.Book_Attribution_ID IS 'Уникальный идентификатор атрибута книги (автоинкрементный)';
COMMENT ON COLUMN Book_Attribute.Book_Attribute_Name IS 'Наименование атрибута книги (обязательное поле, макс. 100 символов)';

-- Дополнительная таблица (Book - Book_Attribute)
CREATE TABLE Book_Attribute_Value (
	Value_ID SERIAL PRIMARY KEY,
	Value TEXT NOT NULL,
	Book_ID INTEGER NOT NULL, --FK
	Book_Attribution_ID INTEGER NOT NULL, --FK
	CONSTRAINT FK_Book_ID
		FOREIGN KEY (Book_ID)
		REFERENCES Book(Book_ID)
		ON DELETE CASCADE,
	CONSTRAINT FK_Book_Attribution_ID
		FOREIGN KEY (Book_Attribution_ID)
		REFERENCES Book_Attribute(Book_Attribution_ID)
		ON DELETE CASCADE
);

COMMENT ON TABLE Book_Attribute_Value IS 'Таблица значений дополнительных атрибутов книг';
COMMENT ON COLUMN Book_Attribute_Value.Value_ID IS 'Уникальный идентификатор значения атрибута (автоинкрементный)';
COMMENT ON COLUMN Book_Attribute_Value.Value IS 'Значение атрибута книги (обязательное поле)';
COMMENT ON COLUMN Book_Attribute_Value.Book_ID IS 'Идентификатор книги (внешний ключ)';
COMMENT ON COLUMN Book_Attribute_Value.Book_Attribution_ID IS 'Идентификатор атрибута книги (внешний ключ)';
COMMENT ON CONSTRAINT FK_Book_ID ON Book_Attribute_Value IS 'Связь с таблицей Book. Каскадное удаление при удалении книги';
COMMENT ON CONSTRAINT FK_Book_Attribution_ID ON Book_Attribute_Value IS 'Связь с таблицей атрибутов книг. Каскадное удаление при удалении атрибута';

-- Автор
CREATE TABLE Author (
	Author_ID SERIAL PRIMARY KEY,
	First_Name VARCHAR(30) NOT NULL,
	Middle_Name VARCHAR(30) DEFAULT '',
	Last_Name VARCHAR(40) NOT NULL,
	Birth_Year INTEGER DEFAULT NULL,
	Death_Year INTEGER DEFAULT NULL
);

COMMENT ON TABLE Author IS 'Таблица авторов литературных произведений';
COMMENT ON COLUMN Author.Author_ID IS 'Уникальный идентификатор автора (автоинкрементный)';
COMMENT ON COLUMN Author.First_Name IS 'Имя автора (обязательное поле, макс. 30 символов)';
COMMENT ON COLUMN Author.Middle_Name IS 'Отчество автора (макс. 30 символов)';
COMMENT ON COLUMN Author.Last_Name IS 'Фамилия автора (обязательное поле, макс. 40 символов)';
COMMENT ON COLUMN Author.Birth_Year IS 'Год рождения автора';
COMMENT ON COLUMN Author.Death_Year IS 'Год смерти автора (если применимо)';

-- Дополнительная таблица (Author - Book) 
CREATE TABLE Book_Author (
	Book_Author_ID SERIAL PRIMARY KEY,
	Book_ID INTEGER NOT NULL, --FK
	Author_ID INTEGER NOT NULL, --FK
	CONSTRAINT FK_Book_ID
		FOREIGN KEY (Book_ID)
		REFERENCES Book(Book_ID)
		ON DELETE CASCADE,
	CONSTRAINT FK_Author_ID
		FOREIGN KEY (Author_ID)
		REFERENCES Author(Author_ID)
		ON DELETE CASCADE
);

COMMENT ON TABLE Book_Author IS 'Таблица связи книг с авторами (отношение многие-ко-многим)';
COMMENT ON COLUMN Book_Author.Book_Author_ID IS 'Уникальный идентификатор связи (автоинкрементный)';
COMMENT ON COLUMN Book_Author.Book_ID IS 'Идентификатор книги (внешний ключ)';
COMMENT ON COLUMN Book_Author.Author_ID IS 'Идентификатор автора (внешний ключ)';
COMMENT ON CONSTRAINT FK_Book_ID ON Book_Author IS 'Связь с таблицей Book. Каскадное удаление при удалении книги';
COMMENT ON CONSTRAINT FK_Author_ID ON Book_Author IS 'Связь с таблицей Author. Каскадное удаление при удалении автора';

-- Статус книги
CREATE TABLE Book_Status_Journal (
	Status_ID SERIAL PRIMARY KEY,
	Status_Name VARCHAR(50) NOT NULL DEFAULT 'Доступна',
	Acquisition_Date DATE NOT NULL DEFAULT CURRENT_DATE,
	Disposal_Date DATE DEFAULT NULL
);

COMMENT ON TABLE Book_Status_Journal IS 'Таблица статусов книг (доступна, выдана, утеряна и др.)';
COMMENT ON COLUMN Book_Status_Journal.Status_ID IS 'Уникальный идентификатор статуса (автоинкрементный)';
COMMENT ON COLUMN Book_Status_Journal.Status_Name IS 'Наименование статуса книги (обязательное поле, макс. 50 символов)';
COMMENT ON COLUMN Book_Status_Journal.Acquisition_Date IS 'Дата приобретения книги (обязательное поле)';
COMMENT ON COLUMN Book_Status_Journal.Disposal_Date IS 'Дата списания книги (если применимо)';

-- Копия книги
CREATE TABLE Book_Copy (
	Inventory_Number VARCHAR(50) NOT NULL PRIMARY KEY,
	Book_ID INTEGER NOT NULL, --FK
	Status_ID INTEGER NOT NULL, --FK
	Storage_Location_ID INTEGER NOT NULL, --FK
	CONSTRAINT FK_Book_ID
		FOREIGN KEY (Book_ID)
		REFERENCES Book(Book_ID)
		ON DELETE CASCADE,
	CONSTRAINT FK_Status_ID
		FOREIGN KEY (Status_ID)
		REFERENCES Book_Status_Journal(Status_ID)
		ON DELETE CASCADE,
	CONSTRAINT FK_Storage_Location_ID
		FOREIGN KEY (Storage_Location_ID)
		REFERENCES Storage_Location(Storage_Location_ID)
		ON DELETE CASCADE
);

COMMENT ON TABLE Book_Copy IS 'Таблица экземпляров книг библиотечного фонда';
COMMENT ON COLUMN Book_Copy.Inventory_Number IS 'Инвентарный номер экземпляра (уникальный идентификатор)';
COMMENT ON COLUMN Book_Copy.Book_ID IS 'Идентификатор книги (внешний ключ)';
COMMENT ON COLUMN Book_Copy.Status_ID IS 'Идентификатор текущего статуса экземпляра (внешний ключ)';
COMMENT ON COLUMN Book_Copy.Storage_Location_ID IS 'Идентификатор места хранения книги (внешний ключ)';
COMMENT ON CONSTRAINT FK_Book_ID ON Book_Copy IS 'Связь с таблицей Book. Каскадное удаление при удалении книги';
COMMENT ON CONSTRAINT FK_Status_ID ON Book_Copy IS 'Связь с таблицей Status. Каскадное удаление при удалении статуса';
COMMENT ON CONSTRAINT FK_Storage_Location_ID ON Book_Copy IS 'Связь с таблицей Storage_Location';

-- Заявки
CREATE TABLE Loan_Request (
	Request_ID SERIAL PRIMARY KEY,
	Reader_ID INTEGER NOT NULL, --FK
	Inventory_Number VARCHAR(50) NOT NULL, --FK
	Employee_ID INTEGER NOT NULL, --FK
	Issue_Date DATE NOT NULL DEFAULT CURRENT_DATE,
	Due_Date DATE NOT NULL DEFAULT (CURRENT_DATE + INTERVAL '14 days'),
	CONSTRAINT FK_Reader_ID
		FOREIGN KEY (Reader_ID)
		REFERENCES Reader(Reader_ID)
		ON DELETE CASCADE,
	CONSTRAINT FK_Inventory_Number
		FOREIGN KEY (Inventory_Number)
		REFERENCES Book_Copy(Inventory_Number)
		ON DELETE CASCADE,
	CONSTRAINT FK_Employee_ID
		FOREIGN KEY (Employee_ID)
		REFERENCES Employee(Employee_ID)
		ON DELETE CASCADE
);

COMMENT ON TABLE Loan_Request IS 'Таблица запросов на выдачу книг читателям';
COMMENT ON COLUMN Loan_Request.Request_ID IS 'Уникальный идентификатор запроса (автоинкрементный)';
COMMENT ON COLUMN Loan_Request.Reader_ID IS 'Идентификатор читателя (внешний ключ)';
COMMENT ON COLUMN Loan_Request.Inventory_Number IS 'Инвентарный номер экземпляра книги (внешний ключ)';
COMMENT ON COLUMN Loan_Request.Employee_ID IS 'Идентификатор сотрудника, оформившего выдачу (внешний ключ)';
COMMENT ON COLUMN Loan_Request.Issue_Date IS 'Дата выдачи книги читателю (обязательное поле)';
COMMENT ON COLUMN Loan_Request.Due_Date IS 'Срок возврата книги (обязательное поле)';
COMMENT ON CONSTRAINT FK_Reader_ID ON Loan_Request IS 'Связь с таблицей Reader. Каскадное удаление при удалении читателя';
COMMENT ON CONSTRAINT FK_Inventory_Number ON Loan_Request IS 'Связь с таблицей Book_Copy. Каскадное удаление при удалении экземпляра';
COMMENT ON CONSTRAINT FK_Employee_ID ON Loan_Request IS 'Связь с таблицей Employee. Каскадное удаление при удалении сотрудника';