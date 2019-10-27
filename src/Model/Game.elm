module Model.Game exposing (DbGame, Game, encodeGame, fromDbGameToGame, gameDecoder, gameResultDecoder, gamesDecoder, getBonusValue, getRoundHighscore, getTotalSum, getUpperSum, sum)

import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Field as Field
import Json.Encode as E
import Model.Box exposing (Box)
import Model.BoxCategory exposing (BoxCategory)
import Model.Error exposing (Error(..))
import Model.GameState exposing (GameState(..))
import Model.Player exposing (DbPlayer, Player, encodePlayer, fromDbPlayerToPlayer, playerDecoder, playersDecoder)
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


encodeGame : Game -> E.Value
encodeGame game =
    E.object
        [ ( "id", E.string game.id )
        , ( "code", E.string game.code )
        , ( "users", E.list encodePlayer game.players )
        , ( "finished", E.bool game.finished )
        , ( "dateCreated", E.bool game.finished )
        ]


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
    , activeUserIndex : Int
    }


fromDbGameToGame : DbGame -> Game
fromDbGameToGame dbGame =
    let
        _ =
            Debug.log "fromDbGameToGame()"
    in
    { id = dbGame.id
    , code = dbGame.code
    , finished = dbGame.finished
    , dateCreated = dbGame.dateCreated
    , activeUserIndex = dbGame.activeUserIndex
    , players = List.map (\dbPlayer -> fromDbPlayerToPlayer dbPlayer) dbGame.users
    }


sum : List number -> number
sum list =
    List.foldl (\a b -> a + b) 0 list


getUpperSum : Values -> Int
getUpperSum values =
    let
        upperValues =
            List.filter (\v -> v.box.category == Model.BoxCategory.Upper) values
    in
    sum (List.map (\v -> v.value) upperValues)


getTotalSum : Values -> Int
getTotalSum values =
    let
        countedValues =
            List.filter (\v -> v.counted == True) values

        totalSum =
            sum (List.map (\v -> v.value) countedValues)

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
