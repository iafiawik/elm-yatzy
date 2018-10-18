module Models exposing (Box, BoxCategory(..), BoxType(..), Error(..), Game(..), Model, Msg(..), Person, Player, PlayerAndNumberOfValues, Value)

import Model.User exposing (User)
import Random exposing (Seed, initialSeed, step)
import Time
import Uuid


type Msg
    = Start
    | AddRemovePlayers
    | AddPlayer
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



-- type Error a b
--     = Just a b
--     | Nothing


type Error
    = NoCurrentPlayer
    | UnableToDecodeUsers String


type alias Model =
    { players : List Player
    , users : List User
    , boxes : List Box
    , values : List Value
    , game : Game
    , countedPlayers : List Player
    , countedValues : List Value
    , currentNewPlayerName : String
    , currentValue : Int
    , currentSeed : Seed
    , currentUuid : Maybe Uuid.Uuid
    , error : Maybe Error
    }


type Game
    = Initializing
    | ShowAddRemovePlayers
    | Idle
    | Input Box Bool
    | Finished
    | ShowCountedValues
    | ShowResults


type alias Person =
    { name : String }


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
    { id_ : String, name : String, order : Int }


type alias PlayerAndNumberOfValues =
    { numberOfValues : Int
    , player : Player
    }
