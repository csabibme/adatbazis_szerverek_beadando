EXPLAIN
SELECT vehicle_id, make, model, year, status
FROM vehicles
WHERE status = TRUE;

EXPLAIN
SELECT c.name, v.make, v.model, r.start_date, r.end_date
FROM rentals r
JOIN customers c ON r.customer_id = c.customer_id
JOIN vehicles v ON r.vehicle_id = v.vehicle_id
WHERE c.name = 'Lenkei Anett';

EXPLAIN
SELECT i.invoice_id, i.amount, i.issue_date, i.due_date
FROM invoices i
JOIN customers c ON i.customer_id = c.customer_id
WHERE c.name = 'Lenkei Anett';


EXPLAIN
SELECT vc.description, COUNT(r.rental_id) AS rental_count
FROM rentals r
JOIN vehicles v ON r.vehicle_id = v.vehicle_id
JOIN vehicle_categories vc ON v.category = vc.category
GROUP BY vc.description
ORDER BY rental_count DESC;
