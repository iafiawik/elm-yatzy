module Views.SelectPlayer exposing (selectPlayer)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Html.Keyed as Keyed
import Model.Game exposing (Game)
import Model.Player as Player
import Model.User as User
import Models exposing (Msg(..))


playerButton : Player.Player -> Bool -> Html Msg
playerButton player isMarked =
    button [ classList [ ( "select-player-button", True ), ( "selected", isMarked ) ], onClick (PlayerMarked [ player ]) ] [ text player.user.name ]


isPlayerMarked : Player.Player -> List Player.Player -> Bool
isPlayerMarked player markedPlayers =
    if List.length markedPlayers == 1 then
        case List.head markedPlayers of
            Just markedPlayer ->
                markedPlayer.user.id == player.user.id

            Nothing ->
                False

    else
        False


playerButtons : List Player.Player -> List Player.Player -> Html Msg
playerButtons players markedPlayers =
    let
        buttons =
            List.map (\player -> playerButton player (isPlayerMarked player markedPlayers)) players
    in
    div [] buttons


selectPlayer : Game -> List Player.Player -> Html Msg
selectPlayer game markedPlayers =
    let
        isAllSelected =
            List.length markedPlayers /= 1 && List.length markedPlayers > 0
    in
    div [ class "dialog-wrapper" ]
        [ div [ class "dialog-background  animated fadeIn" ] []
        , div [ class "select-player dialog-content animated jackInTheBox" ]
            [ h1 [] [ text "Vem är du?" ]
            , h2 [] [ text "välj ditt namn nedan:" ]
            , div [] [ playerButtons game.players markedPlayers ]
            , h2 [] [ text "... eller välj att spela alla spelare:" ]
            , div [] [ button [ onClick (PlayerMarked game.players), classList [ ( "select-player-button", True ), ( "selected", isAllSelected ) ] ] [ span [] [ text "Alla spelare" ] ] ]
            , button [ classList [ ( "large-button add-players-dialog-start-button", True ), ( "enabled", List.length markedPlayers > 0 ) ], onClick Start ] [ text "Start" ]
            ]
        ]
