module Model.Player exposing (Player, encodePlayer, playerDecoder, playersDecoder)

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as E
import Model.User exposing (User, userDecoder)


playersDecoder : Decoder (List Player)
playersDecoder =
    Decode.list playerDecoder


playerDecoder : Decoder Player
playerDecoder =
    Decode.map2 Player
        (Decode.field "user" userDecoder)
        (Decode.field "order" Decode.int)


encodePlayer : Player -> E.Value
encodePlayer player =
    E.object
        [ ( "userId", E.string player.user.id ), ( "order", E.int player.order ) ]


type alias Player =
    { user : User, order : Int }
