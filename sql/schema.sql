PRAGMA journal_mode=WAL;

CREATE TABLE IF NOT EXISTS transactions (
  id INTEGER PRIMARY KEY,
  posted_at TEXT NOT NULL,         -- ISO8601 string (UTC), e.g., 2025-10-01T09:05:00Z
  amount_cents INTEGER NOT NULL,   -- signed: negative = debit, positive = credit
  merchant TEXT NOT NULL,
  memo TEXT
);

CREATE INDEX IF NOT EXISTS idx_tx_posted_at ON transactions(posted_at);
CREATE INDEX IF NOT EXISTS idx_tx_amount    ON transactions(amount_cents);
CREATE INDEX IF NOT EXISTS idx_tx_merchant  ON transactions(merchant);
