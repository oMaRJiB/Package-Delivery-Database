-- 1. Truck 1738 crash thing
SELECT DISTINCT c.id, c.name, c.email
FROM tracking_events te
JOIN trucks tr   ON tr.location_id = te.location_id AND tr.truck_no = 1738
JOIN packages p  ON p.tracking_no  = te.tracking_no
JOIN customers c ON c.id = p.customer_id
WHERE te.event_type = 'LOAD'
  AND te.event_time <= '2026-06-15 14:30:00'
  AND NOT EXISTS (SELECT 1 FROM tracking_events t2
                  WHERE t2.tracking_no = te.tracking_no
                    AND t2.event_time  > te.event_time
                    AND t2.event_time <= '2026-06-15 14:30:00'
                    AND t2.event_type IN ('UNLOAD','DELIVERED'))
ORDER BY c.name;

-- Recipients with a package on that truck
SELECT DISTINCT r.id, r.name, r.phone
FROM tracking_events te
JOIN trucks tr    ON tr.location_id = te.location_id AND tr.truck_no = 1738
JOIN packages p   ON p.tracking_no  = te.tracking_no
JOIN recipients r ON r.id = p.recipient_id
WHERE te.event_type = 'LOAD'
  AND te.event_time <= '2026-06-15 14:30:00'
  AND NOT EXISTS (SELECT 1 FROM tracking_events t2
                  WHERE t2.tracking_no = te.tracking_no
                    AND t2.event_time  > te.event_time
                    AND t2.event_time <= '2026-06-15 14:30:00'
                    AND t2.event_type IN ('UNLOAD','DELIVERED'))
ORDER BY r.name;

-- Last successful delivery by that truck before the crash
SELECT te.event_time AS delivered_at, p.tracking_no, r.name AS recipient, d.signed_by
FROM tracking_events te
JOIN trucks tr    ON tr.location_id = te.location_id AND tr.truck_no = 1738
JOIN deliveries d ON d.event_id     = te.id
JOIN packages p   ON p.tracking_no  = te.tracking_no
JOIN recipients r ON r.id           = p.recipient_id
WHERE te.event_type = 'DELIVERED'
  AND te.event_time <= '2026-06-15 14:30:00'
ORDER BY te.event_time DESC
LIMIT 1;


-- 2. Customer who shipped the most packages this year 
SELECT c.id, c.name, COUNT(*) AS packages_shipped
FROM packages p
JOIN customers c ON c.id = p.customer_id
WHERE p.shipped_at >= NOW() - INTERVAL 1 YEAR
GROUP BY c.id, c.name
ORDER BY packages_shipped DESC
LIMIT 1;


-- 3. Customer who spent the most on shipping this year 
SELECT c.id, c.name, SUM(pay.amount) AS total_spent
FROM packages p
JOIN payments pay ON pay.id = p.payment_id
JOIN customers c ON c.id = p.customer_id
WHERE p.shipped_at >= NOW() - INTERVAL 1 YEAR
GROUP BY c.id, c.name
ORDER BY total_spent DESC
LIMIT 1;


-- 4. Street with the most customers 
SELECT a.street, a.city, a.state_province, COUNT(*) AS customers
FROM customers c
JOIN addresses a ON a.id = c.address_id
GROUP BY a.street, a.city, a.state_province
ORDER BY customers DESC
LIMIT 1;


-- 5. Packages not delivered within the promised time 
SELECT p.tracking_no, c.name AS customer, s.name AS service,
       p.expected_delivery_date, te.event_time AS delivered_at
FROM packages p
JOIN customers c ON c.id = p.customer_id
JOIN services s  ON s.id = p.service_code
LEFT JOIN tracking_events te ON te.tracking_no = p.tracking_no
                            AND te.event_type  = 'DELIVERED'
WHERE te.event_time > p.expected_delivery_date
   OR (te.id IS NULL AND p.expected_delivery_date < NOW())
ORDER BY p.expected_delivery_date;


--  6. Bills for the past month 
SELECT c.name,
       a.street,
       a.city, a.state_province, a.postal_code,
       SUM(pay.amount) AS amount_owed
FROM packages p
JOIN payments pay ON pay.id = p.payment_id
JOIN customers c ON c.id = p.customer_id
JOIN addresses a  ON a.id   = c.address_id
WHERE p.shipped_at >= '2026-06-01'
  AND p.shipped_at <  '2026-07-01'
GROUP BY c.id, c.name, a.street,
         a.city, a.state_province, a.postal_code
ORDER BY c.name;

-- 6b. Bill by type of service, with per-customer subtotals and a grand total
SELECT c.name AS customer,
       s.name AS service,
       COUNT(*)        AS shipments,
       SUM(pay.amount) AS charges
FROM packages p
JOIN payments pay ON pay.id = p.payment_id
JOIN services s   ON s.id   = p.service_code
JOIN customers c ON c.id = p.customer_id
WHERE p.shipped_at >= '2026-06-01'
  AND p.shipped_at <  '2026-07-01'
GROUP BY c.id, c.name, s.id, s.name WITH ROLLUP;

-- 6c. Itemized bill: every shipment and its charge
SELECT c.name AS customer, p.tracking_no, DATE(p.shipped_at) AS shipped,
       s.name AS service, p.weight, r.name AS ship_to, pay.amount AS charge
FROM packages p
JOIN payments pay ON pay.id = p.payment_id
JOIN customers c ON c.id = p.customer_id
JOIN services s   ON s.id   = p.service_code
JOIN recipients r ON r.id   = p.recipient_id
WHERE p.shipped_at >= '2026-06-01'
  AND p.shipped_at <  '2026-07-01'
ORDER BY c.name, p.shipped_at;