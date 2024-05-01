BEGIN; -- TRANSACTION begin

-- Table drops
DROP TABLE IF EXISTS invoices CASCADE;
DROP TABLE IF EXISTS rentals CASCADE;
DROP TABLE IF EXISTS customers CASCADE;
DROP TABLE IF EXISTS vehicles CASCADE;
DROP TABLE IF EXISTS vehicle_categories CASCADE;

-- Create vehicle categories
CREATE TABLE vehicle_categories (
    category INT PRIMARY KEY,
    description VARCHAR(50) NOT NULL,
    daily_rate INT NOT NULL
);

-- A kategóriák feltöltése
INSERT INTO vehicle_categories (category, description, daily_rate) VALUES
(1, 'Városi alapkategória', 2500),
(2, 'Minőségi középkategória', 4500),
(3, 'Felsőkategória', 7000),
(4, 'Luxus kategória', 15000);

-- Create vehicles
CREATE TABLE vehicles (
    vehicle_id SERIAL PRIMARY KEY,
    license_plate VARCHAR(10) UNIQUE NOT NULL,
    make VARCHAR(50) NOT NULL,
    model VARCHAR(50) NOT NULL,
    year INT NOT NULL,
    status BOOLEAN NOT NULL DEFAULT TRUE,
    category INT NOT NULL REFERENCES vehicle_categories(category)
);

-- Create partitioned customers
CREATE TABLE customers (
    customer_id SERIAL,
    name VARCHAR(100) NOT NULL,
    city VARCHAR(150) NOT NULL,
    address VARCHAR(255) NOT NULL,
    email VARCHAR(100),
    phone VARCHAR(15),
    zipcode INT CHECK (zipcode >= 1000 AND zipcode <= 9999),
    county VARCHAR(50) NOT NULL,
    PRIMARY KEY (customer_id, county), -- Include county in primary key
    unique (customer_id, county)
) PARTITION BY LIST (county);

-- Partíciók létrehozása a megyékhez
CREATE TABLE customers_budapest PARTITION OF customers FOR VALUES IN ('Budapest');
CREATE TABLE customers_baranya PARTITION OF customers FOR VALUES IN ('Baranya vármegye');
CREATE TABLE customers_bacs PARTITION OF customers FOR VALUES IN ('Bács-Kiskun vármegye');
CREATE TABLE customers_baz PARTITION OF customers FOR VALUES IN ('Borsod-Abaúj-Zemplén vármegye');
CREATE TABLE customers_bekes PARTITION OF customers FOR VALUES IN ('Békés vármegye');
CREATE TABLE customers_csongrad PARTITION OF customers FOR VALUES IN ('Csongrád-Csanád vármegye');
CREATE TABLE customers_fejer PARTITION OF customers FOR VALUES IN ('Fejér vármegye');
CREATE TABLE customers_hajdubihar PARTITION OF customers FOR VALUES IN ('Hajdú-Bihar vármegye');
CREATE TABLE customers_heves PARTITION OF customers FOR VALUES IN ('Heves vármegye');
CREATE TABLE customers_jnsz PARTITION OF customers FOR VALUES IN ('Jász-Nagykun-Szolnok vármegye');
CREATE TABLE customers_komaromesztergom PARTITION OF customers FOR VALUES IN ('Komárom-Esztergom vármegye');
CREATE TABLE customers_nograd PARTITION OF customers FOR VALUES IN ('Nógrád vármegye');
CREATE TABLE customers_pest PARTITION OF customers FOR VALUES IN ('Pest vármegye');
CREATE TABLE customers_somogy PARTITION OF customers FOR VALUES IN ('Somogy vármegye');
CREATE TABLE customers_szabolcs PARTITION OF customers FOR VALUES IN ('Szabolcs-Szatmár-Bereg vármegye');
CREATE TABLE customers_tolna PARTITION OF customers FOR VALUES IN ('Tolna vármegye');
CREATE TABLE customers_vas PARTITION OF customers FOR VALUES IN ('Vas vármegye');
CREATE TABLE customers_veszprem PARTITION OF customers FOR VALUES IN ('Veszprém vármegye');
CREATE TABLE customers_zala PARTITION OF customers FOR VALUES IN ('Zala vármegye');
CREATE TABLE customers_other PARTITION OF customers DEFAULT; -- külföldi címeknél, vagy más nem besorolható megye adatoknál használjuk

-- Create rentals
CREATE TABLE rentals (
    rental_id SERIAL PRIMARY KEY,
    vehicle_id INT NOT null,
    customer_id INT NOT null,
    customer_county VARCHAR(50) NOT null,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    FOREIGN KEY (customer_id, customer_county) REFERENCES customers(customer_id, county)
);

