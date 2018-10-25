module Model.Box exposing (Box)

import Model.BoxCategory exposing (BoxCategory)
import Model.BoxType exposing (BoxType)


type alias Box =
    { id : String, friendlyName : String, boxType : BoxType, category : BoxCategory, order : Int }
