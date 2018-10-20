module Models exposing (Box, BoxCategory(..), BoxType(..), Error(..), Game, GameResult, GameResultState(..), GameSetup, GameState(..), Model(..), Msg(..), Player, PlayerAndNumberOfValues, Value)

import Json.Decode exposing (Decoder, field, int, map3, string)
import Model.User exposing (User)
import Time
import Uuid


type Msg
    = Start
    | AddRemovePlayers
    | AddUser
    | RemoteUsers (List User)
    | AddPlayer User
    | RemovePlayer Player
    | NewPlayerInputValueChange String
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


type Error
    = NoCurrentPlayer
    | UserAlreadyExists String
    | UnableToDecodeUsers String


type Model
    = PreGame GameSetup
    | Playing Game
    | PostGame GameResult


type alias GameSetup =
    { users : List User
    , currentNewPlayerName : String
    , players : List Player
    , error : Maybe Error
    }


type alias Game =
    { players : List Player
    , boxes : List Box
    , values : List Value
    , state : GameState
    , currentValue : Int
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


type GameState
    = Idle
    | Input Box Bool


type BoxType
    = Regular Int
    | SameKind
    | Combination
    | UpperSum
    | TotalSum
    | Bonus


type BoxCategory
    = Upper
    | Lower
    | None


type alias Box =
    { id_ : String, friendlyName : String, boxType : BoxType, category : BoxCategory, order : Int }


type alias Value =
    { box : Box
    , player : Player
    , value : Int
    , counted : Bool
    }


type alias Player =
    { user : User, order : Int }


type alias PlayerAndNumberOfValues =
    { numberOfValues : Int
    , player : Player
    }
