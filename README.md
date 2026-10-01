# (Haskell + SQLite Transaction Log (POST) + Search API)

A tiny Servant API that searches transactions with filters and pagination.
**Tech:** Haskell (Servant, Warp), SQLite (sqlite-simple).

##### Wrote this out of curiosity to learn more about haskell and also combine concepts from CSC324: Intro to Programming Language (+ Haskell) and CSC343: Intro to Databases.

## Endpoints

### GET /transactions
**Query parameters:**
- `q` — text search over `merchant` and `memo` (SQL LIKE)
- `minAmount` — minimum `amount_cents` (integer, cents)
- `maxAmount` — maximum `amount_cents` (integer, cents)
- `from` — start of date/time range (ISO8601 string, e.g., `2025-10-01T00:00:00Z`)
- `to` — end of date/time range (ISO8601 string)
- `limit` — page size (default 25, max 100)
- `offset` — page offset (default 0)

### PUT /transactions/{id}
Create **or** replace a transaction with a specific ID (idempotent logging).

**Body (JSON):**
```json
{
  "postedAt": "2025-10-13T21:30:00Z",
  "amountCents": -1450,
  "merchant": "Blue Bottle Coffee",
  "memo": "night latte"
}
```

**Response:** the full `Transaction` JSON after upsert.

## Run (Stack)
```bash
stack setup
stack build
stack run
# -> Serving on http://localhost:8080
```

## Examples
```bash
# List / search
curl "http://localhost:8080/transactions"
curl "http://localhost:8080/transactions?q=Blue%20Bottle"
curl "http://localhost:8080/transactions?minAmount=-5000&maxAmount=-1000"
curl "http://localhost:8080/transactions?from=2025-10-01T00:00:00Z&to=2025-10-07T23:59:59Z"
curl "http://localhost:8080/transactions?limit=2&offset=2"

# create a new transaction (auto-generated id)
curl -X POST "http://localhost:8080/transactions" \
-H "Content-Type: application/json" \
-d '{"postedAt":"2025-10-13T21:30:00Z","amountCents":-1450,"merchant":"Blue Bottle Coffee","memo":"night latte"}'
```


## Build and run with Cabal
```bash
cabal update
cabal build
cabal run tx-search
# -> Serving on http://localhost:8080
```
