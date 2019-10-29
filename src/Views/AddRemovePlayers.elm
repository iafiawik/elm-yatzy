module Views.AddRemovePlayers exposing (addRemovePlayers)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import List.Extra exposing (find)
import Model.Player exposing (Player)
import Model.User exposing (User)
import Models exposing (Model, Msg(..))


playerButton : User -> Int -> Html Msg
playerButton user index =
    button [ onClick (RemovePlayer user), class "add-players-dialog-player-button" ] [ span [] [ text (String.fromInt (index + 1) ++ ". ") ], span [] [ text user.name ], button [ class "add-players-dialog-player-button-delete" ] [ text "X" ] ]


userButton : User -> Html Msg
userButton user =
    button [ onClick (AddPlayer user), class "add-players-dialog-user-button" ] [ span [] [ text user.name ], button [ class "add-players-dialog-user-button-add" ] [ text "+" ] ]


addRemovePlayers : List User -> String -> List User -> Html Msg
addRemovePlayers players currentNewPlayerName users =
    let
        playerButtons =
            List.indexedMap
                (\index p ->
                    playerButton p
                        index
                )
                players

        availableUsers =
            List.filter
                (\u ->
                    if find (\p -> p.id == u.id) players == Nothing then
                        True

                    else
                        False
                )
                users

        userButtons =
            List.map
                (\u ->
                    userButton u
                )
                (List.sortBy
                    .name
                    availableUsers
                )
    in
    div [ class "add-players-dialog-wrapper dialog-wrapper" ]
        [ div [ class "add-players-dialog-background dialog-background animated fadeIn", onClick ShowStartPage ] []
        , div [ class "add-players-dialog dialog-content a animated jackInTheBox" ]
            [ button [ class "dialog-content-cancel-button button", onClick ShowStartPage ] [ text "X" ]
            , div [] [ h1 [] [ text "Yatzy" ], h2 [] [ text "Lägg till spelare" ] ]
            , div [ class "add-players-dialog-user-buttons" ] userButtons
            , div [ class "add-players-dialog-add-new-user" ]
                [ input [ class "add-players-dialog-input-field", type_ "text", onInput NewPlayerInputValueChange, value currentNewPlayerName, placeholder "Ny spelare..." ] []
                , button [ onClick CreateUser ] [ text "Skapa" ]
                ]
            , h3 [] [ text "Spelare i denna omgång" ]
            , div [ class "add-players-dialog-player-buttons" ] playerButtons
            , button [ classList [ ( "large-button add-players-dialog-start-button", True ), ( "enabled", List.length players > 0 ) ], disabled (List.length players == 0), onClick PlayersAdded ] [ text "Start" ]
            ]
        ]
