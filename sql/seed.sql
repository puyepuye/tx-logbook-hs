DELETE FROM transactions;

INSERT INTO transactions (posted_at, amount_cents, merchant, memo) VALUES
('2025-09-28T13:22:00Z', -1299, 'Blue Bottle Coffee', 'latte + croissant'),
('2025-10-01T09:05:00Z', -5599, 'Air Canada', 'YYZ→SFO'),
('2025-10-02T11:14:00Z',  2500, 'Reimbursement', 'conference lunch'),
('2025-10-05T20:45:00Z', -2199, 'Uber', 'airport'),
('2025-10-06T12:00:00Z', -8999, 'Apple', 'AirPods'),
('2025-10-07T16:10:00Z', -3500, 'Blue Bottle Coffee', 'beans'),
('2025-10-10T08:30:00Z', -1200, 'Tim Hortons', 'double double');
