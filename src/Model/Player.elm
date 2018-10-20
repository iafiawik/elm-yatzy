module Model.Player exposing (Player, playerDecoder, playersDecoder)

import Json.Decode exposing (Decoder, field, int, map2, string)
import Json.Encode as E
import Model.User exposing (User, userDecoder)


playersDecoder : Json.Decode.Decoder (List Player)
playersDecoder =
    Json.Decode.list playerDecoder


playerDecoder : Decoder Player
playerDecoder =
    let
        _ =
            Debug.log "userDecoder" ""
    in
    map2 Player
        (field "user" userDecoder)
        (field "order" int)


type alias Player =
    { user : User, order : Int }



-- userEncoder : User -> E.value
-- userEncoder ({ id } as user) =
--     Encode.object
--         [ ( "id", encodeOfficeId id )
--         , ( "latLng", encodeLatLon office.address.geo )
--         ]
