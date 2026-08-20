--1) Получите список читателей с заданными характеристиками: студентов указанного учебного заведения, факультета, научных работников по определенной тематике и т.д. 
SELECT 
	r.Last_Name AS "Фамилия",
	r.First_Name AS "Имя", 
	r.Middle_Name AS "Отчество"
FROM Reader r
JOIN Reader_Category rc ON r.Reader_Category_ID = rc.Reader_Category_ID
JOIN Reader_Attribute_Value rav ON r.Reader_ID = rav.Reader_ID
JOIN Reader_Category_Attribute rca ON rav.Reader_Category_Attribute_ID = rca.Reader_Category_Attribute_ID
WHERE rca.Reader_Category_Attribute_Name = 'Название учебного заведения' 
  AND rav.Value = 'МГУ';
  
--2) Выдайте перечень читателей, на руках у которых находится указанное произведение.
SELECT DISTINCT
	r.Last_Name AS "Фамилия",
	r.First_Name AS "Имя", 
	r.Middle_Name AS "Отчество",
FROM Reader r
JOIN Loan_Request lr ON r.Reader_ID = lr.Reader_ID
JOIN Book_Copy bc ON lr.Inventory_Number = bc.Inventory_Number
JOIN Book b ON bc.Book_ID = b.Book_ID
JOIN Book_Status_Journal bsj ON bc.Status_ID = bsj.Status_ID
WHERE b.Title = 'Тайный Космоса И Его Тайны'
  AND bsj.Status_Name = 'Выдана';

--3) Получите список читателей, на руках у которых находится указанное издание (книга, журнал и т.п.). 
SELECT DISTINCT 
    r.First_Name AS "Имя",
	r.Middle_Name AS "Отчество",
    r.Last_Name AS "Фамилия"
FROM 
    Reader r
    JOIN Loan_Request lr ON r.Reader_ID = lr.Reader_ID
    JOIN Book_Copy bc ON lr.Inventory_Number = bc.Inventory_Number
    JOIN Book b ON bc.Book_ID = b.Book_ID
    JOIN Book_Category bc_cat ON b.Book_Category_ID = bc_cat.Book_Category_ID
    JOIN Book_Status_Journal sj ON bc.Status_ID = sj.Status_ID
WHERE 
    bc_cat.Book_Name = 'Книга' -- Указать нужную категорию
    AND sj.Status_Name = 'Выдана';

--4) Получите перечень читателей, которые в течение указанного промежутка времени получали издание с некоторым произведением, и название этого издания. 
SELECT
    r.First_Name AS "Имя",
    r.Last_Name AS "Фамилия",
	r.Middle_Name AS "Отчество",
    b.Title AS "Название издания"
FROM 
    Reader r
    JOIN Loan_Request lr ON r.Reader_ID = lr.Reader_ID
    JOIN Book_Copy bcpy ON lr.Inventory_Number = bcpy.Inventory_Number
    JOIN Book b ON bcpy.Book_ID = b.Book_ID
    JOIN Book_Category bc ON b.Book_Category_ID = bc.Book_Category_ID
WHERE 
    bc.Book_Name = 'Книга'  -- Указать нужную категорию
    AND lr.Issue_Date BETWEEN '2021-01-01' AND '2024-12-31'  -- Указать период
ORDER BY 
    r.Last_Name, r.First_Name, lr.Issue_Date;

--5) Выдайте список изданий, которые в течение некоторого времени получал указанный читатель из фонда библиотеки, где он зарегистрирован. 
SELECT
    bc.Book_Name AS "Категория издания",
    b.Title AS "Название книги",
    lr.Issue_Date AS "Дата выдачи",
    lr.Due_Date AS "Срок возврата"
FROM
    Loan_Request lr
    JOIN Reader r ON lr.Reader_ID = r.Reader_ID
    JOIN Book_Copy bcpy ON lr.Inventory_Number = bcpy.Inventory_Number
    JOIN Book b ON bcpy.Book_ID = b.Book_ID
    JOIN Book_Category bc ON b.Book_Category_ID = bc.Book_Category_ID
    JOIN Storage_Location sl ON bcpy.Storage_Location_ID = sl.Storage_Location_ID
    JOIN Hall h ON sl.Hall_ID = h.Hall_ID
    JOIN Library lib ON h.Library_ID = lib.Library_ID
WHERE
    r.Reader_ID = 1 -- Указать ID читателя
    AND lib.Library_ID = r.Library_ID -- Только фонд его библиотеки
    AND lr.Issue_Date BETWEEN '2021-01-01' AND '2021-12-31' -- Указать период
ORDER BY
    lr.Issue_Date DESC;

--6) Получите перечень изданий, которыми в течение некоторого времени пользовался указанный читатель из фонда библиотеки, где он не зарегистрирован. 
SELECT 
    b.Title AS "Название книги",
    lr.Issue_Date AS "Дата выдачи",
    lr.Due_Date AS "Дата возврата",
    lib.Library_Name AS "Библиотека выдачи"
