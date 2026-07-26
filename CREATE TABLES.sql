CREATE TABLE locations (
    id INT PRIMARY KEY AUTOINCREMENT
);
CREATE TABLE addresses (
    id INT PRIMARY KEY,
    street TEXT NOT NULL,
    city TEXT NOT NULL,
    state TEXT NOT NULL,
    postal_code TEXT NOT NULL,
    country TEXT NOT NULL,
    FOREIGN KEY (id) REFERENCES locations(id)
);

CREATE TABLE customers (
    id INT PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    phone TEXT,
    address_id INT NOT NULL,
    FOREIGN KEY (address_id) REFERENCES addresses(id) ON UPDATE CASCADE
);

CREATE TABLE accounts (
    id INT PRIMARY KEY AUTOINCREMENT,
    customer_id INT NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES customers(id) ON UPDATE CASCADE
);

CREATE TABLE payments (
    id INT PRIMARY KEY AUTOINCREMENT,
    amount REAL NOT NULL,
    payment_time DATETIME NOT NULL
);

CREATE TABLE invoices (
    id INT PRIMARY KEY AUTOINCREMENT,
    account_id INT NOT NULL,
    invoice_date DATETIME NOT NULL,
    due_date DATETIME NOT NULL,
    FOREIGN KEY (account_id) REFERENCES accounts(id) ON UPDATE CASCADE
);

CREATE TABLE account_charges(
    id INT PRIMARY KEY AUTOINCREMENT,
    payment_id INT NOT NULL,
    invoice_id INT NOT NULL,
    FOREIGN KEY (payment_id) REFERENCES payments(id) ON UPDATE CASCADE,
    FOREIGN KEY (invoice_id) REFERENCES invoices(id) ON UPDATE CASCADE
);

CREATE TABLE prepaid_labels (
    id INT PRIMARY KEY AUTOINCREMENT,
    label_code TEXT UNIQUE NOT NULL,
    payment_id INT NOT NULL,
    FOREIGN KEY (payment_id) REFERENCES payments(id) ON UPDATE CASCADE
);

CREATE TABLE recipients (
    id INT PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    phone TEXT,
    address_id INT NOT NULL,
    FOREIGN KEY (address_id) REFERENCES addresses(id) ON UPDATE CASCADE
);

-- Packages
CREATE TABLE services (
    id INT PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    base_cost REAL NOT NULL,
    per_kg_cost REAL NOT NULL,
    hazard_surcharge REAL NOT NULL,
    intl_surcharge REAL NOT NULL,
    delivery_time_estimate INT NOT NULL
);

CREATE TABLE packages (
    tracking_no TEXT PRIMARY KEY,
    customer_id INT NOT NULL,
    recipient_id INT NOT NULL,
    type TEXT NOT NULL,
    weight REAL NOT NULL,
    service_code INT NOT NULL,
    is_hazardous INT NOT NULL DEFAULT 0 CHECK (is_hazardous IN (0, 1)),
    is_international INT NOT NULL DEFAULT 0 CHECK (is_international IN (0, 1)),
    payment_id INT NOT NULL,
    expected_delivery_date DATETIME NOT NULL,
    FOREIGN KEY (payment_id) REFERENCES payments(id) ON UPDATE CASCADE,
    FOREIGN KEY (customer_id) REFERENCES customers(id) ON UPDATE CASCADE,
    FOREIGN KEY (recipient_id) REFERENCES recipients(id) ON UPDATE CASCADE,
    FOREIGN KEY (service_code) REFERENCES services(id) ON UPDATE CASCADE
);
--Customs Declarations
CREATE TABLE customs_declarations (
    id INT PRIMARY KEY AUTOINCREMENT,
    tracking_no TEXT NOT NULL,
    origin_country TEXT NOT NULL,
    destination_country TEXT NOT NULL,
    total_value REAL NOT NULL,
    FOREIGN KEY (tracking_no) REFERENCES packages(tracking_no) ON DELETE CASCADE
);

CREATE TABLE customs_items (
    id INT PRIMARY KEY AUTOINCREMENT,
    declaration_id INT NOT NULL,
    line_no TEXT NOT NULL,
    item_value REAL NOT NULL,
    FOREIGN KEY (declaration_id) REFERENCES customs_declarations(id) ON DELETE CASCADE
);
--tracking
CREATE TABLE warehouses (
    location_id INT PRIMARY KEY,
    address_id INT NOT NULL,
    FOREIGN KEY (location_id) REFERENCES locations(id) ON DELETE CASCADE,
    FOREIGN KEY (address_id) REFERENCES addresses(id)
);
CREATE TABLE trucks (
    location_id INT PRIMARY KEY,
    plate_no TEXT NOT NULL,
    FOREIGN KEY (location_id) REFERENCES locations(id) ON DELETE CASCADE
);
CREATE TABLE planes (
    location_id INT PRIMARY KEY,
    tail_no TEXT NOT NULL,
    FOREIGN KEY (location_id) REFERENCES locations(id) ON DELETE CASCADE
);

CREATE TABLE tracking_events (
    id INT PRIMARY KEY AUTOINCREMENT,
    tracking_no TEXT NOT NULL,
    event_time DATETIME NOT NULL,
    location_id INT NOT NULL,
    event_type TEXT NOT NULL,
    FOREIGN KEY (tracking_no) REFERENCES packages(tracking_no) ON DELETE RESTRICT,
    FOREIGN KEY (location_id) REFERENCES locations(id) ON DELETE CASCADE
);

CREATE TABLE deliveries (
    event_id INT PRIMARY KEY,
    delivery_time DATETIME NOT NULL,
    signed_by TEXT NOT NULL,
    FOREIGN KEY (event_id) REFERENCES tracking_events(id) ON DELETE CASCADE
);


-- base view (the join logic lives here once)
CREATE VIEW v_itemized_invoice AS
SELECT
    i.id AS invoice_id,
    i.account_id,
    c.name AS customer_name,
    a.street, a.city, a.state, a.postal_code,
    p.tracking_no,
    s.name AS service_name,
    calc_pack_cost(p.tracking_no) AS charge_amount,
    i.invoice_date,
    i.due_date
FROM invoices i
JOIN accounts acc ON acc.id = i.account_id
JOIN customers c ON c.id = acc.customer_id
JOIN addresses a ON a.id = c.address_id
JOIN account_charges ac ON ac.invoice_id = i.id
JOIN payments pay ON pay.id = ac.payment_id
JOIN packages p ON p.payment_id = pay.id
JOIN services s ON s.id = p.service_code;

--simple bill: customer, address, amount owed
CREATE VIEW v_simple_bill AS
SELECT invoice_id, customer_name, street, city, state, postal_code,
       SUM(charge_amount) AS amount_owed
FROM v_itemized_invoice
GROUP BY invoice_id, customer_name, street, city, state, postal_code;

--bill by service type
CREATE VIEW v_bill_by_service AS
SELECT invoice_id, customer_name, service_name,
       SUM(charge_amount) AS service_total
FROM v_itemized_invoice
GROUP BY invoice_id, customer_name, service_name;