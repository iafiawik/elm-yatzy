module Views.Loader exposing (loader)

import Html exposing (..)
import Html.Attributes exposing (..)
import Models exposing (Msg(..))


loader : String -> Bool -> Html Msg
loader message inverted =
    div [ classList [ ( "loader-outer-container", True ), ( "inverted", inverted ) ] ]
        [ div [ class "loader-container" ]
            [ div [ class "loader centered" ]
                [ div [ class "square square_one" ]
                    []
                , div
                    [ class "square square_two" ]
                    []
                , div
                    [ class "square square_three" ]
                    []
                , div
                    [ class "square square_four" ]
                    []
                , div
                    [ class "square square_five" ]
                    []
                , div
                    [ class "square square_six" ]
                    []
                , div
                    [ class "square square_seven" ]
                    []
                , div
                    [ class "square square_eight" ]
                    []
                , div
                    [ class "square square_nine" ]
                    []
                ]
            ]
        , span
            [ class "loader-text" ]
            [ text message ]
        ]
