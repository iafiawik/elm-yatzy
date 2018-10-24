module Model.Game exposing (DbGame, Game, encodeGame, gameDecoder, gameResultDecoder, gamesDecoder)

import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Field as Field
import Json.Encode as E
import Model.Box exposing (Box)
import Model.Error exposing (Error(..))
import Model.GameState exposing (GameState(..))
import Model.Player exposing (Player, encodePlayer, playerDecoder, playersDecoder)
import Model.User exposing (User, userDecoder)
import Model.Value exposing (DbValue, Value, valuesDecoder)


gamesDecoder : Decoder (List DbGame)
gamesDecoder =
    Decode.list gameDecoder


gameDecoder : Decoder DbGame
gameDecoder =
    Decode.map4 DbGame
        (Decode.field "id" Decode.string)
        (Decode.field "code" Decode.string)
        (Decode.field "users" (Decode.list playerDecoder))
        (Decode.field "finished" Decode.bool)


gameResultDecoder : Decoder GameResult
gameResultDecoder =
    Field.require "result" Decode.string <|
        \result ->
            Field.require "game" gameDecoder <|
                \game ->
                    if result /= "ok" then
                        Decode.fail "You must be an adult"

                    else
                        Decode.succeed
                            { result = result
                            , game = game
                            }


type alias GameResult =
    { result : String
    , game : DbGame
    }



-- `list` takes two parameters, the first is a function to convert one element to a `Value` the second is the list of things to convert (


encodeGame : Game -> E.Value
encodeGame game =
    let
        users =
            List.map (\p -> encodePlayer p) game.players
    in
    E.object
        [ ( "id", E.string game.id )
        , ( "code", E.string game.code )
        , ( "users", E.list encodePlayer game.players )
        , ( "finished", E.bool game.finished )
        ]


type alias DbGame =
    { id : String
    , code : String
    , users : List Player
    , finished : Bool
    }


type alias Game =
    { id : String
    , code : String
    , players : List Player
    , values : List Value
    , finished : Bool
    }



-- userEncoder : User -> E.value
-- userEncoder ({ id } as user) =
--     Encode.object
--         [ ( "id", encodeOfficeId id )
--         , ( "latLng", encodeLatLon office.address.geo )
--         ]
