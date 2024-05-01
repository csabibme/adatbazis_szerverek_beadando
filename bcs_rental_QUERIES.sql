-- ************************************
-- *** QUERIES on bcs_rental - TEST ***
-- ************************************

-- 1. Az össes jelenleg elérhető jűrmű lekérdezése
SELECT vehicle_id, make, model, year, status
FROM vehicles
WHERE status = TRUE;

-- 2. Kölcsönzési előzmények (itt át kell térni az customer id-ra)
SELECT c.name, v.make, v.model, r.start_date, r.end_date
FROM rentals r
JOIN customers c ON r.customer_id = c.customer_id
JOIN vehicles v ON r.vehicle_id = v.vehicle_id
WHERE c.name = 'Nagy István'; -- Itt egy konkrét ügyfél nevét kell megadni

-- 3. Egy adott ügyfél számláinak lekérdezése (fiygelj rá, hogy legyen ügyfél!)
SELECT i.invoice_id, i.amount, i.issue_date, i.due_date
FROM invoices i
JOIN customers c ON i.customer_id = c.customer_id
WHERE c.name = 'Kovács Anna'  -- Név alapján keresés
   OR c.customer_id = 123;  -- ID alapján keresés


-- 4. Kategóriák szerinti kölcsönzési statisztika
SELECT vc.description, COUNT(r.rental_id) AS rental_count
FROM rentals r
JOIN vehicles v ON r.vehicle_id = v.vehicle_id
JOIN vehicle_categories vc ON v.category = vc.category
GROUP BY vc.description
ORDER BY rental_count DESC;

-- 5. számlák kimutatás havi bontásban
SELECT EXTRACT(YEAR FROM issue_date) AS year, EXTRACT(MONTH FROM issue_date) AS month, SUM(amount) AS total_amount
FROM invoices
GROUP BY year, month
ORDER BY year DESC, month DESC;

-- 6. Vehicle Report (view a bcs_rental.sql-ben)
SELECT * FROM Vehicle_Report;
