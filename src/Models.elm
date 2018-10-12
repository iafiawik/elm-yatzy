module Models exposing (Box, BoxCategory(..), BoxType(..), Game(..), Model, Msg(..), Person, Player, PlayerAndNumberOfValues, Value)

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
    | ShowAddValue Box
    | ValueMarked Int
    | HideAddValue
    | InputValueChange String
    | CountValues
    | CountValuesTick Time.Posix
    | Restart


type alias Model =
    { players : List Player
    , boxes : List Box
    , values : List Value
    , game : Game
    , countedPlayers : List Player
    , countedValues : List Value
    , currentNewPlayerName : String
    , currentValue : Int
    , currentSeed : Seed
    , currentUuid : Maybe Uuid.Uuid
    }


type Game
    = Initializing
    | ShowAddRemovePlayers
    | Idle
    | Input Box
    | Finished
    | ShowCountedValues
    | ShowResults
    | Error


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
