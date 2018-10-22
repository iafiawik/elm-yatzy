module Model.Player exposing (Player, encodePlayer, playerDecoder, playersDecoder)

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


encodePlayer : Player -> E.Value
encodePlayer player =
    E.object
        [ ( "userId", E.string player.user.id ), ( "order", E.int player.order ) ]


type alias Player =
    { user : User, order : Int }



--
-- playerDecoder : Decoder DbPlayer
-- playerDecoder =
--     map2 DbPlayer
--         (field "user" userDecoder)
--         (field "order" int)
--
-- type alias DbPlayer =
--     { user : User
--     , order : Int
--     }
-- userEncoder : User -> E.value
-- userEncoder ({ id } as user) =
--     Encode.object
--         [ ( "id", encodeOfficeId id )
--         , ( "latLng", encodeLatLon office.address.geo )
--         ]
