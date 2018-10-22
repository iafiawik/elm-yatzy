module Views.SelectPlayer exposing (selectPlayer)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Html.Keyed as Keyed
import Model.Game exposing (Game)
import Model.Player as Player
import Model.User as User
import Models exposing (Msg(..))


playerButtons : List Player.Player -> Player.Player -> Html Msg
playerButtons players markedPlayer =
    let
        buttons =
            List.map (\player -> button [ classList [ ( "select-player-button", True ), ( "selected", markedPlayer.user.id == player.user.id ) ], onClick (PlayerMarked player) ] [ text player.user.name ]) players
    in
    div [] buttons


selectPlayer : Game -> Player.Player -> Html Msg
selectPlayer game markedPlayer =
    div [ class "dialog-wrapper" ]
        [ div [ class "dialog-background  animated fadeIn" ] []
        , div [ class "select-player dialog-content animated jackInTheBox" ]
            [ h1 [] [ text "Vem är du?" ]
            , h2 [] [ text "välj ditt namn nedan" ]
            , div [] [ playerButtons game.players markedPlayer ]
            , button [ classList [ ( "large-button add-players-dialog-start-button", True ), ( "enabled", markedPlayer.user.id /= "" ) ], onClick Start ] [ text "Start" ]
            ]
        ]
