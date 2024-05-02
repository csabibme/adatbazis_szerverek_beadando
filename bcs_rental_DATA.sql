BEGIN;

-- Ügyfelek adatokkal való feltöltése

INSERT INTO customers (name, city, address, email, phone, zipcode, county) VALUES
('Szabo Laszlo', 'Szeged', 'Kossuth Lajos sgt. 50.', 'szabo.laszlo@email.com', '06701234657', 6720, 'Csongrád-Csanád'),
('Toth Agnes', 'Pécs', 'Mártírok útja 11.', 'toth.agnes@email.com', '06706544321', 7622, 'Baranya'),
('Varga József', 'Győr', 'Baross Gábor u. 14.', 'varga.jozsef@email.com', '06701234777', 9022, 'Győr-Moson-Sopron'),
('Kis Gergely', 'Miskolc', 'Széchenyi István út 22.', 'kis.gergely@email.com', '06706544888', 3525, 'Borsod-Abaúj-Zemplén'),
('Nemes Anna', 'Kecskemét', 'Kossuth tér 10.', 'nemes.anna@email.com', '06701234999', 6000, 'Bács-Kiskun'),
('Farkas Balázs', 'Nyíregyháza', 'Dózsa György út 56.', 'farkas.balazs@email.com', '06706544000', 4400, 'Szabolcs-Szatmár-Bereg'),
('Balogh Éva', 'Eger', 'Egészségház u. 4.', 'balogh.eva@email.com', '06701234560', 3300, 'Heves'),
('Tószegi Viktor', 'Veszprém', 'Király u. 15.', 'toszegi.viktor@email.com', '06701234561', 8200, 'Veszprém'),
('Lakatos Brigitta', 'Zalaegerszeg', 'Petőfi Sándor u. 25.', 'lakatos.brigitta@email.com', '06701234562', 8900, 'Zala'),
('Horvath Lajos', 'Szombathely', 'Vas Gereben u. 9.', 'horvath.lajos@email.com', '06706544555', 9700, 'Vas'),
('Kovács István', 'Kaposvár', 'Fő u. 33.', 'kovacs.istvan@email.com', '06706544666', 7400, 'Somogy'),
('Szűcs Béla', 'Salgótarján', 'Rákóczi út 47.', 'szucs.bela@email.com', '06701234789', 3100, 'Nógrád'),
('Molnár Csaba', 'Tatabánya', 'Aradi vértanúk útja 101.', 'molnar.csaba@email.com', '06701234890', 2800, 'Komárom-Esztergom'),
('Fehér Ádám', 'Békéscsaba', 'Andrássy út 12.', 'feher.adam@email.com', '06706544777', 5600, 'Békés'),
('Juhász Petra', 'Székesfehérvár', 'Palotai út 21.', 'juhasz.petra@email.com', '06701234678', 8000, 'Fejér'),
('Erős Dániel', 'Hódmezővásárhely', 'Kossuth Lajos u. 88.', 'eros.daniel@email.com', '06706544111', 6800, 'Csongrád-Csanád'),
('Gál Anikó', 'Debrecen', 'Hatvan u. 3.', 'gal.aniko@email.com', '06706544222', 4025, 'Hajdú-Bihar'),
('Orosz Márton', 'Budapest', 'Nagymező u. 44.', 'orosz.marton@email.com', '06701234910', 1173, 'Budapest'),
('Lenkei Anett', 'Budapest', 'Haller u. 28 I/A 11.', 'lenkeia88@hotmail.com', '06501211111', 1101, 'Budapest');


-- Járművek adatokkal való feltöltése
INSERT INTO vehicles (license_plate, make, model, year, status, category) VALUES
('ABC-123', 'Ford', 'Focus', 2018, TRUE, 1),
('XYZ-789', 'Audi', 'A6', 2020, TRUE, 3),
('DEF-456', 'Toyota', 'Camry', 2019, TRUE, 3),
('GHI-789', 'Honda', 'Civic', 2021, TRUE, 1),
('JKL-012', 'BMW', 'X5', 2020, TRUE, 3),
('MNO-345', 'Mercedes-Benz', 'E-Class', 2017, TRUE, 2),
('PQR-678', 'Volkswagen', 'Golf', 2019, TRUE, 1),
('STU-901', 'Hyundai', 'Elantra', 2020, TRUE, 2),
('VWX-234', 'Chevrolet', 'Cruze', 2018, TRUE, 2),
('YZA-567', 'Kia', 'Optima', 2019, TRUE, 2),
('AA-CF-211', 'Toyota','Civic', 2023, TRUE, 2),
('TZT-233', 'Mercedes-Benz', 'S-Class 500', 2022, TRUE, 4);



-- Kölcsönzések adatokkal való feltöltése 80 rekorddal (random dátumok max 2 hónap kölcsönzés 2020-01-31 és 2024-04-30 között)
INSERT INTO rentals (vehicle_id, customer_id, customer_county, start_date, end_date)
SELECT 
    floor(random() * 12) + 1, -- Random vehicle ID from 1 to 12
    c.customer_id, -- Random customer ID
    c.county, -- County corresponding to the customer ID
    start_date_random,
    start_date_random + (floor(random() * 60) + 1 || ' days')::INTERVAL -- Random end date between start date and 2 months later
FROM 
    generate_series(1, 80) AS gs
JOIN
    (SELECT 
        customer_id, 
        county,
        '2020-01-30'::DATE + floor(random() * ('2024-04-30'::DATE - '2020-01-30'::DATE + 1)) * INTERVAL '1 day' as start_date_random
    FROM 
        customers 
    ORDER BY 
        random() 
    LIMIT 80) AS c
ON
    true;



-- Számlák adatokkal feltöltése (a már elkészített rental-okból)
DO $$
DECLARE
    rental_id_param INT;
BEGIN
    FOR rental_id_param IN
        SELECT rental_id FROM rentals
    LOOP
        PERFORM generate_invoice(rental_id_param);
    END LOOP;
END $$;

COMMIT;