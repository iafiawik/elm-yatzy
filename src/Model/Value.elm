module Model.Value exposing (DbValue, Value, encodeValue, valueDecoder, valuesDecoder)

import Json.Decode exposing (Decoder, bool, field, int, map3, map4, string)
import Json.Encode as E
import Model.Box exposing (Box)
import Model.Player exposing (Player)
import Model.User exposing (User)


valuesDecoder : Json.Decode.Decoder (List DbValue)
valuesDecoder =
    Json.Decode.list valueDecoder


valueDecoder : Decoder DbValue
valueDecoder =
    let
        _ =
            Debug.log "valueDecoder" ""
    in
    map4 DbValue
        (field "id" string)
        (field "boxId" string)
        (field "userId" string)
        (field "value" int)


encodeValue : Value -> E.Value
encodeValue value =
    E.object
        [ ( "id", E.string value.id )
        , ( "boxId", E.string value.box.id_ )
        , ( "userId", E.string value.player.user.id )
        , ( "value", E.int value.value )
        ]


type alias DbValue =
    { id : String
    , boxId : String
    , userId : String
    , value : Int
    }


type alias Value =
    { id : String
    , box : Box
    , player : Player
    , value : Int
    , counted : Bool
    }



-- userEncoder : User -> E.value
-- userEncoder ({ id } as user) =
--     Encode.object
--         [ ( "id", encodeOfficeId id )
--         , ( "latLng", encodeLatLon office.address.geo )
--         ]
