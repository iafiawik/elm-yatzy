module Model.Value exposing (DbValue, Value, encodeValue, encodeValues, valueDecoder, valuesDecoder)

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as E
import Model.Box exposing (Box)
import Model.Player exposing (Player)
import Model.User exposing (User)


valuesDecoder : Decoder (List DbValue)
valuesDecoder =
    Decode.list valueDecoder


valueDecoder : Decoder DbValue
valueDecoder =
    Decode.map4 DbValue
        (Decode.field "id" Decode.string)
        (Decode.field "boxId" Decode.string)
        (Decode.field "userId" Decode.string)
        (Decode.field "value" Decode.int)


encodeValue : Value -> E.Value
encodeValue value =
    E.object
        [ ( "id", E.string value.id )
        , ( "boxId", E.string value.box.id )
        , ( "userId", E.string value.player.user.id )
        , ( "value", E.int value.value )
        ]


encodeValues : List Value -> List E.Value
encodeValues values =
    List.map
        (\value ->
            E.object
                [ ( "id", E.string value.id )
                , ( "boxId", E.string value.box.id )
                , ( "userId", E.string value.player.user.id )
                , ( "value", E.int value.value )
                ]
        )
        values


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
    , new : Bool
    }



-- userEncoder : User -> E.value
-- userEncoder ({ id } as user) =
--     Encode.object
--         [ ( "id", encodeOfficeId id )
--         , ( "latLng", encodeLatLon office.address.geo )
--         ]
