module Logic exposing (hej)


hej : Bool
hej =
    True



-- getNextValueToAnimate : List Player -> List Value -> Maybe Value
-- getNextValueToAnimate players values =
--     let
--         nextPlayerMaybe =
--             find
--                 (\player ->
--                     List.any (\v -> v.counted == False) player.values
--                 )
--                 players
--     in
--     case nextPlayerMaybe of
--         Just nextPlayer ->
--             let
--                 sortedPlayerValues =
--                     List.sortBy (\v -> v.box.order) nextPlayer.values
--
--                 nextValueMaybe =
--                     find
--                         (\v -> v.counted == False)
--                         sortedPlayerValues
--             in
--             case nextValueMaybe of
--                 Just nextValue ->
--                     Just nextValue
--
--                 Nothing ->
--                     Nothing
--
--         Nothing ->
--             Nothing
-- getCurrentPlayer : List Value -> List Player -> Maybe Player
-- getCurrentPlayer values players =
--     let
--         sortablePlayers =
--             List.map (\p -> { numberOfValues = List.length (getValuesByPlayer values p), player = p }) players
--
--         playersByNumberOfValues =
--             sortPLayers sortablePlayers
--
--         currentPlayerMaybe =
--             List.head playersByNumberOfValues
--     in
--     -- Maybe.map .player currentPlayerMaybe
--     case currentPlayerMaybe of
--         Just currentPlayerComparable ->
--             let
--                 currentPlayer =
--                     currentPlayerComparable.player
--             in
--             Just currentPlayer
--
--         Nothing ->
--             Nothing
-- getValuesByPlayer : List Value -> Player -> List Value
-- getValuesByPlayer values player =
--     List.filter (\v -> v.player == player) values
-- sortPlayersByOrder : List Player -> List Player
-- sortPlayersByOrder players =
--     players
-- sortPLayers : List PlayerAndNumberOfValues -> List PlayerAndNumberOfValues
-- sortPLayers players =
--     players
-- playerOrdering : Ordering PlayerAndNumberOfValues
-- playerOrdering =
--     Ordering.byField .numberOfValues
--         |> Ordering.breakTiesWith (Ordering.byField (.player >> .order))
--
--
-- areAllUsersFinished : List Value -> List Player -> List Box -> Bool
-- areAllUsersFinished values players boxes =
--     let
--         numberOfBoxes =
--             List.length (List.filter (\b -> b.category /= None) boxes)
--
--         numberOfValues =
--             List.length values
--
--         numberOfPlayers =
--             List.length players
--     in
--     numberOfValues >= numberOfBoxes * numberOfPlayers
