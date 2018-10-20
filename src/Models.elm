module Models exposing (GameResult, GameResultState(..), GameSetup, Model(..), Msg(..), PlayerAndNumberOfValues, PreGameState(..))

import Json.Decode exposing (Decoder, field, int, map3, string)
import Model.Box exposing (Box)
import Model.Error exposing (Error(..))
import Model.Game exposing (Game)
import Model.Player exposing (Player)
import Model.User exposing (User)
import Model.Value exposing (Value)
import Time
import Uuid


type Msg
    = AddRemovePlayers
    | AddUser
    | RemoteUsers (List User)
    | AddPlayer User
    | RemovePlayer Player
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
    | CountValues
    | CountValuesTick Time.Posix
    | Restart
    | HideNotification
    | NoOp



-- type Error a b
--     = Just a b
--     | Nothing


type Model
    = PreGame GameSetup
    | Playing Game
    | PostGame GameResult


type alias GameSetup =
    { users : List User
    , currentNewPlayerName : String
    , players : List Player
    , state : PreGameState
    , error : Maybe Error
    }


type alias GameResult =
    { players : List Player
    , boxes : List Box
    , values : List Value
    , state : GameResultState
    , countedPlayers : List Player
    , countedValues : List Value
    , error : Maybe Error
    }


type GameResultState
    = GameFinished
    | ShowCountedValues
    | ShowResults


type PreGameState
    = ShowAddRemovePlayers
    | ShowGameInfo


type alias PlayerAndNumberOfValues =
    { numberOfValues : Int
    , player : Player
    }
