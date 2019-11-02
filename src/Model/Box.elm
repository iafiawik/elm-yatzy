module Model.Box exposing (Box, getAcceptedValues, getBoxById, getBoxes, getDefaultMarkedValue, getInteractiveBoxes)

import List.Extra exposing (find)
import Model.BoxCategory exposing (BoxCategory(..))
import Model.BoxType exposing (BoxType(..))


type alias Box =
    { id : String, friendlyName : String, boxType : BoxType, category : BoxCategory, order : Int }


getInteractiveBoxes : List Box
getInteractiveBoxes =
    List.filter (\box -> box.category /= None) getBoxes


getDefaultMarkedValue : Box -> Maybe Int
getDefaultMarkedValue box =
    let
        acceptedValues =
            getAcceptedValues box
    in
    if List.length (getAcceptedValues box) == 1 then
        List.head acceptedValues

    else
        Nothing


getBoxes : List Box
getBoxes =
    [ { id = "ones", friendlyName = "Ettor", boxType = Regular 1, category = Upper, order = 0 }
    , { id = "twos", friendlyName = "Tvåor", boxType = Regular 2, category = Upper, order = 1 }
    , { id = "threes", friendlyName = "Treor", boxType = Regular 3, category = Upper, order = 2 }
    , { id = "fours", friendlyName = "Fyror", boxType = Regular 4, category = Upper, order = 3 }
    , { id = "fives", friendlyName = "Femmor", boxType = Regular 5, category = Upper, order = 4 }
    , { id = "sixes", friendlyName = "Sexor", boxType = Regular 6, category = Upper, order = 5 }
    , { id = "upper_sum", friendlyName = "Övre summa", boxType = UpperSum, category = None, order = -1 }
    , { id = "bonus", friendlyName = "Bonus", boxType = Bonus, category = None, order = -1 }
    , { id = "one_pair", friendlyName = "Ett par", boxType = SameKind, category = Lower, order = 6 }
    , { id = "two_pairs", friendlyName = "Två par", boxType = Combination, category = Lower, order = 7 }
    , { id = "three_of_a_kind", friendlyName = "Tretal", boxType = SameKind, category = Lower, order = 8 }
    , { id = "four_of_a_kind", friendlyName = "Fyrtal", boxType = SameKind, category = Lower, order = 9 }
    , { id = "small_straight", friendlyName = "Liten stege", boxType = Combination, category = Lower, order = 10 }
    , { id = "large_straight", friendlyName = "Stor stege", boxType = Combination, category = Lower, order = 11 }
    , { id = "full_house", friendlyName = "Kåk", boxType = Combination, category = Lower, order = 12 }
    , { id = "chance", friendlyName = "Chans", boxType = Combination, category = Lower, order = 13 }
    , { id = "yatzy", friendlyName = "Yatzy", boxType = SameKind, category = Lower, order = 14 }
    , { id = "total_sum", friendlyName = "Summa", boxType = TotalSum, category = None, order = -1 }
    ]


getBoxById : String -> Box
getBoxById id =
    Maybe.withDefault { id = "ones", friendlyName = "Ettor", boxType = Regular 1, category = Upper, order = 0 } (find (\b -> b.id == id) getBoxes)


getAcceptedValues : Box -> List Int
getAcceptedValues box =
    if box.id == "ones" then
        List.map (\n -> n * 1) [ 1, 2, 3, 4, 5 ]

    else if box.id == "twos" then
        List.map (\n -> n * 2) [ 1, 2, 3, 4, 5 ]

    else if box.id == "threes" then
        List.map (\n -> n * 3) [ 1, 2, 3, 4, 5 ]

    else if box.id == "fours" then
        List.map (\n -> n * 4) [ 1, 2, 3, 4, 5 ]

    else if box.id == "fives" then
        List.map (\n -> n * 5) [ 1, 2, 3, 4, 5 ]

    else if box.id == "sixes" then
        List.map (\n -> n * 6) [ 1, 2, 3, 4, 5 ]

    else if box.id == "one_pair" then
        List.map (\n -> n * 2) [ 1, 2, 3, 4, 5, 6 ]

    else if box.id == "two_pairs" then
        [ 6, 8, 10, 12, 14, 16, 18, 20, 22 ]

    else if box.id == "three_of_a_kind" then
        List.map (\n -> n * 3) [ 1, 2, 3, 4, 5, 6 ]

    else if box.id == "four_of_a_kind" then
        List.map (\n -> n * 4) [ 1, 2, 3, 4, 5, 6 ]

    else if box.id == "small_straight" then
        [ 15 ]

    else if box.id == "large_straight" then
        [ 20 ]

    else if box.id == "full_house" then
        [ 7, 8, 9, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 26, 27, 28 ]

    else if box.id == "chance" then
        List.range 5 30

    else if box.id == "yatzy" then
        [ 50 ]

    else
        []
