module Util where

-- Returns `Nothing` if there are 0 or >1 results
find : (a -> Bool) -> List a -> Maybe a
find predicate list =
  let
    filteredList = List.filter predicate list
  in
    if List.length filteredList /= 1 then
      Nothing
    else
      List.head filteredList

mapWhen : (a -> Bool) -> (a -> a) -> List a -> List a
mapWhen predicate mapper list =
  List.map (\a -> if predicate a then mapper a else a) list

idIs : a -> { record | id : a } -> Bool
idIs id thingWithId = thingWithId.id == id

-- can't use Maybe.withDefault cuz Elm isn't lazy! cool!
unwrapOrCrash : String -> Maybe a -> a
unwrapOrCrash message maybeA =
  case maybeA of
    Just a  -> a
    Nothing -> Debug.crash message

-- maybeApply : (b -> a -> a) -> Maybe b -> (a -> a)
-- maybeApply f maybeB = maybeB |> Maybe.map f |> Maybe.withDefault identity
