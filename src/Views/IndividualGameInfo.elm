module Views.IndividualGameInfo exposing (individualGameInfo)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Html.Keyed as Keyed
import Model.Game exposing (Game)
import Models exposing (Msg(..))


individualGameInfo : Game -> Html Msg
individualGameInfo game =
    div [ class "dialog-wrapper" ]
        [ div [ class "dialog-background  animated fadeIn" ] []
        , div [ class "individual-game-info dialog-content animated jackInTheBox" ]
            [ h1 [] [ text "Information" ]
            , h2 [] [ text "Du spelar ett spel med denna kod:" ]
            , span [ class "game-info-code" ] [ text game.code ]
            , h2 [ class "indivudal-game-info-restart" ] [ span [] [ text "Vill du byta spel eller spelare? " ], a [ onClick Restart ] [ text "Klicka här" ], span [] [ text "." ] ]
            , button [ classList [ ( "large-button add-players-dialog-start-button", True ), ( "enabled", True ) ], onClick HideGameInfo ] [ text "Stäng" ]
            ]
        ]
