-- Solve the below SQL problems using the Famous Paintings & Museum dataset:

--1) Fetch all the paintings which are not displayed on any museums?

---10,163 paintings were not displayed on any museums
SELECT w.name
FROM
[Famous_Painting].[dbo].[work] w
FULL JOIN [Famous_Painting].[dbo].[museum] m
ON w.museum_id = m.museum_id
WHERE m. museum_id IS NULL ;

---4,553 paintings were displayed on museums
SELECT w.name
FROM
[Famous_Painting].[dbo].[work] w
FULL JOIN [Famous_Painting].[dbo].[museum] m
ON w.museum_id = m.museum_id
WHERE m. museum_id IS NOT NULL ;


SELECT *
FROM [Famous_Painting].[dbo].[work]

--2) Are there museuems without any paintings?
--There are no museums without any paintings in other words every museum has a painting
SELECT m.name as museum_name, w.name as painting_name
FROM
[Famous_Painting].[dbo].[work] w
LEFT JOIN [Famous_Painting].[dbo].[museum] m
ON w.museum_id = m.museum_id
WHERE w.work_id IS NULL ;

--3) How many paintings have an asking price of more than their regular price? 
--There is no painting with an asking price more than regular price
SELECT w.name
FROM [Famous_Painting].[dbo].[work] w
LEFT JOIN [Famous_Painting].[dbo].[product_size] p
ON w.work_id = p.work_id
WHERE p.sale_price > p.regular_price;


--4) Identify the paintings whose asking price is less than 50% of its regular price
--There are 15 paintings whose asking price is less than 50% of its regular price
SELECT w.name
FROM [Famous_Painting].[dbo].[work] w
LEFT JOIN [Famous_Painting].[dbo].[product_size] p
ON w.work_id = p.work_id
WHERE p.sale_price < (0.5 * p.regular_price);


--5) Which canva size costs the most?
---FIRST APPROACH
SELECT  TOP 1 c.label, p.sale_price
FROM [Famous_Painting].[dbo].[canvas_size] c
JOIN [Famous_Painting].[dbo].[product_size] p
ON CAST(c.size_id AS nvarchar) = p.size_id
ORDER BY p.sale_price DESC ;

---SECOND APPROACH
WITH CTE AS (
  SELECT DISTINCT c.label, p.sale_price
  , RANK() OVER(ORDER BY p.sale_price DESC) AS rnk
  FROM [Famous_Painting].[dbo].[canvas_size] c
  JOIN [Famous_Painting].[dbo].[product_size] p
    ON CAST(c.size_id AS nvarchar) = p.size_id
)
SELECT label, sale_price
FROM CTE
WHERE rnk = 1

--6) Delete duplicate records from work, product_size, subject and image_link tables
---CHECKING AND DELETING DUPLICATES IN THE WORK TABLE (60 DUPLICATES WERE DELETED)
SELECT  work_id, COUNT(*)
FROM [Famous_Painting].[dbo].[work]
GROUP BY work_id
HAVING COUNT(*) > 1;

WITH dups AS (SELECT *, ROW_NUMBER()OVER(PARTITION BY work_id ORDER BY work_id) as rn
FROM [Famous_Painting].[dbo].[work] 
)
DELETE FROM dups WHERE rn > 1;


---CHECKING AND DELETING DUPLICATES IN THE PRODUCT TABLE (95,717 DUPLICATES WERE DELETED)

SELECT  work_id, COUNT(work_id)
FROM [Famous_Painting].[dbo].[product_size]
GROUP BY work_id
HAVING COUNT(work_id) > 1;

WITH dups_product AS (SELECT *, ROW_NUMBER()OVER(PARTITION BY work_id ORDER BY work_id) as rn
FROM [Famous_Painting].[dbo].[product_size] 
)
DELETE FROM dups_product WHERE rn > 1;

---CHECKING AND DELETING DUPLICATES IN THE SUBJECT TABLE (730 DUPLICATES WERE DELETED)
SELECT  work_id, COUNT(*)
FROM [Famous_Painting].[dbo].[subject]
GROUP BY work_id
HAVING COUNT(*) > 1;

WITH dups_subject AS (SELECT *, ROW_NUMBER()OVER(PARTITION BY work_id ORDER BY work_id) as rn
FROM [Famous_Painting].[dbo].[subject] 
)
DELETE FROM dups_subject WHERE rn > 1;