FROM 
    Loan_Request lr
    JOIN Reader r ON lr.Reader_ID = r.Reader_ID
    JOIN Book_Copy bc ON lr.Inventory_Number = bc.Inventory_Number
    JOIN Storage_Location sl ON bc.Storage_Location_ID = sl.Storage_Location_ID
    JOIN Hall h ON sl.Hall_ID = h.Hall_ID
    JOIN Library lib ON h.Library_ID = lib.Library_ID
    JOIN Library rlib ON r.Library_ID = rlib.Library_ID
    JOIN Book b ON bc.Book_ID = b.Book_ID
WHERE 
    r.Reader_ID = 715 -- Указать ID нужного читателя
    AND h.Library_ID <> r.Library_ID
	AND lr.Issue_Date BETWEEN '2021-01-01' AND '2023-01-01';

--7) Получите список литературы, которая в настоящий момент выдана с определенной полки некоторой библиотеки. 
SELECT 
    b.Title AS "Название книги",
    bc.Inventory_Number AS "Инвентарный номер"
FROM 
    Book_Copy bc
    JOIN Storage_Location sl ON bc.Storage_Location_ID = sl.Storage_Location_ID
    JOIN Hall h ON sl.Hall_ID = h.Hall_ID
    JOIN Library lib ON h.Library_ID = lib.Library_ID
    JOIN Book_Status_Journal bs ON bc.Status_ID = bs.Status_ID
    JOIN Loan_Request lr ON bc.Inventory_Number = lr.Inventory_Number
    JOIN Book b ON bc.Book_ID = b.Book_ID
WHERE 
    lib.Library_Name = 'Библиотека "Экономист"'
    AND sl.Room_Number = 2
    AND sl.Rack_Number = 2
    AND sl.Shelf_Number = 6
    AND bs.Status_Name = 'Выдана'
	AND lr.Due_Date > CURRENT_DATE;

--8) Выдайте список читателей, которые в течение обозначенного периода были обслужены указанным библиотекарем. 
SELECT
    r.Last_Name AS "Фамилия",
    r.First_Name AS "Имя",
    r.Middle_Name AS "Отчество",
    COUNT(lr.Request_ID) AS "Количество выдач"
FROM 
    Loan_Request lr
    JOIN Employee e ON lr.Employee_ID = e.Employee_ID
    JOIN Reader r ON lr.Reader_ID = r.Reader_ID
WHERE 
    e.Employee_ID = 36 -- ID библиотекаря
    AND lr.Issue_Date BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY 
    r.Reader_ID, r.Last_Name, r.First_Name, r.Middle_Name
ORDER BY 
    r.Last_Name, r.First_Name;

--9) Получите данные о выработке библиотекарей (число обслуженных читателей в указанный период времени). 
SELECT 
    e.Last_Name AS "Фамилия",
    e.First_Name AS "Имя",
    e.Middle_Name AS "Отчество",
    COUNT(DISTINCT lr.Reader_ID) AS "Количество обслуженных читателей"
FROM 
    Loan_Request lr
    JOIN Employee e ON lr.Employee_ID = e.Employee_ID
WHERE 
    lr.Issue_Date BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY 
    e.Employee_ID, e.Last_Name, e.First_Name, e.Middle_Name
ORDER BY 
    "Количество обслуженных читателей" DESC;

--10) Получите список читателей с просроченным сроком литературы. 
SELECT 
    r.Last_Name AS "Фамилия",
    r.First_Name AS "Имя",
    r.Middle_Name AS "Отчество",
    b.Title AS "Название книги",
    lr.Issue_Date AS "Дата выдачи",
    lr.Due_Date AS "Срок возврата",
    lib.Library_Name AS "Библиотека",
    (CURRENT_DATE - lr.Due_Date) AS "Дней просрочки"
FROM 
    Loan_Request lr
    JOIN Book_Copy bc ON lr.Inventory_Number = bc.Inventory_Number
    JOIN Book_Status_Journal bs ON bc.Status_ID = bs.Status_ID
    JOIN Reader r ON lr.Reader_ID = r.Reader_ID
    JOIN Library lib ON r.Library_ID = lib.Library_ID
    JOIN Book b ON bc.Book_ID = b.Book_ID
WHERE 
    bs.Status_Name = 'Выдана'
    AND lr.Due_Date < CURRENT_DATE
ORDER BY 
    "Дней просрочки" DESC,
    r.Last_Name,
    r.First_Name;

--11) Получите перечень указанной литературы, которая поступила (была списана) в течение некоторого периода. 
SELECT 
    b.Title AS "Название книги",
    bc.Inventory_Number AS "Инвентарный номер",
    bs.Disposal_Date AS "Дата списания",
    bs.Acquisition_Date AS "Дата поступления",
	lib.Library_Name AS "Библиотека"
