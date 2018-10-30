module Views.SelectPlayer exposing (selectPlayer)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Html.Keyed as Keyed
import Model.Game exposing (Game)
import Model.Player as Player
import Model.User as User
import Models exposing (MarkedPlayer(..), Msg(..))


playerButton : Player.Player -> Bool -> Html Msg
playerButton player isMarked =
    button [ classList [ ( "select-player-button", True ), ( "selected", isMarked ) ], onClick (PlayerMarked player) ] [ text player.user.name ]


isPlayerMarked : Player.Player -> MarkedPlayer -> Bool
isPlayerMarked player markedPlayer =
    case markedPlayer of
        Single currentMarkedPlayer ->
            currentMarkedPlayer.user.id == player.user.id

        All ->
            False

        NoPlayer ->
            False


playerButtons : List Player.Player -> MarkedPlayer -> Html Msg
playerButtons players markedPlayer =
    let
        buttons =
            List.map (\player -> playerButton player (isPlayerMarked player markedPlayer)) players
    in
    div [] buttons


selectPlayer : Game -> MarkedPlayer -> Html Msg
selectPlayer game markedPlayer =
    div [ class "dialog-wrapper" ]
        [ div [ class "dialog-background  animated fadeIn" ] []
        , div [ class "select-player dialog-content animated jackInTheBox" ]
            [ button [ class "dialog-content-cancel-button button", onClick ShowStartPage ] [ text "X" ]
            , h1 [] [ text "Vem är du?" ]
            , h2 [] [ text "välj ditt namn nedan:" ]
            , div [ class "select-player-buttons" ] [ playerButtons game.players markedPlayer ]
            , h2 [] [ text "... eller välj att spela alla spelare:" ]
            , div [ class "select-player-button-all-players" ] [ button [ onClick AllPlayersMarked, classList [ ( "select-player-button", True ), ( "selected", markedPlayer == All ) ] ] [ span [] [ text "Alla spelare" ] ] ]
            , button [ classList [ ( "large-button add-players-dialog-start-button", True ), ( "enabled", markedPlayer /= NoPlayer ) ], onClick Start ] [ text "Start" ]
            ]
        ]