---CHECKING AND DELETING DUPLICATES IN THE IMAGE LINK TABLE (60 DUPLICATES WERE DELETED)
SELECT  work_id, COUNT(*)
FROM [Famous_Painting].[dbo].[image_link]
GROUP BY work_id
HAVING COUNT(*) = 1;

WITH dups_imagelink AS (SELECT *, ROW_NUMBER()OVER(PARTITION BY work_id ORDER BY work_id) as rn
FROM [Famous_Painting].[dbo].[image_link] 
)
DELETE FROM dups_imagelink WHERE rn > 1;



--7) Identify the museums with invalid city information in the given dataset
SELECT * FROM [Famous_Painting].[dbo].[museum]
WHERE city  LIKE '%[^a-zA-Z ]%' AND city NOT LIKE '%S';




--8) Fetch the top 10 most famous painting subject
SELECT TOP 10 subject, COUNT(work_id)
FROM [Famous_Painting].[dbo].[subject]
GROUP BY subject
ORDER by COUNT(work_id) DESC;


---9) Identify the museums which are open on both Sunday and Monday. Display museum name, city.
---FIRST APPROACH
SELECT name AS museum_name, city
FROM [Famous_Painting].[dbo].[museum_hours] h
JOIN [Famous_Painting].[dbo].[museum] m
  ON h.museum_id = m.museum_id
WHERE day = 'Sunday'
AND EXISTS (SELECT *
            FROM [Famous_Painting].[dbo].[museum_hours] h
            WHERE h.museum_id = m.museum_id
            AND h.day = 'Monday')
ORDER BY museum_name

----SECOND APPROACH
WITH Sunday_Monday as (SELECT h.museum_id, name, city
            FROM [Famous_Painting].[dbo].[museum_hours] h
             JOIN [Famous_Painting].[dbo].[museum] m
             ON h.museum_id = m.museum_id
             WHERE day IN ('Sunday', 'Monday') 
			 )
,
 both_days AS (SELECT *
               , COUNT('day') OVER(PARTITION BY museum_id) AS cnt
			  FROM Sunday_Monday)

SELECT DISTINCT name, city
FROM both_days
WHERE cnt = 2
ORDER BY name;



--10) Which are the top 5 most popular museum? (Popularity is defined based on most no of paintings in a museum)
---FIRST APPROACH
SELECT TOP 5 m.name AS Museum_name, m.country ,COUNT(m.name) AS Number_of_paintings
FROM [Famous_Painting].[dbo].[museum] m
JOIN [Famous_Painting].[dbo].[work] w
ON m.museum_id = w.museum_id
GROUP BY m.name, m.country
ORDER BY COUNT(m.name) DESC

---SECOND APPROACH
WITH CTE AS (
  SELECT m.name AS Museum_name, m.country AS Country, COUNT(m.name) AS Number_of_paintings, RANK() OVER(ORDER BY COUNT(m.name) DESC) AS rnk
FROM [Famous_Painting].[dbo].[museum] m
JOIN [Famous_Painting].[dbo].[work] w
ON m.museum_id = w.museum_id
GROUP BY m.name, m.country
)
SELECT Museum_name, Country, Number_of_paintings
FROM CTE
WHERE rnk <= 5

--11) Who are the top 5 most popular artist? (Popularity is defined based on most no of paintings done by an artist)
---FIRST APPROACH
SELECT TOP 5 a.full_name AS Artist_name, a.nationality, COUNT(w.name) AS Number_of_paintings
FROM [Famous_Painting].[dbo].[artist] a
JOIN [Famous_Painting].[dbo].[work] w
ON a.artist_id = w.artist_id
GROUP BY a.full_name, a.nationality
ORDER BY COUNT(w.name) DESC

---SECOND APPROACH
WITH CTE AS (
  SELECT a.full_name AS Artist_name, a.nationality AS Nationality, COUNT(w.name) AS Number_of_paintings, RANK() OVER(ORDER BY COUNT(w.name) DESC) AS rnk
FROM [Famous_Painting].[dbo].[artist] a
JOIN [Famous_Painting].[dbo].[work] w
ON a.artist_id = w.artist_id
GROUP BY a.full_name, a.nationality
)
SELECT Artist_name, Nationality, Number_of_paintings
FROM CTE
WHERE rnk <= 5


