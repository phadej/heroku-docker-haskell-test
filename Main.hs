{-# LANGUAGE TemplateHaskell #-}
module Main where

import Control.Applicative
import Data.String
import Network.HTTP.Types (status200)
import Network.Wai
import Network.Wai.Application.Static
import Network.Wai.Handler.Warp
import Network.Waitra
import Network.Waitra.Embedded
import System.Environment (lookupEnv)
import Text.Regex.Applicative

echoRoute :: Route
echoRoute = routeGet (echoApp <$ string "/api/echo/" <*> many anySym)
  where echoApp msg _req respond = respond $ responseLBS status200 [] (fromString msg)

app :: Application
app = waitraMiddleware [echoRoute] $ staticApp $ embeddedSettings $(mkRecursiveEmbedded "static")

main :: IO ()
main = do
  port <- maybe 8000 read <$> lookupEnv "PORT"
  run port app

