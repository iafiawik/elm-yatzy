module Model.Player exposing (DbPlayer, Player, encodePlayer, fromDbPlayerToPlayer, getShortNames, playerDecoder, playersDecoder)

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as E
import List.Extra exposing (last, unique)
import Model.User exposing (User, userDecoder)
import Model.Values exposing (DbValues, Values, fromDbValuesToValues, valuesDecoder)


playersDecoder : Decoder (List DbPlayer)
playersDecoder =
    Decode.list playerDecoder


playerDecoder : Decoder DbPlayer
playerDecoder =
    Decode.map2 DbPlayer
        (Decode.field "user" userDecoder)
        (Decode.field "values" valuesDecoder)


encodePlayer : Player -> E.Value
encodePlayer player =
    E.object
        [ ( "userId", E.string player.user.id ) ]


type alias Player =
    { user : User, values : Values }


type alias DbPlayer =
    { user : User, values : DbValues }


fromDbPlayerToPlayer : DbPlayer -> Player
fromDbPlayerToPlayer dbPlayer =
    let
        _ =
            Debug.log "fromDbPlayerToPlayer()"
    in
    { user = dbPlayer.user
    , values = fromDbValuesToValues dbPlayer.values
    }


getShortNames : List String -> Int -> List String
getShortNames names currentLength =
    let
        retval =
            List.map (\name -> String.slice 0 currentLength name) names

        longestName =
            Maybe.withDefault 0 (last (List.sort (List.map (\name -> String.length name) names)))

        allNamesUnique =
            List.length (unique retval) == List.length names
    in
    if allNamesUnique then
        retval

    else if currentLength >= longestName then
        names

    else
        getShortNames names (currentLength + 1)
