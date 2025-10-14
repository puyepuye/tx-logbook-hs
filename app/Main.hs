{-# LANGUAGE OverloadedStrings #-}

module Main where

import Network.Wai.Handler.Warp (run)
import Database.SQLite.Simple
import DB (withDb, initDb, seedDb)
import Api (app)
import System.IO (hPutStrLn, stderr)

main :: IO ()
main = withDb "tx.sqlite" $ \conn -> do
  initDb conn
  seedDb conn
  putStrLn "Serving on http://localhost:8080"
  run 8080 (app conn)
