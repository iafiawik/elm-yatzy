module Model.Value exposing (DbValue, Value, valueDecoder, valuesDecoder)

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
    map3 DbValue
        (field "boxId" string)
        (field "userId" string)
        (field "value" int)


type alias DbValue =
    { boxId : String
    , userId : String
    , value : Int
    }


type alias Value =
    { box : Box
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
