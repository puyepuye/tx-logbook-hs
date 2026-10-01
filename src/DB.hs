{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE NamedFieldPuns #-}

module DB
  ( withDb
  , initDb
  , seedDb
  , findTransactions
  , createTransaction
  , upsertTransaction
  ) where

import Control.Exception (bracket)
import Data.Char (isSpace)
import Data.List (intercalate)
import Data.Maybe (catMaybes)
import Data.String (fromString)
import Data.Text (Text)
import Database.SQLite.Simple
import Database.SQLite.Simple.FromRow

import Types

instance FromRow Transaction where
  fromRow =
    Transaction <$> field <*> field <*> field <*> field <*> field

withDb :: FilePath -> (Connection -> IO a) -> IO a
withDb fp = bracket (open fp) close

-- keep newlines; only split on literal ';'
splitOnSemicolons :: String -> [String]
splitOnSemicolons = go ""
  where
    go acc []       = [reverse acc]
    go acc (c:cs)
      | c == ';'    = reverse acc : go "" cs
      | otherwise   = go (c:acc) cs

-- Execute all statements in a file
execFile :: Connection -> FilePath -> IO ()
execFile conn fp = do
  src <- readFile fp
  let stmts = filter (not . all isSpace) (splitOnSemicolons src)
  mapM_ (\s -> execute_ conn (Query (fromString s))) stmts

initDb :: Connection -> IO ()
initDb conn = execFile conn "sql/schema.sql"

seedDb :: Connection -> IO ()
seedDb conn = execFile conn "sql/seed.sql"

-- | Dynamic SELECT with optional filters.
findTransactions
  :: Connection
  -> Maybe Text   -- q
  -> Maybe Int    -- minAmount
  -> Maybe Int    -- maxAmount
  -> Maybe Text   -- from (ISO8601 text)
  -> Maybe Text   -- to   (ISO8601 text)
  -> Int          -- limit
  -> Int          -- offset
  -> IO [Transaction]
findTransactions conn mq mMin mMax mFrom mTo lim off = do
  let base = "SELECT id, posted_at, amount_cents, merchant, memo FROM transactions"
      condsParams :: [(String, [SQLData])]
      condsParams = catMaybes
        [ fmap (\_ -> ("(merchant LIKE ? OR memo LIKE ?)", [SQLText likeq, SQLText likeq])) mq
        , fmap (\v -> ("amount_cents >= ?", [SQLInteger (fromIntegral v)])) mMin
        , fmap (\v -> ("amount_cents <= ?", [SQLInteger (fromIntegral v)])) mMax
        , fmap (\t -> ("posted_at >= ?", [SQLText t])) mFrom
        , fmap (\t -> ("posted_at <= ?", [SQLText t])) mTo
        ]
        where likeq = "%" <> maybe "" id mq <> "%"

      whereClause =
        if null condsParams then ""
        else " WHERE " <> intercalate " AND " (map fst condsParams)

      orderLimit = " ORDER BY posted_at DESC LIMIT ? OFFSET ?"
      sqlq = base <> whereClause <> orderLimit

      finalParams :: [SQLData]
      finalParams = concatMap snd condsParams ++ [SQLInteger (fromIntegral lim), SQLInteger (fromIntegral off)]

  query conn (Query (fromString sqlq)) finalParams

-- | Insert a new transaction (auto-id) and return it.
createTransaction :: Connection -> NewTransaction -> IO Transaction
createTransaction conn NewTransaction{ ntPostedAt = p
                                     , ntAmountCents = a
                                     , ntMerchant = m
                                     , ntMemo = mm
                                     } = do
  execute conn (Query $ fromString
    "INSERT INTO transactions (posted_at, amount_cents, merchant, memo) VALUES (?, ?, ?, ?)"
    ) (p, a, m, mm)
  rid <- lastInsertRowId conn
  pure $ Transaction (fromIntegral rid) p a m mm

-- | Atomically create or replace the fields of a transaction with a known ID.
-- ON CONFLICT updates the existing row without deleting it.
upsertTransaction :: Connection -> Int -> NewTransaction -> IO Transaction
upsertTransaction conn tid NewTransaction{ ntPostedAt = p
                                        , ntAmountCents = a
                                        , ntMerchant = m
                                        , ntMemo = mm
                                        } = do
  execute conn
    "INSERT INTO transactions (id, posted_at, amount_cents, merchant, memo) VALUES (?, ?, ?, ?, ?) ON CONFLICT(id) DO UPDATE SET posted_at = excluded.posted_at, amount_cents = excluded.amount_cents, merchant = excluded.merchant, memo = excluded.memo"
    (tid, p, a, m, mm)
  pure $ Transaction tid p a m mm
