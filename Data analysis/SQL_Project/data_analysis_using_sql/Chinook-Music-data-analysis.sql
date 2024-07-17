/* This open database is provided by https://github.com/lerocha/chinook-database */

/* Question 1: Which countries have the most Invoices?*/

SELECT BillingCountry, COUNT(*) INVOICE_CNT
FROM dbo.Invoice
GROUP BY BillingCountry
ORDER BY INVOICE_CNT DESC;

/* Question 2: Which city has the best customers? 
We would like to throw a promotional Music Festival in the city we made the most money. 
Write a query that returns the 1 city that has the highest sum of invoice totals. 
Return both the city name and the sum of all invoice totals.*/

SELECT TOP 1 BillingCity, COUNT(*) INVOICE_CNT
FROM dbo.Invoice
GROUP BY BillingCity
ORDER BY INVOICE_CNT DESC;

/*Question 3: Who is the best customer?
The customer who has spent the most money will be declared the best customer. 
Build a query that returns the person who has spent the most money. 
Invoice, InvoiceLine, and Customer tables to retrieve this information*/

SELECT TOP 1 A.CustomerId, A.FirstName, A.LastName, 
	COUNT(B.InvoiceId) INVOICE_CNT, 
	SUM(B.Total) TOTAL_SPEND 
FROM dbo.Customer AS A
INNER JOIN dbo.Invoice AS B ON A.CustomerId = B.CustomerId
GROUP BY A.CustomerId, A.FirstName, A.LastName
ORDER BY TOTAL_SPEND DESC

/*Question 4:
Use your query to return the email, first name, last name, and Genre of all Rock Music listeners.
Return your list ordered alphabetically by email address starting with A.*/

SELECT DISTINCT A.FirstName, A.LastName, A.Email, E.Name AS GENRE
FROM dbo.Customer AS A
INNER JOIN dbo.Invoice AS B ON A.CustomerId = B.CustomerId
INNER JOIN dbo.InvoiceLine AS C ON B.InvoiceId = C.InvoiceId
INNER JOIN dbo.Track AS D ON C.TrackId = D.TrackId
INNER JOIN dbo.Genre AS E ON D.GenreId = E.GenreId
WHERE E.Name = 'Rock'
ORDER BY A.Email;

/*Question 5: Who is writing the rock music?
Now that we know that our customers love rock music, we can decide which musicians to invite to play at the concert.
Let's invite the artists who have written the most rock music in our dataset. 
Write a query that returns the Artist name and total track count of the top 10 rock bands.*/

SELECT TOP 10 C.ArtistId, C.Name AS ARTIST, COUNT(DISTINCT A.TrackId) TRACK_CNT --A.Name 
FROM dbo.Track AS A
JOIN dbo.Album AS B ON A.AlbumId = B.AlbumId
JOIN dbo.Artist AS C ON B.ArtistId = C.ArtistId
JOIN dbo.Genre AS D ON A.GenreId = D.GenreId
WHERE D.Name = 'Rock'
GROUP BY C.ArtistId, C.Name
ORDER BY TRACK_CNT DESC;

/*Question 6
First, find which artist has earned the most according to the InvoiceLines?
Now use this artist to find which customer spent the most on this artist.
For this query, you will need to use the Invoice, InvoiceLine, Track, Customer, Album, and Artist tables.
Notice, this one is tricky because the Total spent in the Invoice table might not be on a single product, 
so you need to use the InvoiceLine table to find out how many of each product was purchased, 
and then multiply this by the price for each artist.*/

WITH TOP_EARNING_ARTIST AS(
	SELECT TOP 1 D.ArtistId, D.Name, SUM(A.Quantity * A.UnitPrice) TOTAL_EARNING
	FROM InvoiceLine AS A
	JOIN Track AS B ON A.TrackId = B.TrackId
	JOIN dbo.Album AS C ON B.AlbumId = C.AlbumId
	JOIN dbo.Artist AS D ON C.ArtistId = D.ArtistId
	GROUP BY D.ArtistId, D.Name
	ORDER BY TOTAL_EARNING DESC
)

SELECT E.ArtistId, E.Name, F.FirstName, F.LastName, SUM(B.Quantity*B.UnitPrice) BILL_AMT
FROM Invoice AS A
JOIN InvoiceLine AS B ON A.InvoiceId = B.InvoiceId
JOIN Track AS C ON C.TrackId = B.TrackId
JOIN Album AS D ON C.AlbumId = D.AlbumId
JOIN TOP_EARNING_ARTIST AS E ON E.ArtistId = D.ArtistId
JOIN Customer AS F ON A.CustomerId = F.CustomerId
GROUP BY E.ArtistId, E.Name, F.FirstName, F.LastName
ORDER BY BILL_AMT DESC

/*Question 7:
We want to find out the most popular music Genre for each country. 
We determine the most popular genre as the genre with the highest amount of purchases. 
Write a query that returns each country along with the top Genre. 
For countries where the maximum number of purchases is shared return all Genres.*/

-- Main query
WITH PURCHASE_PER_COUNTRY AS(
	SELECT C.Country, E.Name AS GENRE, COUNT(*) PURCHASE_COUNT
	FROM InvoiceLine AS A
	JOIN Invoice AS B ON A.InvoiceId = B.InvoiceId
	JOIN Customer AS C ON C.CustomerId = B.CustomerId
	JOIN Track AS D ON D.TrackId = A.TrackId
	JOIN Genre AS E ON E.GenreId = D.GenreId
	GROUP BY C.Country, E.Name, E.GenreId
)
, MAX_GENRE_CNT_PER_COUNTRY AS(
SELECT Country, MAX(PURCHASE_COUNT) CNT FROM PURCHASE_PER_COUNTRY
GROUP BY Country
)
SELECT A.*
FROM PURCHASE_PER_COUNTRY AS A
JOIN MAX_GENRE_CNT_PER_COUNTRY AS B ON A.Country = B.Country
WHERE A.PURCHASE_COUNT = B.CNT;


-- Data Validation query
SELECT C.Country, E.Name AS GENRE, COUNT(*) PURCHASE_COUNT
FROM InvoiceLine AS A
JOIN Invoice AS B ON A.InvoiceId = B.InvoiceId
JOIN Customer AS C ON C.CustomerId = B.CustomerId
JOIN Track AS D ON D.TrackId = A.TrackId
JOIN Genre AS E ON E.GenreId = D.GenreId
-- update country name to verify results
WHERE C.Country = 'Sweden'
GROUP BY C.Country, E.Name, E.GenreId;



-- LOOKUP COMMANDS
SELECT TOP 10 * FROM dbo.Track WHERE TrackId IN (1202,1208,1214,1220,1226,1232,1238,1244,1250); --
SELECT TOP 10 * FROM dbo.Album WHERE AlbumId IN (94,95,96,97,98); --
SELECT TOP 10 * FROM dbo.Artist; --
SELECT TOP 10 * FROM dbo.Customer WHERE CustomerId = 27; --
SELECT TOP 10 * FROM dbo.InvoiceLine WHERE InvoiceId = 39; --
SELECT TOP 10 * FROM dbo.Invoice WHERE InvoiceId = 39; --