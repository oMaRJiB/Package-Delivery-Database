CREATE FUNCTION calc_pack_cost(track_num TEXT) RETURNS REAL
DECLARE
    pkg RECORD;
    svc RECORD;
    total_cost REAL;
BEGIN
    SELECT * INTO pkg FROM packages WHERE tracking_no = track_num;
    SELECT * INTO svc FROM services WHERE id = pkg.service_code;
    total_cost := svc.base_cost + (svc.per_kg_cost * pkg.weight);
    IF pkg.is_hazardous = 1 THEN
        total_cost := total_cost + svc.hazard_surcharge;
    END IF;
    IF pkg.is_international = 1 THEN
        total_cost := total_cost + svc.intl_surcharge;
    END IF;
    RETURN total_cost;
END;

CREATE FUNCTION calc_deliver_time(track_num TEXT) RETURNS INTERVAL
DECLARE
    label_create_time DATETIME;
    deliver_time DATETIME;
BEGIN
    SELECT event_time INTO label_create_time
    FROM tracking_events 
    WHERE (tracking_no=track_num AND event_type='Label Created');

    SELECT event_time INTO label_time
    FROM tracking_events 
    WHERE (tracking_no=track_num AND event_type='Delivered');

    RETURN deliver_time-label_create_time;
END;