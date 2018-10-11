module Views.ScoreDialog exposing (scoreDialog)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Logic exposing (getAcceptedValues)
import Models exposing (Box, BoxCategory(..), BoxType(..), Game(..), Model, Msg(..), Player, PlayerAndNumberOfValues, Value)


scoreDialogButton : Bool -> Int -> String -> String -> Html Msg
scoreDialogButton isMarked value buttonText class =
    button
        [ classList
            [ ( "input-dialog-number-button button", True )
            , ( "marked", isMarked )
            , ( class, True )
            ]
        , onClick (ValueMarked value)
        ]
        [ text buttonText ]


scoreDialog : Model -> Box -> Player -> Html Msg
scoreDialog model box currentPlayer =
    let
        acceptedValues =
            getAcceptedValues box

        acceptedValuesButtons =
            List.map
                (\v ->
                    scoreDialogButton (model.currentValue == v) v (String.fromInt v) "hej"
                )
                acceptedValues
    in
    div [ class "input-dialog-wrapper dialog-wrapper" ]
        [ div [ class "input-dialog-background dialog-background  animated fadeIn", onClick HideAddValue ] []
        , div [ class "input-dialog dialog-content animated jackInTheBox" ]
            [ div []
                [ button [ class "input-dialog-cancel-button button", onClick HideAddValue ] [ text "X" ]
                , h1 [] [ text box.friendlyName ]
                , h2 [] [ text currentPlayer.name ]
                ]
            , div [ classList [ ( "input-dialog-number-buttons", True ), ( "" ++ box.id_, True ) ] ]
                (acceptedValuesButtons ++ [ scoreDialogButton (model.currentValue == 0) 0 ":(" "skip-button" ])
            , div []
                [ input [ class "input-dialog-input-field", type_ "number", onInput InputValueChange, value (String.fromInt model.currentValue) ] []
                ]
            , button [ classList [ ( "input-dialog-submit-button button", True ), ( "enabled animated pulse infinite", model.currentValue >= 0 ) ], disabled (model.currentValue < 0), onClick AddValue ] [ text "Spara" ]
            ]
        ]
