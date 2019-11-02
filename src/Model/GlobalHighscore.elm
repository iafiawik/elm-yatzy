module Model.GlobalHighscore exposing (GlobalHighscore, globalHighscoresDecoder)

import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Field as Field
import Model.GlobalHighscoreItem exposing (GlobalHighscoreItem, globalHighscoreItemDecoder)


globalHighscoresDecoder : Decoder (List GlobalHighscore)
globalHighscoresDecoder =
    Decode.list globalHighscoreDecoder


globalHighscoreDecoder : Decoder GlobalHighscore
globalHighscoreDecoder =
    Decode.map3 GlobalHighscore
        (Decode.field "year" Decode.int)
        (Decode.field "normal" (Decode.list globalHighscoreItemDecoder))
        (Decode.field "inverted" (Decode.list globalHighscoreItemDecoder))


type alias GlobalHighscore =
    { year : Int
    , normal : List GlobalHighscoreItem
    , inverted : List GlobalHighscoreItem
    }
