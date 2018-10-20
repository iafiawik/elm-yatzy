module Model.User exposing (User, userDecoder, usersDecoder)

import Json.Decode exposing (Decoder, field, int, map3, string)
import Json.Encode as E


usersDecoder : Json.Decode.Decoder (List User)
usersDecoder =
    Json.Decode.list userDecoder


userDecoder : Decoder User
userDecoder =
    let
        _ =
            Debug.log "userDecoder" ""
    in
    map3 User
        (field "id" string)
        (field "name" string)
        (field "userName" string)


type alias User =
    { id : String, name : String, userName : String }



-- userEncoder : User -> E.value
-- userEncoder ({ id } as user) =
--     Encode.object
--         [ ( "id", encodeOfficeId id )
--         , ( "latLng", encodeLatLon office.address.geo )
--         ]
