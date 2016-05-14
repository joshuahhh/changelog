module Util where

find : (a -> Bool) -> List a -> a
find predicate list =
  let
    filteredList = List.filter predicate list
  in
    if List.length filteredList /= 1 then
      Debug.crash "find failed!"
    else
      case List.head filteredList of
        Just a -> a
        Nothing -> Debug.crash "find failed!"

mapWhen : (a -> Bool) -> (a -> a) -> List a -> List a
mapWhen predicate mapper list =
  List.map (\a -> if predicate a then mapper a else a) list

idIs : a -> { record | id : a } -> Bool
idIs id thingWithId = thingWithId.id == id

force : Maybe a -> a
force maybeA =
  case maybeA of
    Just a  -> a
    Nothing -> Debug.crash "forced a Nothing!"
