module Model.StatisticItem exposing (StatisticItem, statisticItemDecoder, statisticItemsDecoder)

import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Field as Field
import Model.User exposing (User, userDecoder)


statisticItemsDecoder : Decoder (List StatisticItem)
statisticItemsDecoder =
    Decode.list statisticItemDecoder


statisticItemDecoder : Decoder StatisticItem
statisticItemDecoder =
    Decode.map7 StatisticItem
        (Decode.field "user" userDecoder)
        (Decode.field "average" Decode.float)
        (Decode.field "lowestScore" Decode.int)
        (Decode.field "highestScore" Decode.int)
        (Decode.field "numberOfGames" Decode.int)
        (Decode.field "yatzyChance" Decode.float)
        (Decode.field "winChance" Decode.float)


type alias StatisticItem =
    { user : User
    , average : Float
    , highestScore : Int
    , lowestScore : Int
    , numberOfGames : Int
    , yatzyChance : Float
    , winChance : Float
    }
