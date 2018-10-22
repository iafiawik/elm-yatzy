module Models exposing (GamePlaying, GameResult, GameResultState(..), GameSetup, GroupModel(..), IndividualModel(..), Mode(..), Model(..), Msg(..), PlayerAndNumberOfValues, PreGameState(..))

import Json.Decode exposing (Decoder, field, int, map3, string)
import Model.Box exposing (Box)
import Model.Error exposing (Error(..))
import Model.Game exposing (DbGame, Game)
import Model.GameState exposing (GameState)
import Model.Player exposing (Player)
import Model.User exposing (User)
import Model.Value exposing (DbValue, Value)
import Time
import Uuid


type Msg
    = SelectGroup
    | SelectIndividual
    | EnterGame
    | AddRemovePlayers
    | AddUser
    | RemoteUsers (List User)
    | RemoteValuesReceived (List DbValue)
    | GameReceived DbGame
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
    | GameCodeInputChange String
    | CountValues
    | CountValuesTick Time.Posix
    | Restart
    | HideNotification
    | NoOp



-- type Error a b
--     = Just a b
--     | Nothing


type Model
    = SelectedMode Mode (List User)


type Mode
    = SelectMode
    | Individual IndividualModel
    | Group GroupModel


type IndividualModel
    = EnterGameCode String
    | WaitingForGame
    | SelectPlayer GamePlaying
    | IndividualPlaying GamePlaying


type GroupModel
    = PreGame GameSetup
    | Playing GamePlaying
    | PostGame GameResult


type alias GameSetup =
    { users : List User
    , currentNewPlayerName : String
    , state : PreGameState
    , error : Maybe Error
    , game : Game
    }


type alias GamePlaying =
    { game : Game
    , boxes : List Box
    , state : GameState
    , currentValue : Int
    , error : Maybe Error
    }


type alias GameResult =
    { game : Game
    , boxes : List Box
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
