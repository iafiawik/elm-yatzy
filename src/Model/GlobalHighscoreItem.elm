module Model.GlobalHighscoreItem exposing (GlobalHighscoreItem, globalHighscoreItemDecoder, globalHighscoreItemsDecoder)

import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Field as Field
import Json.Encode as E
import Model.Game exposing (DbGame, Game, gameDecoder)
import Model.Player exposing (Player, playerDecoder)


globalHighscoreItemsDecoder : Decoder (List GlobalHighscoreItem)
globalHighscoreItemsDecoder =
    Decode.list globalHighscoreItemDecoder


globalHighscoreItemDecoder : Decoder GlobalHighscoreItem
globalHighscoreItemDecoder =
    Decode.map2 GlobalHighscoreItem
        (Decode.field "game" gameDecoder)
        (Decode.field "user" playerDecoder)


type alias GlobalHighscoreItem =
    { game : DbGame
    , player : Player
    }
