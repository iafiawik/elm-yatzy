module Model.Value exposing (DbValue, Value, encodeValue, fromDbValueToValue, valueDecoder)

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as E
import Model.Box exposing (Box, getBoxById)


valueDecoder : Decoder DbValue
valueDecoder =
    Decode.map2 DbValue
        (Decode.field "c" Decode.int)
        (Decode.field "v" Decode.int)


encodeValue : Value -> E.Value
encodeValue value =
    E.object
        [ ( "c", E.int value.createdAt )
        , ( "v", E.int value.value )
        ]


type alias DbValue =
    { v : Int
    , c : Int
    }


type alias Value =
    { value : Int
    , createdAt : Int
    , box : Box
    , counted : Bool
    }


fromDbValueToValue : ( String, DbValue ) -> Value
fromDbValueToValue dbValueTuple =
    let
        _ =
            Debug.log "fromDbValueToValue()"

        dbValue =
            Tuple.second dbValueTuple

        boxId =
            Tuple.first dbValueTuple
    in
    { value = dbValue.v
    , createdAt = dbValue.c
    , box = getBoxById boxId
    , counted = False
    }
