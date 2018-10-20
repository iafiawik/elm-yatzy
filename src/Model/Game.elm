module Model.Game exposing (DbGame, Game, encodeGame, gameDecoder, gamesDecoder)

import Json.Decode exposing (Decoder, field, int, list, map2, map3, map4, string)
import Json.Encode as E
import Model.Box exposing (Box)
import Model.Error exposing (Error(..))
import Model.GameState exposing (GameState(..))
import Model.Player exposing (Player, playersDecoder)
import Model.Value exposing (DbValue, Value, valuesDecoder)


gamesDecoder : Json.Decode.Decoder (List DbGame)
gamesDecoder =
    Json.Decode.list gameDecoder


gameDecoder : Decoder DbGame
gameDecoder =
    let
        _ =
            Debug.log "userDecoder" ""
    in
    map3 DbGame
        (field "id" string)
        (field "code" string)
        (field "users" (Json.Decode.list string))


encodeGame : Game -> E.Value
encodeGame game =
    let
        users =
            List.map (\p -> p.user.id) game.players
    in
    E.object
        [ ( "id", E.string game.id )
        , ( "code", E.string game.code )
        , ( "users", E.list E.string users )
        ]


type alias DbGame =
    { id : String
    , code : String
    , users : List String
    }


type alias Game =
    { id : String
    , code : String
    , players : List Player
    , values : List Value
    }



-- userEncoder : User -> E.value
-- userEncoder ({ id } as user) =
--     Encode.object
--         [ ( "id", encodeOfficeId id )
--         , ( "latLng", encodeLatLon office.address.geo )
--         ]
