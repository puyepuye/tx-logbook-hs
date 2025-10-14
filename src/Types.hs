{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}

module Types where

import Data.Aeson
  ( ToJSON
  , FromJSON(..)        -- <-- note the (..) to bring parseJSON into scope
  , defaultOptions
  , genericParseJSON
  )
import Data.Aeson.Types (Options(..))
import Data.Char (toLower)
import Data.Text (Text)
import GHC.Generics (Generic)

-- DB row / response payload
data Transaction = Transaction
  { id_          :: Int
  , postedAt     :: Text
  , amountCents  :: Int
  , merchant     :: Text
  , memo         :: Maybe Text
  } deriving (Show, Generic)

instance ToJSON Transaction

-- Request payload for PUT/POST (distinct field names to avoid clashes)
data NewTransaction = NewTransaction
  { ntPostedAt    :: Text
  , ntAmountCents :: Int
  , ntMerchant    :: Text
  , ntMemo        :: Maybe Text
  } deriving (Show, Generic)

-- Map JSON keys "postedAt"/"amountCents"/"merchant"/"memo" -> ntPostedAt/...
instance FromJSON NewTransaction where
  parseJSON = genericParseJSON defaultOptions
    { fieldLabelModifier = \s ->
        case drop 2 s of  -- drop the "nt" prefix
          (c:cs) -> toLower c : cs
          []     -> []
    }
