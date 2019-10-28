module Views.AddRemovePlayers exposing (addRemovePlayers)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import List.Extra exposing (find)
import Model.Player exposing (Player)
import Model.User exposing (User)
import Models exposing (GameSetup, Model, Msg(..))


playerButton : Player -> Int -> List (Html Msg) -> Html Msg
playerButton player index content =
    button [ onClick (RemovePlayer player), class "add-players-dialog-player-button" ] [ span [] [ text (String.fromInt (index + 1) ++ ". ") ], span [] [ text player.user.name ], button [ class "add-players-dialog-player-button-delete" ] [ text "X" ], div [] ([] ++ content) ]


userButton : User -> List (Html Msg) -> Html Msg
userButton user content =
    button [ onClick (AddPlayer user), class "add-players-dialog-user-button" ] [ span [] [ text user.name ], button [ class "add-players-dialog-user-button-add" ] [ text "+" ], div [] ([] ++ content) ]


addRemovePlayers : GameSetup -> List User -> Html Msg
addRemovePlayers model users =
    let
        playerButtons =
            List.indexedMap
                (\index p ->
                    playerButton p
                        index
                        []
                )
                model.players

        availableUsers =
            List.filter
                (\u ->
                    if find (\p -> p.user.id == u.id) model.players == Nothing then
                        True

                    else
                        False
                )
                users

        userButtons =
            List.map
                (\u ->
                    userButton u
                        []
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
                [ input [ class "add-players-dialog-input-field", type_ "text", onInput NewPlayerInputValueChange, value model.currentNewPlayerName, placeholder "Ny spelare..." ] []
                , button [ onClick AddUser ] [ text "Skapa" ]
                ]
            , h3 [] [ text "Spelare i denna omgång" ]
            , div [ class "add-players-dialog-player-buttons" ] playerButtons
            , button [ classList [ ( "large-button add-players-dialog-start-button", True ), ( "enabled", List.length model.players > 0 ) ], disabled (List.length model.players == 0), onClick PlayersAdded ] [ text "Start" ]
            ]
        ]
