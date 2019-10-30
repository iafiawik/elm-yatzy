module Model.Values exposing (DbValues, Values, fromDbValuesToValues, valuesDecoder)

import Dict exposing (Dict)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as E
import Model.Box exposing (Box)
import Model.User exposing (User)
import Model.Value exposing (DbValue, Value, fromDbValueToValue, valueDecoder)


valuesDecoder : Decoder (Dict String DbValue)
valuesDecoder =
    Decode.dict valueDecoder


type alias DbValues =
    Dict String DbValue


type alias Values =
    List Value


fromDbValuesToValues : DbValues -> Bool -> Values
fromDbValuesToValues dbValues wasPreviousActivePlayer =
    updateValues (Dict.toList dbValues) wasPreviousActivePlayer


flippedComparison : ( String, DbValue ) -> ( String, DbValue ) -> Order
flippedComparison a b =
    let
        valueA =
            Tuple.second a

        valueB =
            Tuple.second b
    in
    case compare valueA.c valueB.c of
        LT ->
            GT

        EQ ->
            EQ

        GT ->
            LT


updateValues : List ( String, DbValue ) -> Bool -> List Value
updateValues dbValues wasPreviousActivePlayer =
    let
        sortedByNewest =
            if wasPreviousActivePlayer then
                List.sortWith flippedComparison dbValues

            else
                dbValues
    in
    List.indexedMap
        (\index v ->
            let
                value : Value
                value =
                    fromDbValueToValue v
            in
            { value | new = index == 0 }
        )
        sortedByNewest
