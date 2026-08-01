-- 1. Truck 1738 crash thing
SELECT DISTINCT custo.id, custo.name, custo.email
FROM tracking_events evt
JOIN trucks    trk   ON trk.location_id = evt.location_id AND trk.truck_no = 1721
JOIN packages  pkg   ON pkg.tracking_no = evt.tracking_no
JOIN customers custo ON custo.id        = pkg.customer_id
WHERE evt.event_type = 'LOAD'
  AND evt.event_time <= '2026-06-15 14:30:00'
  AND NOT EXISTS (SELECT 1 FROM tracking_events later
                  WHERE later.tracking_no = evt.tracking_no
                    AND later.event_time  > evt.event_time
                    AND later.event_time <= '2026-06-15 14:30:00'
                    AND later.event_type IN ('UNLOAD','DELIVERED'))
ORDER BY custo.name;

-- Recipients with a package on that truck
SELECT DISTINCT rcpt.id, rcpt.name, rcpt.phone
FROM tracking_events evt
JOIN trucks     trk  ON trk.location_id = evt.location_id AND trk.truck_no = 1721
JOIN packages   pkg  ON pkg.tracking_no = evt.tracking_no
JOIN recipients rcpt ON rcpt.id         = pkg.recipient_id
WHERE evt.event_type = 'LOAD'
  AND evt.event_time <= '2026-06-15 14:30:00'
  AND NOT EXISTS (SELECT 1 FROM tracking_events later
                  WHERE later.tracking_no = evt.tracking_no
                    AND later.event_time  > evt.event_time
                    AND later.event_time <= '2026-06-15 14:30:00'
                    AND later.event_type IN ('UNLOAD','DELIVERED'))
ORDER BY rcpt.name;

-- Last successful delivery by that truck before the crash
SELECT evt.event_time AS delivered_at, pkg.tracking_no,
       rcpt.name AS recipient, dlv.signed_by
FROM tracking_events evt
JOIN trucks     trk  ON trk.location_id = evt.location_id AND trk.truck_no = 1721
JOIN deliveries dlv  ON dlv.event_id    = evt.id
JOIN packages   pkg  ON pkg.tracking_no = evt.tracking_no
JOIN recipients rcpt ON rcpt.id         = pkg.recipient_id
WHERE evt.event_type = 'DELIVERED'
  AND evt.event_time <= '2026-06-15 14:30:00'
ORDER BY evt.event_time DESC
LIMIT 1;


-- 2. Customer who shipped the most packages this year 
SELECT custo.id, custo.name, COUNT(*) AS packages_shipped
FROM packages  pkg
JOIN customers custo ON custo.id = pkg.customer_id
WHERE pkg.shipped_at >= NOW() - INTERVAL 1 YEAR
GROUP BY custo.id, custo.name
ORDER BY packages_shipped DESC
LIMIT 1;


-- 3. Customer who spent the most on shipping this year 
<<<<<<< HEAD
SELECT custo.id, custo.name, SUM(pmt.amount) AS total_spent
FROM packages  pkg
JOIN payments  pmt   ON pmt.id   = pkg.payment_id
JOIN customers custo ON custo.id = pkg.customer_id
WHERE pkg.shipped_at >= NOW() - INTERVAL 1 YEAR
GROUP BY custo.id, custo.name
=======
SELECT c.id, c.name, SUM(pay.amount) AS total_spent
FROM packages p
JOIN payments pay ON pay.id = p.payment_id
JOIN customers c ON c.id = p.customer_id
WHERE p.shipped_at >= NOW() - INTERVAL 1 YEAR
GROUP BY c.id, c.name
>>>>>>> bcfb806e92e4ad499bac8ece87bad6725914df8f
ORDER BY total_spent DESC
LIMIT 1;


-- 4. Street with the most customers 
SELECT addr.street, addr.city, addr.state_province, COUNT(*) AS customers
FROM customers custo
JOIN addresses addr ON addr.id = custo.address_id
GROUP BY addr.street, addr.city, addr.state_province
ORDER BY customers DESC
LIMIT 1;


-- 5. Packages not delivered within the promised time 
SELECT pkg.tracking_no, custo.name AS customer, svc.name AS service,
       pkg.expected_delivery_date, evt.event_time AS delivered_at
FROM packages  pkg
JOIN customers custo ON custo.id = pkg.customer_id
JOIN services  svc   ON svc.id   = pkg.service_code
LEFT JOIN tracking_events evt ON evt.tracking_no = pkg.tracking_no
                            AND evt.event_type   = 'DELIVERED'
WHERE evt.event_time > pkg.expected_delivery_date
   OR (evt.id IS NULL AND pkg.expected_delivery_date < NOW())
ORDER BY pkg.expected_delivery_date;


--  6. Bills for the past month 
<<<<<<< HEAD
SELECT custo.name,
       addr.street,
       addr.city, addr.state_province, addr.postal_code,
       SUM(pmt.amount) AS amount_owed
FROM packages  pkg
JOIN payments  pmt   ON pmt.id   = pkg.payment_id
JOIN customers custo ON custo.id = pkg.customer_id
JOIN addresses addr  ON addr.id  = custo.address_id
WHERE pkg.shipped_at >= '2026-06-01'
  AND pkg.shipped_at <  '2026-07-01'
GROUP BY custo.id, custo.name, addr.street,
         addr.city, addr.state_province, addr.postal_code
ORDER BY custo.name;
=======
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
>>>>>>> bcfb806e92e4ad499bac8ece87bad6725914df8f

-- 6b. Bill by type of service, with per-customer subtotals and a grand total
SELECT custo.name AS customer,
       svc.name   AS service,
       COUNT(*)        AS shipments,
<<<<<<< HEAD
       SUM(pmt.amount) AS charges
FROM packages  pkg
JOIN payments  pmt   ON pmt.id   = pkg.payment_id
JOIN services  svc   ON svc.id   = pkg.service_code
JOIN customers custo ON custo.id = pkg.customer_id
WHERE pkg.shipped_at >= '2026-06-01'
  AND pkg.shipped_at <  '2026-07-01'
GROUP BY custo.id, custo.name, svc.id, svc.name WITH ROLLUP;

-- 6c. Itemized bill: every shipment and its charge
SELECT custo.name AS customer, pkg.tracking_no, DATE(pkg.shipped_at) AS shipped,
       svc.name AS service, pkg.weight, rcpt.name AS ship_to, pmt.amount AS charge
FROM packages   pkg
JOIN payments   pmt   ON pmt.id   = pkg.payment_id
JOIN customers  custo ON custo.id = pkg.customer_id
JOIN services   svc   ON svc.id   = pkg.service_code
JOIN recipients rcpt  ON rcpt.id  = pkg.recipient_id
WHERE pkg.shipped_at >= '2026-06-01'
  AND pkg.shipped_at <  '2026-07-01'
ORDER BY custo.name, pkg.shipped_at;
=======
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
>>>>>>> bcfb806e92e4ad499bac8ece87bad6725914df8f