--12) Display the 3 least popular canva sizes
SELECT  c.size_id, c.label, COUNT(c.size_id) AS Number_of_Paintings
FROM [Famous_Painting].[dbo].[canvas_size] c
JOIN [Famous_Painting].[dbo].[product_size] p
ON CAST(c.size_id AS nvarchar) = p.size_id
GROUP BY c.label,c.size_id
HAVING COUNT(c.size_id) < 4
ORDER BY COUNT(c.size_id) ASC


--13) Which museum is open for the longest during a day. Dispay museum name, state and hours open and which day?
--FIRST APPROACH
SELECT TOP 1 m.name AS Museum_Name, m.state AS State, h.day AS Day, DATEDIFF(HOUR, h.[open], h.[close])AS time_opened_hr , DATEDIFF(MINUTE, h.[open], h.[close])AS time_opened_mins
FROM [Famous_Painting].[dbo].[museum] m
LEFT JOIN [Famous_Painting].[dbo].[museum_hours] h
ON m.museum_id = h.museum_id
ORDER BY DATEDIFF(MINUTE, h.[open], h.[close]) DESC

--SECOND APPROACH
WITH CTE AS (
  SELECT m.name AS Museum_Name, m.state AS State, h.day AS Day, DATEDIFF(HOUR, h.[open], h.[close]) AS time_opened_hr, DATEDIFF(MINUTE, h.[open], h.[close])AS time_opened_mins,
  RANK()OVER(ORDER BY DATEDIFF(MINUTE, h.[open], h.[close]) DESC) AS rnk
FROM [Famous_Painting].[dbo].[museum] m
LEFT JOIN [Famous_Painting].[dbo].[museum_hours] h
ON m.museum_id = h.museum_id
)
SELECT Museum_name, State, day, time_opened_hr, time_opened_mins
FROM CTE
WHERE rnk = 1

--14) Which museum has the most no of most popular painting style?
SELECT TOP 1 m.name AS Museum_Name, w.style AS Painting_style, COUNT(w.work_id) AS Number_of_paintings
FROM [Famous_Painting].[dbo].[work] w
JOIN  [Famous_Painting].[dbo].[museum] m
ON w.museum_id = m.museum_id
GROUP BY m.name, w.style
ORDER BY COUNT(w.style) DESC

--15) Identify the artists whose paintings are displayed in multiple countries

WITH CTE AS(
SELECT a.full_name AS Full_name, w.name, m.country AS country
FROM [Famous_Painting].[dbo].[museum] m
JOIN [Famous_Painting].[dbo].[work] w
ON m.museum_id = w.museum_id
JOIN [Famous_Painting].[dbo].[artist] a
ON w.artist_id = a.artist_id
)
SELECT Full_name, COUNT(DISTINCT country) AS number_of_countries
FROM CTE
GROUP BY Full_name
HAVING COUNT(DISTINCT country) >1
ORDER BY  COUNT(DISTINCT country)DESC


--16) Display the country and the city with most no of museums. Output 2 seperate columns to mention the city and country. 
--If there are multiple value, seperate them with comma.

WITH country AS (
 SELECT DISTINCT country
 , COUNT(museum_id) AS total_museum
 , RANK() OVER(ORDER BY COUNT(museum_id) DESC) AS rnk
 FROM [Famous_Painting].[dbo].[museum]
 GROUP BY country
)
, city AS (
 SELECT city
 , COUNT(museum_id) AS total_museum
 , RANK() OVER(ORDER BY COUNT(museum_id) DESC) AS rnk
 FROM [Famous_Painting].[dbo].[museum]
 GROUP BY city 
)
SELECT STRING_AGG( country,', ' ) AS country
, STRING_AGG(city, ', ' ) AS city
FROM country c
CROSS JOIN city ci
WHERE c.rnk = 1
 AND ci.rnk = 1



--17) Identify the artist and the museum where the most expensive and least expensive painting is placed. 
--Display the artist name, sale_price, painting name, museum name, museum city and canvas label

--FINDING THE MOST EXPENSIVE PAINTITNG
SELECT TOP 1 a.full_name AS Artist,  w.name AS Name_of_Painting, m.name AS Museum, m.city Museum_city, c.label AS Canvas_label, SUM(p.sale_price) AS Sale_price
FROM [Famous_Painting].[dbo].[artist] a
JOIN [Famous_Painting].[dbo].[work] w
ON a.artist_id = w.artist_id
JOIN [Famous_Painting].[dbo].[museum] m
ON w.museum_id = m.museum_id 
JOIN [Famous_Painting].[dbo].[product_size] p
ON p.work_id =w.work_id
JOIN [Famous_Painting].[dbo].[canvas_size] c
ON p.size_id =  CAST(c.size_id AS nvarchar)
GROUP BY a.full_name,  w.name , m.name , m.city , c.label 
ORDER BY SUM(p.sale_price) DESC

