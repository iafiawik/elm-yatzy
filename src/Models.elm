module Models exposing (Box, BoxCategory(..), BoxType(..), Person, Player, PlayerAndNumberOfValues, Value)


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
    { id_ : String, friendlyName : String, boxType : BoxType, category : BoxCategory }


type alias Value =
    { box : Box
    , player : Player
    , value : Int
    }


type alias Player =
    { id_ : Int, name : String }


type alias PlayerAndNumberOfValues =
    { numberOfValues : Int
    , player : Player
    , playerId : Int
    }
