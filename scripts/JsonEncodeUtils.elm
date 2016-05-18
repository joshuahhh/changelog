module JsonEncodeUtils where

import Dict exposing ( Dict )
import Json.Encode

maybeString : Maybe String -> Json.Encode.Value
maybeString maybeString =
  Maybe.map Json.Encode.string maybeString |> Maybe.withDefault Json.Encode.null

mappedDict : (a -> Json.Encode.Value) -> (Dict String a) -> Json.Encode.Value
mappedDict mapper dict =
  dict
  |> Dict.map (\ k v -> mapper v)
  |> Dict.toList
  |> Json.Encode.object
