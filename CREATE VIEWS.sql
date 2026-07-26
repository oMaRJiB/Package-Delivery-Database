-- base view (the join logic lives here once)
CREATE VIEW v_itemized_invoice AS
SELECT
    i.id AS invoice_id,
    i.account_id,
    c.name AS customer_name,
    a.street, a.city, a.state_province, a.postal_code,
    p.tracking_no,
    s.name AS service_name,
    s.base_cost 
    + p.weight*s.per_kg_cost 
    + p.is_hazard*s.hazard_surcharge
    + p.is_intl*s.intl_surcharge AS charge_amount,
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
SELECT invoice_id, customer_name, street, city, state_province, postal_code,
       SUM(charge_amount) AS amount_owed
FROM v_itemized_invoice
GROUP BY invoice_id, customer_name, street, city, state_province, postal_code;

--bill by service type
CREATE VIEW v_bill_by_service AS
SELECT invoice_id, customer_name, service_name,
       SUM(charge_amount) AS service_total
FROM v_itemized_invoice
GROUP BY invoice_id, customer_name, service_name;