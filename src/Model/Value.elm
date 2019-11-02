module Model.Value exposing (DbValue, Value, fromDbValueToValue, valueDecoder)

import Json.Decode as Decode exposing (Decoder)
import Model.Box exposing (Box, getBoxById)


valueDecoder : Decoder DbValue
valueDecoder =
    Decode.map2 DbValue
        (Decode.field "v" Decode.int)
        (Decode.field "c" Decode.int)


type alias DbValue =
    { v : Int
    , c : Int
    }


type alias Value =
    { value : Int
    , dateCreated : Int
    , box : Box
    , new : Bool
    }


fromDbValueToValue : ( String, DbValue ) -> Value
fromDbValueToValue dbValueTuple =
    let
        dbValue =
            Tuple.second dbValueTuple

        boxId =
            Tuple.first dbValueTuple
    in
    { value = dbValue.v
    , dateCreated = dbValue.c
    , box = getBoxById boxId
    , new = False
    }