--FINDING THE LEAST EXPENSIVE PAINTITNG
SELECT TOP 1 a.full_name AS Artist,  w.name AS Name_of_Painting, m.name AS Museum, m.city Museum_city, c.label AS Canvas_label, SUM(p.sale_price) AS Sale_price
FROM [Famous_Painting].[dbo].[artist] a
JOIN [Famous_Painting].[dbo].[work] w
ON a.artist_id = w.artist_id
JOIN [Famous_Painting].[dbo].[museum] m
ON w.museum_id = m.museum_id 
JOIN [Famous_Painting].[dbo].[product_size] p
ON p.work_id =w.work_id
JOIN [Famous_Painting].[dbo].[canvas_size] c
ON p.size_id =  CAST(c.size_id AS nvarchar)
GROUP BY a.full_name,  w.name , m.name , m.city , c.label 
ORDER BY SUM(p.sale_price) 

--18) Which country has the 5th highest no of paintings?
WITH CTE AS (
SELECT m.country AS Country, COUNT(w.work_id) AS Number_of_paintings, RANK()OVER(ORDER BY COUNT(w.work_id) DESC) AS rnk
FROM [Famous_Painting].[dbo].[museum] m
JOIN [Famous_Painting].[dbo].[work] w
ON m.museum_id = w.museum_id
GROUP BY m.country
)
SELECT Country, Number_of_paintings
FROM CTE
WHERE rnk = 5



--19) Which are the 3 most popular and 3 least popular painting styles?
--FIRST APPROACH
SELECT TOP 3 w.style, COUNT(w.work_id) AS Number_of_paintings
FROM [Famous_Painting].[dbo].[work] w
JOIN [Famous_Painting].[dbo].[museum] m
ON w.museum_id= m.museum_id
GROUP BY w.style
HAVING style IS NOT NULL
ORDER BY COUNT(w.work_id) DESC

SELECT TOP 3 w.style, COUNT(w.work_id) AS Number_of_paintings
FROM [Famous_Painting].[dbo].[work] w
JOIN [Famous_Painting].[dbo].[museum] m
ON w.museum_id= m.museum_id
GROUP BY w.style
HAVING style IS NOT NULL
ORDER BY COUNT(w.work_id) ASC

--SECOND APPROACH
WITH CTE AS (
  SELECT style
  , COUNT(work_id) AS Number_of_paintings
  , RANK() OVER(ORDER BY COUNT(work_id) DESC) AS popular_rnk
  , RANK() OVER(ORDER BY COUNT(work_id)) AS least_rnk
  FROM [Famous_Painting].[dbo].[work] w
  WHERE style IS NOT NULL
  GROUP BY style
)
SELECT style, Number_of_paintings,
CASE WHEN popular_rnk <= 3 THEN 'most_popular'
     WHEN least_rnk <= 3 THEN 'least_popular'
END AS remark  
FROM CTE
WHERE popular_rnk <= 3 
   OR least_rnk <= 3
ORDER BY popular_rnk


--20) Which artist has the most no of Portraits paintings outside USA?. Display artist name, no of paintings and the artist nationality.
WITH CTE AS(
SELECT a.full_name AS Artist, a.nationality AS Nationality, m.country, s.subject, COUNT(w.work_id) AS Number_of_paintings, RANK()OVER(ORDER BY COUNT(w.work_id) DESC) AS rnk
FROM [Famous_Painting].[dbo].[work] w
JOIN [Famous_Painting].[dbo].[subject] s
ON w.work_id = s.work_id
JOIN [Famous_Painting].[dbo].[artist] a
ON a.artist_id =w.artist_id
JOIN [Famous_Painting].[dbo].[museum] m
ON w.museum_id = m.museum_id
GROUP BY  a.full_name , a.nationality, m.country, s.subject
HAVING m.country!='USA' AND s.subject = 'Portraits'

)
SELECT Artist, Number_of_paintings, Nationality
FROM CTE
WHERE rnk = 1;

