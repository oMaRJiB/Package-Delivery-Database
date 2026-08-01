-- base view (the join logic lives here once)
CREATE VIEW v_itemized_invoice AS
SELECT
    inv.id AS invoice_id,
    inv.account_id,
    custo.name AS customer_name,
    addr.street, addr.city, addr.state_province, addr.postal_code,
    pkg.tracking_no,
    svc.name AS service_name,
    svc.base_cost 
    + pkg.weight*svc.per_kg_cost 
    + pkg.is_hazard*svc.hazard_surcharge
    + pkg.is_intl*svc.intl_surcharge AS charge_amount,
    inv.invoice_date,
    inv.due_date
FROM invoices inv
JOIN accounts acct ON acct.id = inv.account_id
JOIN customers custo ON custo.id = acct.customer_id
JOIN addresses addr ON addr.id = custo.address_id
JOIN account_charges chg ON chg.invoice_id = inv.id
JOIN payments pmt ON pmt.id = chg.payment_id
JOIN packages pkg ON pkg.payment_id = pmt.id
JOIN services svc ON svc.id = pkg.service_code;

-- simple bill: customer, address, amount owed
CREATE VIEW v_simple_bill AS
SELECT invoice_id, customer_name, street, city, state_province, postal_code,
       SUM(charge_amount) AS amount_owed
FROM v_itemized_invoice
GROUP BY invoice_id, customer_name, street, city, state_province, postal_code;

-- bill by service type
CREATE VIEW v_bill_by_service AS
SELECT invoice_id, customer_name, service_name,
       SUM(charge_amount) AS service_total
FROM v_itemized_invoice
GROUP BY invoice_id, customer_name, service_name;