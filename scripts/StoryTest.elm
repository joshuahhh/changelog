module StoryTest where

import Json.Encode

import Story exposing ( Story )

divideByTwo : Story Int -> Story Int
divideByTwo =
  Story.step "divide by two" <| Story.map (\ i -> i // 2)

timesThree : Story Int -> Story Int
timesThree =
  Story.step "times three" <| Story.map (\ i -> i * 2)

plusOne : Story Int -> Story Int
plusOne =
  Story.step "plus one" <| Story.map (\ i -> i + 2)

collatz : Story Int -> Story Int
collatz =
  Story.step "collatz!" <| Story.do (\ i ->
    if i % 2 == 0 then
      divideByTwo
    else
      timesThree
      >> plusOne
  )

collatzTwice : Story Int -> Story Int
collatzTwice =
  Story.step "Collatz 1" collatz
  >> Story.step "Collatz 2" collatz

collatzToOne : Story Int -> Story Int
collatzToOne =
  Story.do (\ i ->
    if i == 1 then
      identity
    else
      collatz
      >> collatzToOne)

a : Json.Encode.Value
a = Debug.log "yayaya" (Story.start 3 |> collatzToOne |> Story.jsonEncodeStory Json.Encode.int)
