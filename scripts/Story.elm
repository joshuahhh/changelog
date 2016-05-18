module Story where

import Json.Encode
import List.Extra

import JsonEncodeUtils


type alias Story a =
  { start : a
  , steps : List (StoryStep a)
  }

type alias StoryStep a =
  { narration : Maybe String
  , before : a
  , explanation : Explanation a
  , after : a
  }

type Explanation a = Explanation (Story a)

emptyStory : a -> Story a
emptyStory character =
  { start = character
  , steps = []
  }

outcome : Story a -> a
outcome story =
  case List.Extra.last story.steps of
    Just step -> step.after
    Nothing -> story.start

simpleStep : Maybe String -> a -> a -> StoryStep a
simpleStep narration before after =
  { narration = narration
  , before = before
  , explanation = Explanation { start = before, steps = [] }
  , after = after }

addStep : StoryStep a -> Story a -> Story a
addStep storyStep story = { story | steps = story.steps ++ [ storyStep ] }

-- An `advancer` takes an empty substory and advances it
applyStep : Maybe String -> (Story a -> Story a) -> Story a -> Story a
applyStep narration advancer story =
  let
    character = story |> outcome
    emptySubStory = emptyStory character
    advancedSubStory = emptySubStory |> advancer
  in
    story
    |> addStep
      { narration = narration
      , before = character
      , explanation = Explanation advancedSubStory
      , after = advancedSubStory |> outcome
      }

applySimpleStep : Maybe String -> (a -> a) -> Story a -> Story a
applySimpleStep narration transformer story =
  let
    character = story |> outcome
    newCharacter = character |> transformer
  in
    story
    |> addStep (simpleStep narration character newCharacter)

-- Given a way to encode characters, we can encode stories about those characters

jsonEncodeStory : (a -> Json.Encode.Value) -> Story a -> Json.Encode.Value
jsonEncodeStory jsonEncodeCharacter story =
  [ ( "start", story.start |> jsonEncodeCharacter )
  , ( "steps", story.steps |> jsonEncodeStorySteps jsonEncodeCharacter )
  ]
  |> Json.Encode.object

jsonEncodeStorySteps : (a -> Json.Encode.Value) -> List (StoryStep a) -> Json.Encode.Value
jsonEncodeStorySteps jsonEncodeCharacter storySteps =
  storySteps |> List.map (jsonEncodeStoryStep jsonEncodeCharacter) |> Json.Encode.list

jsonEncodeStoryStep : (a -> Json.Encode.Value) -> StoryStep a -> Json.Encode.Value
jsonEncodeStoryStep jsonEncodeCharacter storyStep =
  [ ( "narration",   storyStep.narration   |> JsonEncodeUtils.maybeString )
  , ( "before",      storyStep.before      |> jsonEncodeCharacter )
  , ( "explanation", storyStep.explanation |> jsonEncodeExplanation jsonEncodeCharacter )
  , ( "after",       storyStep.after       |> jsonEncodeCharacter ) ]
  |> Json.Encode.object

jsonEncodeExplanation : (a -> Json.Encode.Value) -> Explanation a -> Json.Encode.Value
jsonEncodeExplanation jsonEncodeCharacter (Explanation story) =
  jsonEncodeStory jsonEncodeCharacter story
