module Model.Value exposing (DbValue, Value, encodeValue, fromDbValueToValue, valueDecoder)

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as E
import Model.Box exposing (Box, getBoxById)


valueDecoder : Decoder DbValue
valueDecoder =
    Decode.map2 DbValue
        (Decode.field "v" Decode.int)
        (Decode.field "c" Decode.int)


encodeValue : Value -> E.Value
encodeValue value =
    E.object
        [ ( "v", E.int value.value )
        , ( "c", E.int value.dateCreated )
        ]


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
