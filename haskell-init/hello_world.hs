{-# LANGUAGE LambdaCase #-}

module Main where
import Control.Concurrent (threadDelay)
import Control.Monad (forever)
import System.Posix.Directory
import System.Directory
import Data.Char
import Data.List.Split
import Control.Monad.State
import System.Linux.Mount

data AppState = AppState { running :: Bool } deriving (Eq, Show, Read)

ls :: String -> IO ()
ls arg1 = mapM_ print =<< getDirectoryContents arg1

type Repl = StateT AppState IO

keepRunning :: Bool -> Repl ()
keepRunning b = modify $ \m -> m { running = b }

eval :: [String] -> Repl ()
eval ("ls" : arg1 : rest) = do
  liftIO $ ls arg1
eval ("ls" : rest) = do
  liftIO $ ls "."
eval ("quit":rest) = do
  keepRunning False
eval _  = do
  liftIO $ putStrLn "unknown command"

defaultMain :: Repl () -> IO ()
defaultMain repl = do
  mount "devtmpfs" "/dev" "devtmpfs" [] noData
  mount "proc" "/proc" "proc" [] noData
  mount "sysfs" "/sys" "sysfs" [] noData
  putStrLn "booted"
  flip evalStateT initialState repl
    where
      initialState = AppState True

main = defaultMain $ fix $ \loop ->
  running <$> get >>= \case
    False -> liftIO $ putStrLn "Exiting"
    True -> do
      liftIO $ putStr "> "
      line <- splitOn " " <$> liftIO getLine
      eval line >> loop
