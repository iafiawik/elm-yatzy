module Models exposing (GameAndUserId, MarkedPlayer(..), Mode(..), Model, Msg(..))

import Json.Decode exposing (Decoder, field, int, map3, string)
import Model.Box exposing (Box)
import Model.Game exposing (DbGame, Game)
import Model.GameState exposing (GameState)
import Model.GlobalHighscore exposing (GlobalHighscore)
import Model.GlobalHighscoreItem exposing (GlobalHighscoreItem)
import Model.Player exposing (Player)
import Model.User exposing (User)
import Model.Value exposing (Value)
import Model.WindowState exposing (WindowState)
import Time


type Msg
    = ShowStartPage
    | ChangeActiveHighscoreTab Int
    | CreateGame
    | JoinExistingGame
    | EnterGame
    | ShowSelectPlayer
    | PlayerMarked Player
    | AllPlayersMarked
    | AddRemovePlayers
    | CreateUser
    | RemoteUsers (List User)
    | GameReceived Game
    | GamesReceived (List Game)
    | GlobalHighscoreReceived (List GlobalHighscore)
    | WindowFocusedReceived Game String
    | WindowBlurredReceived
    | AddPlayer User
    | RemovePlayer User
    | NewPlayerInputValueChange String
    | PlayersAdded
    | Start
    | AddValue
    | RemoveValue
    | ShowAddValue Box
    | ShowEditValue Value
    | ValueMarked Int
    | HideAddValue
    | InputValueChange String
    | GameCodeInputChange String
    | ShowGameHighscore
    | HideGameHighscore
    | HideHighscore
    | Restart
    | HideNotification
    | ShowGameInfo
    | ReloadGame
    | HideGameInfo
    | FillWithDummyValues Player
    | NoOp


type alias Model =
    { mode : Mode
    , users : List User
    , games : List Game
    , highscoreList : List GlobalHighscore
    , windowState : WindowState
    , isAdmin : Bool
    }


type Mode
    = StartPage Int
    | ShowAddRemovePlayers (List User) String
    | EnterGameCode String
    | WaitForGame Bool
    | ShowGameCode Game
    | SelectPlayer Game MarkedPlayer
    | Playing Game MarkedPlayer GameState Int Bool
    | ShowGameFinished Game MarkedPlayer
    | ShowGameResults Game MarkedPlayer
    | ShowFinishedScoreCard Game MarkedPlayer Bool


type MarkedPlayer
    = Single Player
    | All
    | NoPlayer


type alias GameAndUserId =
    { game : DbGame
    , userId : String
    }