FROM 
    Book_Status_Journal bs
    JOIN Book_Copy bc ON bs.Status_ID = bc.Status_ID
    JOIN Book b ON bc.Book_ID = b.Book_ID
    JOIN Storage_Location sl ON bc.Storage_Location_ID = sl.Storage_Location_ID
    JOIN Hall h ON sl.Hall_ID = h.Hall_ID
    JOIN Library lib ON h.Library_ID = lib.Library_ID
WHERE 
    bs.Disposal_Date BETWEEN '2023-01-01' AND '2023-12-31' -- Указать период
    AND bs.Status_Name = 'Непригодна' -- Указать нужный статус
ORDER BY 
    bs.Disposal_Date DESC,
    lib.Library_Name;

--12) Выдайте список библиотекарей, работающих в указанном читальном зале некоторой библиотеки. 
SELECT 
    e.Last_Name AS "Фамилия",
    e.First_Name AS "Имя",
    e.Middle_Name AS "Отчество"
FROM 
    Employee e
    JOIN Hall h ON e.Hall_ID = h.Hall_ID
    JOIN Library lib ON h.Library_ID = lib.Library_ID
WHERE 
    lib.Library_Name = 'Центральная городская библиотека'  -- Указать название библиотеки
    AND h.Hall_Type = 'Читальный'
ORDER BY 
    e.Last_Name, e.First_Name;

--13) Получите список читателей, не посещавших библиотеку в течение указанного времени. 
SELECT 
    r.Last_Name AS "Фамилия",
    r.First_Name AS "Имя",
    r.Middle_Name AS "Отчество",
FROM 
    Reader r
WHERE 
    r.Registration_Date <= '2023-12-31' -- Последняя дата периода
    AND NOT EXISTS (
        SELECT 1
        FROM Loan_Request lr
        WHERE 
            lr.Reader_ID = r.Reader_ID
            AND lr.Issue_Date BETWEEN '2023-01-01' AND '2023-12-31' -- Указать период
    )
ORDER BY 
    r.Last_Name, r.First_Name;

--14) Получите список инвентарных номеров и названий из библиотечного фонда, в которых содержится указанное произведение. 
SELECT 
    bc.Inventory_Number AS "Инвентарный номер"
FROM 
    Book_Copy bc
    JOIN Book b ON bc.Book_ID = b.Book_ID
    LEFT JOIN Book_Attribute_Value bav ON b.Book_ID = bav.Book_ID
    LEFT JOIN Book_Attribute ba ON bav.Book_Attribution_ID = ba.Book_Attribution_ID
WHERE 
    b.Title ILIKE 'Секреты Магии И Вечный Поиск' -- Указать название книги
GROUP BY 
    bc.Inventory_Number, b.Title
ORDER BY 
    b.Title;

--15) Выдать список инвентарных номеров и названий из библиотечного фонда, в которых содержатся произведения указанного автора. 
SELECT DISTINCT 
    bc.Inventory_Number AS "Инвентарный номер",
    b.Title AS "Название книги",
    a.Last_Name AS "Фамилия автора",
    a.First_Name AS "Имя автора",
	a.Middle_Name AS "Отчество автора"
FROM 
    Book_Copy bc
    INNER JOIN Book b ON bc.Book_ID = b.Book_ID
    INNER JOIN Book_Author ba ON b.Book_ID = ba.Book_ID
    INNER JOIN Author a ON ba.Author_ID = a.Author_ID
WHERE 
    CONCAT(a.Last_Name, ' ', a.First_Name, ' ', a.Middle_Name) ILIKE 'Михайлов Николай Михайлович'
    -- Или поиск по отдельным полям:
    -- a.Last_Name ILIKE 'Михайлов'
    -- AND a.First_Name ILIKE 'Николай'
    -- AND a.Middle_Name ILIKE 'Михайлович'
ORDER BY 
    b.Title, bc.Inventory_Number;

--16) Получите список самых популярных произведений. 
SELECT 
    b.Title AS "Название произведения",
    COUNT(lr.Request_ID) AS "Количество выдач",
    STRING_AGG(DISTINCT a.Last_Name || ' ' || a.First_Name, ', ') AS "Авторы"
FROM 
    Loan_Request lr
    JOIN Book_Copy bc ON lr.Inventory_Number = bc.Inventory_Number
    JOIN Book b ON bc.Book_ID = b.Book_ID
    LEFT JOIN Book_Author ba ON b.Book_ID = ba.Book_ID
    LEFT JOIN Author a ON ba.Author_ID = a.Author_ID
GROUP BY 
    b.Book_ID, b.Title
ORDER BY 
    "Количество выдач" DESC
LIMIT 10; -- Топ-10 самых популярных