-- Create invoices
CREATE TABLE invoices (
    invoice_id SERIAL PRIMARY KEY,
    rental_id INT NOT null,
    customer_id INT NOT null,
    customer_county VARCHAR(50) not null,
    customer_name VARCHAR(100) NOT NULL,
    customer_address VARCHAR(255) NOT NULL,
    amount INT NOT NULL,
    issue_date DATE NOT NULL,
    due_date DATE NOT null,
    FOREIGN KEY (customer_id, customer_county) REFERENCES customers(customer_id, county)
);

-- Create indexes
CREATE INDEX idx_vehicles_status_category ON vehicles (status, category);
CREATE INDEX idx_customers_name ON customers USING btree (name);
CREATE INDEX idx_rentals_dates ON rentals (start_date, end_date);
CREATE INDEX idx_invoices_dates_amount ON invoices (issue_date, amount);

-- Create function and trigger for vehicle status
CREATE OR REPLACE FUNCTION update_vehicle_status() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = FALSE THEN
        UPDATE vehicles SET status = FALSE WHERE vehicle_id = NEW.vehicle_id;
    ELSIF NEW.status = TRUE THEN
        UPDATE vehicles SET status = TRUE WHERE vehicle_id = NEW.vehicle_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_vehicle_status AFTER UPDATE ON rentals
FOR EACH ROW EXECUTE FUNCTION update_vehicle_status();

-- Stored procedure to generate invoices
CREATE OR REPLACE FUNCTION public.generate_invoice(rental_id_param integer)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_category INT;
    v_daily_rate INT;
    v_days INT;
    v_amount INT;
    v_customer_id INT;
    v_customer_county VARCHAR(50);
    v_customer_name VARCHAR(100);
    v_customer_address VARCHAR(255);
BEGIN
    -- Correctly joining the tables and selecting the necessary columns
    SELECT v.category, vc.daily_rate, r.customer_id, c.county, c.name,
           c.city || ' ' || c.zipcode || ', ' || c.address INTO v_category, v_daily_rate, v_customer_id, v_customer_county, v_customer_name, v_customer_address
    FROM rentals r
    JOIN vehicles v ON r.vehicle_id = v.vehicle_id
    JOIN vehicle_categories vc ON v.category = vc.category
    JOIN customers c ON r.customer_id = c.customer_id AND r.customer_county = c.county
    WHERE r.rental_id = rental_id_param;

    -- Calculate the duration of the rental in days
    SELECT (r.end_date - r.start_date)::INT INTO v_days
    FROM rentals r
    WHERE r.rental_id = rental_id_param;

    -- Calculate the total invoice amount
    v_amount := v_daily_rate * v_days;

    -- Insert the invoice record with corrected county reference
    INSERT INTO invoices (rental_id, customer_id, customer_county, customer_name, customer_address, amount, issue_date, due_date)
    VALUES (rental_id_param, v_customer_id, v_customer_county, v_customer_name, v_customer_address, v_amount, CURRENT_DATE, CURRENT_DATE + INTERVAL '8 days');
END;
$function$;

-- Rental procedure
CCREATE OR REPLACE PROCEDURE process_rental(
    p_vehicle_id INT,
    p_customer_id INT,
    p_start_date DATE,
    p_end_date DATE
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_rental_id INT;
    v_county VARCHAR;
BEGIN
    -- Retrieve the county for the customer
    SELECT county INTO v_county
    FROM customers
    WHERE customer_id = p_customer_id;

    -- Check if county was successfully retrieved
    IF v_county IS NULL THEN
        RAISE EXCEPTION 'No customer found with ID %', p_customer_id;
    END IF;

    -- Insert the new rental into the 'rentals' table
    INSERT INTO rentals (vehicle_id, customer_id, customer_county, start_date, end_date)
    VALUES (p_vehicle_id, p_customer_id, v_county, p_start_date, p_end_date)
    RETURNING rental_id INTO v_rental_id;

    -- Generate invoice using the existing function
    PERFORM generate_invoice(v_rental_id);
END;
$$;


-- Create vehicle report view
CREATE VIEW Vehicle_Report AS
SELECT v.make AS Make, 
       v.model AS Model, 
       v.status AS Status, 
       COUNT(r.rental_id) AS Usage_Count
FROM vehicles v
LEFT JOIN rentals r ON v.vehicle_id = r.vehicle_id
GROUP BY v.vehicle_id
ORDER BY Usage_Count DESC;

COMMIT; -- End of transaction
