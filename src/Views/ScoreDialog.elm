module Views.ScoreDialog exposing (scoreDialog)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Model.Box exposing (Box, getAcceptedValues)
import Model.BoxCategory exposing (BoxCategory(..))
import Model.BoxType exposing (BoxType(..))
import Model.Game exposing (Game)
import Model.Player exposing (Player)
import Model.Value exposing (Value)
import Models exposing (GamePlaying, Model, Msg(..), PlayerAndNumberOfValues)


scoreDialogNumberButton : Bool -> Int -> String -> String -> Html Msg
scoreDialogNumberButton isMarked value buttonText class =
    button
        [ classList
            [ ( "score-dialog-number-button button", True )
            , ( "marked", isMarked )
            , ( class, True )
            ]
        , onClick (ValueMarked value)
        ]
        [ span [] [ text buttonText ] ]


scoreDialog : GamePlaying -> Box -> Player -> Bool -> Html Msg
scoreDialog model box currentPlayer isEdit =
    let
        acceptedValues =
            getAcceptedValues box

        acceptedValuesButtons =
            List.map
                (\v ->
                    scoreDialogNumberButton (model.currentValue == v) v (String.fromInt v) ""
                )
                acceptedValues
    in
    div [ class "dialog-wrapper score-dialog-dialog-wrapper" ]
        [ div [ class "dialog-background  animated fadeIn", onClick HideAddValue ] []
        , div [ class "score-dialog dialog-content animated jackInTheBox" ]
            [ div []
                [ button [ class "dialog-content-cancel-button button", onClick HideAddValue ] [ text "X" ]
                , h1 [] [ span [] [ text box.friendlyName ], button [ classList [ ( "score-dialog-delete-button button", True ), ( "enabled", model.currentValue >= 0 ), ( "visible", isEdit ) ], disabled (model.currentValue < 0), onClick RemoveValue ] [ text "(ta bort)" ] ]
                , h2 [] [ text currentPlayer.user.name ]
                ]
            , div [ classList [ ( "score-dialog-number-buttons", True ), ( "" ++ box.id, True ) ] ]
                (acceptedValuesButtons ++ [ scoreDialogNumberButton (model.currentValue == 0) 0 "" "skip-button" ])
            , button [ classList [ ( "score-dialog-submit-button button", True ), ( "enabled animated pulse infinite", model.currentValue >= 0 ) ], disabled (model.currentValue < 0), onClick AddValue ] [ text "Spara" ]
            ]
        ]
