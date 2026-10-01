{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE OverloadedStrings #-}

module Api (app) where

import Control.Monad.IO.Class (liftIO)
import Data.Maybe (fromMaybe)
import Data.Text (Text)
import Network.Wai (Application)
import Servant
import Database.SQLite.Simple (Connection)

import DB (findTransactions, createTransaction, upsertTransaction)
import Types

type API =
       "transactions"
         :> QueryParam "q" Text
         :> QueryParam "minAmount" Int
         :> QueryParam "maxAmount" Int
         :> QueryParam "from" Text
         :> QueryParam "to" Text
         :> QueryParam "limit" Int
         :> QueryParam "offset" Int
         :> Get '[JSON] [Transaction]
  :<|> "transactions"
         :> ReqBody '[JSON] NewTransaction
         :> PostCreated '[JSON] Transaction
  :<|> "transactions"
         :> Capture "id" Int
         :> ReqBody '[JSON] NewTransaction
         :> Put '[JSON] Transaction

server :: Connection -> Server API
server conn =
  -- GET /transactions
  (\mq mMin mMax mFrom mTo mLim mOff -> do
     let lim = clamp 1 100 (fromMaybe 25 mLim)
         off = max 0 (fromMaybe 0 mOff)
     liftIO $ findTransactions conn mq mMin mMax mFrom mTo lim off
  )
  -- POST /transactions (auto-id)
  :<|> (\body -> liftIO $ createTransaction conn body)
  :<|> (\tid body -> liftIO $ upsertTransaction conn tid body)
  where
    clamp lo hi x = max lo (min hi x)

api :: Proxy API
api = Proxy

app :: Connection -> Application
app conn = serve api (server conn)
