module JsonEncodeTools where

import Dict exposing ( Dict )
import Json.Encode

jsonEncodeMaybeString : Maybe String -> Json.Encode.Value
jsonEncodeMaybeString maybeString =
  Maybe.map Json.Encode.string maybeString |> Maybe.withDefault Json.Encode.null

jsonEncodeMappedDict : (a -> Json.Encode.Value) -> (Dict String a) -> Json.Encode.Value
jsonEncodeMappedDict mapper dict =
  dict
  |> Dict.map (\ k v -> mapper v)
  |> Dict.toList
  |> Json.Encode.object
