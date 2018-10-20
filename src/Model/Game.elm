module Model.Game exposing (Game, gameDecoder, gamesDecoder)

import Json.Decode exposing (Decoder, field, int, list, map3, map4, string)
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
    map4 DbGame
        (field "id" string)
        (field "users" (list string))
        (field "values" valuesDecoder)
        (field "dateStarted" string)


type alias DbGame =
    { id : String
    , users : List String
    , values : List DbValue
    , dateStarted : String
    }


type alias Game =
    { players : List Player
    , boxes : List Box
    , values : List Value
    , state : GameState
    , currentValue : Int
    , error : Maybe Error
    }



-- userEncoder : User -> E.value
-- userEncoder ({ id } as user) =
--     Encode.object
--         [ ( "id", encodeOfficeId id )
--         , ( "latLng", encodeLatLon office.address.geo )
--         ]
