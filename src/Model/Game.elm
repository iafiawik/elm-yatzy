module Model.Game exposing (DbGame, Game, fromDbGameToGame, gameDecoder, gamesDecoder, getActivePlayer, getBonusValue, getRoundHighscore, getTotalSum, getUpperSum, getValueByPlayerAndBox, sum)

import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Field as Field
import Json.Encode as E
import List.Extra exposing (find, getAt, last)
import Model.Box exposing (Box)
import Model.BoxCategory exposing (BoxCategory)
import Model.Error exposing (Error(..))
import Model.GameState exposing (GameState(..))
import Model.Player exposing (DbPlayer, Player, fromDbPlayerToPlayer, playerDecoder, playersDecoder)
import Model.User exposing (User, userDecoder)
import Model.Value exposing (Value, valueDecoder)
import Model.Values exposing (Values, valuesDecoder)


gamesDecoder : Decoder (List DbGame)
gamesDecoder =
    Decode.list gameDecoder


gameDecoder : Decoder DbGame
gameDecoder =
    Decode.map6 DbGame
        (Decode.field "id" Decode.string)
        (Decode.field "code" Decode.string)
        (Decode.field "users" (Decode.list playerDecoder))
        (Decode.field "finished" Decode.bool)
        (Decode.field "dateCreated" Decode.string)
        (Decode.field "activeUserIndex" Decode.int)


type alias DbGame =
    { id : String
    , code : String
    , users : List DbPlayer
    , finished : Bool
    , dateCreated : String
    , activeUserIndex : Int
    }


type alias Game =
    { id : String
    , code : String
    , players : List Player
    , finished : Bool
    , dateCreated : String
    , activePlayer : Player
    }


fromDbGameToGame : DbGame -> List User -> Game
fromDbGameToGame dbGame users =
    let
        _ =
            Debug.log "fromDbGameToGame()" (Debug.toString dbGame)

        players =
            List.map (\dbPlayer -> fromDbPlayerToPlayer dbPlayer users) dbGame.users
    in
    { id = dbGame.id
    , code = dbGame.code
    , finished = dbGame.finished
    , dateCreated = dbGame.dateCreated
    , activePlayer = getActivePlayer dbGame.activeUserIndex players
    , players = players
    }


sum : List number -> number
sum list =
    List.foldl (\a b -> a + b) 0 list


getUpperSum : Values -> Int
getUpperSum values =
    let
        _ =
            Debug.log "getUpperSum" (Debug.toString values)

        upperValues =
            List.filter (\v -> v.box.category == Model.BoxCategory.Upper && v.value /= -1) values
    in
    sum (List.map (\v -> v.value) upperValues)


getTotalSum : Values -> Int
getTotalSum values =
    let
        totalSum =
            sum (List.map (\v -> v.value) values)

        bonusValue =
            getBonusValue values
    in
    totalSum + bonusValue


getBonusValue : Values -> Int
getBonusValue values =
    let
        upperSum =
            getUpperSum values
    in
    if upperSum >= 63 then
        50

    else
        0


getValueByPlayerAndBox : Values -> Box -> Maybe Value
getValueByPlayerAndBox values box =
    List.head
        (List.filter
            (\v ->
                v.box == box && v.value /= -1
            )
            values
        )


getRoundHighscore : List Player -> List ( Player, Int )
getRoundHighscore players =
    let
        playerValues =
            List.map (\player -> ( player, getTotalSum player.values )) players

        sortedPlayers =
            sortTupleBySecond playerValues

        --
        -- _ =
        --     Debug.log "sortedPlayers" sortedPlayers
    in
    sortedPlayers


sortTupleBySecond : List ( a, comparable ) -> List ( a, comparable )
sortTupleBySecond =
    (\f lst ->
        List.sortWith (\a b -> compare (f b) (f a)) lst
    )
        Tuple.second


getActivePlayer : Int -> List Player -> Player
getActivePlayer index players =
    Maybe.withDefault { user = { id = "", name = "", userName = "" }, values = [] } (getAt index players)
