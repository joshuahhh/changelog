module Story where

import Json.Encode

import Util exposing ( unwrapOrCrash )


type alias Story a =
  { before : a
  , steps : List (Step a)
  , after : a
  }

  -- if Nothing, then this is a secret, silent step
type alias Narration = String

type alias Step a =
  { narration : Narration
  , subStory : SubStory a
  }

type SubStory a = SubStory (Story a)

-- Here's the public API:

ending : Story a -> a
ending story = story.after

start : a -> Story a
start a = emptyStory_ a

do : (a -> (Story a -> Story a)) -> (Story a -> Story a)
do f story = f (ending story) story

step : Narration -> (Story a -> Story a) -> (Story a -> Story a)
step narration subStoryAdvancer story =
  let
    subStoryBefore = emptyStory_ (ending story)
    subStoryAfter = subStoryAdvancer subStoryBefore
  in
    story |> addStep_
      { narration = narration
      , subStory = SubStory subStoryAfter}

map : (a -> a) -> (Story a -> Story a)
map mapper story =
  { story | after = mapper story.after }

flattenLastIfLonesome : Story a -> Story a
flattenLastIfLonesome story =
  if List.length story.steps == 1 then
    story.steps |> List.head |> unwrapOrCrash "???" |> subStory_
  else
    story

-- And here are utility functions:

subStory_ : Step a -> Story a
subStory_ { subStory } =
  case subStory of SubStory subStory -> subStory  -- lolz

-- "There once was a `character`. Nothing happened."
emptyStory_ : a -> Story a
emptyStory_ character =
  { before = character
  , steps = []
  , after = character
  }

-- addStep adds a step to a story, and updates the story's ending to reflect the step's ending.
addStep_ : Step a -> Story a -> Story a
addStep_ step story =
  { story
  | steps = story.steps ++ [ step ]
  , after = (step |> subStory_).after
  }

-- Given a way to encode characters, we can encode stories about those characters

jsonEncodeStory : (a -> Json.Encode.Value) -> Story a -> Json.Encode.Value
jsonEncodeStory jsonEncodeCharacter story =
  [ ( "before", story.before |> jsonEncodeCharacter )
  , ( "steps", story.steps |> jsonEncodeSteps jsonEncodeCharacter )
  , ( "after", story.after |> jsonEncodeCharacter )
  ]
  |> Json.Encode.object

jsonEncodeSteps : (a -> Json.Encode.Value) -> List (Step a) -> Json.Encode.Value
jsonEncodeSteps jsonEncodeCharacter steps =
  steps |> List.map (jsonEncodeStep jsonEncodeCharacter) |> Json.Encode.list

jsonEncodeStep : (a -> Json.Encode.Value) -> Step a -> Json.Encode.Value
jsonEncodeStep jsonEncodeCharacter step =
  [ ( "narration", step.narration |> jsonEncodeNarration )
  , ( "subStory",  step.subStory  |> jsonEncodeSubStory jsonEncodeCharacter )
  ]
  |> Json.Encode.object

jsonEncodeNarration : Narration -> Json.Encode.Value
jsonEncodeNarration = Json.Encode.string  -- JsonEncodeUtils.maybeString

jsonEncodeSubStory : (a -> Json.Encode.Value) -> SubStory a -> Json.Encode.Value
jsonEncodeSubStory jsonEncodeCharacter (SubStory story) =
  jsonEncodeStory jsonEncodeCharacter story
