CREATE TABLE locations (
    id INT AUTO_INCREMENT PRIMARY KEY
);
CREATE TABLE addresses (
    id INT PRIMARY KEY,
    street VARCHAR(128) NOT NULL,
    city VARCHAR(64) NOT NULL,
    state_province VARCHAR(64) NOT NULL,
    postal_code VARCHAR(9) NOT NULL,
    country CHAR(2) NOT NULL,
    FOREIGN KEY (id) REFERENCES locations(id)
);

CREATE TABLE customers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(64) NOT NULL,
    email VARCHAR(64) UNIQUE NOT NULL,
    phone CHAR(10),
    address_id INT NOT NULL,
    FOREIGN KEY (address_id) REFERENCES addresses(id) ON UPDATE CASCADE
);

CREATE TABLE accounts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES customers(id) ON UPDATE CASCADE
);

CREATE TABLE payments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    amount DECIMAL(10,2) NOT NULL,
    payment_time DATETIME NOT NULL
);

CREATE TABLE invoices (
    id INT AUTO_INCREMENT PRIMARY KEY,
    account_id INT NOT NULL,
    invoice_date DATETIME NOT NULL,
    due_date DATETIME NOT NULL,
    FOREIGN KEY (account_id) REFERENCES accounts(id) ON UPDATE CASCADE
);

CREATE TABLE account_charges(
    id INT AUTO_INCREMENT PRIMARY KEY,
    payment_id INT NOT NULL,
    invoice_id INT NOT NULL,
    FOREIGN KEY (payment_id) REFERENCES payments(id) ON UPDATE CASCADE,
    FOREIGN KEY (invoice_id) REFERENCES invoices(id) ON UPDATE CASCADE
);

CREATE TABLE prepaid_labels (
    id INT AUTO_INCREMENT PRIMARY KEY,
    label_code VARCHAR(64) UNIQUE NOT NULL,
    payment_id INT NOT NULL,
    FOREIGN KEY (payment_id) REFERENCES payments(id) ON UPDATE CASCADE
);

CREATE TABLE recipients (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(64) NOT NULL,
    phone VARCHAR(10),
    address_id INT NOT NULL,
    FOREIGN KEY (address_id) REFERENCES addresses(id) ON UPDATE CASCADE
);

-- Packages
CREATE TABLE services (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(64) NOT NULL,
    base_cost DECIMAL(10,2) NOT NULL,
    per_kg_cost DECIMAL(10,2) NOT NULL,
    hazard_surcharge DECIMAL(10,2) NOT NULL,
    intl_surcharge DECIMAL(10,2) NOT NULL,
    delivery_time_estimate INT NOT NULL
);

CREATE TABLE packages (
    tracking_no VARCHAR(32) PRIMARY KEY,
    customer_id INT NOT NULL,
    recipient_id INT NOT NULL,
    type  VARCHAR(32) NOT NULL,
    weight DECIMAL(10,2) NOT NULL,
    service_code INT NOT NULL,
    is_hazard INT NOT NULL DEFAULT 0 CHECK (is_hazard IN (0, 1)),
    is_intl INT NOT NULL DEFAULT 0 CHECK (is_intl IN (0, 1)),
    payment_id INT NOT NULL,
    expected_delivery_date DATETIME NOT NULL,
    FOREIGN KEY (payment_id) REFERENCES payments(id) ON UPDATE CASCADE,
    FOREIGN KEY (customer_id) REFERENCES customers(id) ON UPDATE CASCADE,
    FOREIGN KEY (recipient_id) REFERENCES recipients(id) ON UPDATE CASCADE,
    FOREIGN KEY (service_code) REFERENCES services(id) ON UPDATE CASCADE
);
-- Customs Declarations
CREATE TABLE customs_declarations (
    id INT AUTO_INCREMENT PRIMARY KEY,
    tracking_no VARCHAR(32) NOT NULL,
    origin_country CHAR(2) NOT NULL,
    destination_country CHAR(2) NOT NULL,
    total_value DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (tracking_no) REFERENCES packages(tracking_no) ON DELETE CASCADE
);

CREATE TABLE customs_items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    declaration_id INT NOT NULL,
    line_no VARCHAR(16) NOT NULL,
    item_value DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (declaration_id) REFERENCES customs_declarations(id) ON DELETE CASCADE
);
-- tracking
CREATE TABLE warehouses (
    location_id INT PRIMARY KEY,
    address_id INT NOT NULL,
    FOREIGN KEY (location_id) REFERENCES locations(id) ON DELETE CASCADE,
    FOREIGN KEY (address_id) REFERENCES addresses(id)
);
CREATE TABLE trucks (
    location_id INT PRIMARY KEY,
    plate_no VARCHAR(10) NOT NULL,
    FOREIGN KEY (location_id) REFERENCES locations(id) ON DELETE CASCADE
);
CREATE TABLE planes (
    location_id INT PRIMARY KEY,
    tail_no VARCHAR(10) NOT NULL,
    FOREIGN KEY (location_id) REFERENCES locations(id) ON DELETE CASCADE
);

CREATE TABLE tracking_events (
    id INT AUTO_INCREMENT PRIMARY KEY,
    tracking_no VARCHAR(32) NOT NULL,
    event_time DATETIME NOT NULL,
    location_id INT NOT NULL,
    event_type  VARCHAR(32) NOT NULL,
    FOREIGN KEY (tracking_no) REFERENCES packages(tracking_no) ON DELETE RESTRICT,
    FOREIGN KEY (location_id) REFERENCES locations(id) ON DELETE CASCADE
);

CREATE TABLE deliveries (
    event_id INT PRIMARY KEY,
    delivery_time DATETIME NOT NULL,
    signed_by VARCHAR(64) NOT NULL,
    FOREIGN KEY (event_id) REFERENCES tracking_events(id) ON DELETE CASCADE
);