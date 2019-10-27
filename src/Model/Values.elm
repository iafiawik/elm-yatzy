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


fromDbValuesToValues : DbValues -> Values
fromDbValuesToValues dbValues =
    let
        _ =
            Debug.log "fromDbValuesToValues()"
    in
    List.map (\dbValue -> fromDbValueToValue dbValue) (Dict.toList dbValues)
