module Model.GlobalHighscoreItem exposing (GlobalHighscoreItem, globalHighscoreItemDecoder, globalHighscoreItemsDecoder)

import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Field as Field
import Json.Encode as E
import Model.Game exposing (DbGame, Game, gameDecoder)
import Model.Player exposing (Player, playerDecoder)
import Model.User exposing (User, userDecoder)


globalHighscoreItemsDecoder : Decoder (List GlobalHighscoreItem)
globalHighscoreItemsDecoder =
    Decode.list globalHighscoreItemDecoder


globalHighscoreItemDecoder : Decoder GlobalHighscoreItem
globalHighscoreItemDecoder =
    Decode.map5 GlobalHighscoreItem
        (Decode.field "date" Decode.string)
        (Decode.field "gameId" Decode.string)
        (Decode.field "order" Decode.int)
        (Decode.field "score" Decode.int)
        (Decode.field "user" userDecoder)


type alias GlobalHighscoreItem =
    { date : String
    , gameId : String
    , order : Int
    , score : Int
    , user : User
    }
