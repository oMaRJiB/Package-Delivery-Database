CREATE INDEX idx_customers_address_id ON customers(address_id);

CREATE INDEX idx_accounts_customer_id ON accounts(customer_id);

CREATE INDEX idx_invoices_account_id ON invoices(account_id);

CREATE INDEX idx_account_charges_payment_id ON account_charges(payment_id);
CREATE INDEX idx_account_charges_invoice_id ON account_charges(invoice_id);

CREATE INDEX idx_prepaid_labels_payment_id ON prepaid_labels(payment_id);

CREATE INDEX idx_recipients_address_id ON recipients(address_id);

CREATE INDEX idx_te_pkg_time  ON tracking_events (tracking_no, event_time);
CREATE INDEX idx_te_loc_time  ON tracking_events (location_id, event_time);
CREATE INDEX idx_pkg_shipped  ON packages (customer_id, shipped_at);
CREATE INDEX idx_pkg_expected ON packages (expected_delivery_date);
CREATE INDEX idx_addr_street  ON addresses (street, city, state_province);
CREATE INDEX idx_pay_time     ON payments (payment_time);

CREATE INDEX idx_customs_declarations_tracking_no ON customs_declarations(tracking_no);

CREATE INDEX idx_customs_items_declaration_id ON customs_items(declaration_id);

CREATE INDEX idx_warehouses_location_id ON warehouses(location_id);
CREATE INDEX idx_warehouses_address_id ON warehouses(address_id);

CREATE INDEX idx_trucks_location_id ON trucks(location_id);

CREATE INDEX idx_planes_location_id ON planes(location_id);

CREATE INDEX idx_tracking_events_tracking_no ON tracking_events(tracking_no);
CREATE INDEX idx_tracking_events_location_id ON tracking_events(location_id);

CREATE INDEX idx_deliveries_event_id ON deliveries(event_id);