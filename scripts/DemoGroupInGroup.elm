module DemoGroupInGroup where

import Json.Encode
import Dict
import Array

import SymbolRendering exposing (
  SymbolRendering, runChangeInContextAsStep, catchUpCloning, jsonEncodeSymbolRendering)
import Symbol exposing (
  Environment, Change(..), SymbolRef(..), environmentToJson )
import Story exposing ( Story )

myEnvironment : Environment
myEnvironment =
  { symbols = Dict.fromList [
    ( "Transform"
    , { changes = Array.fromList
        [ SetRoot (
            { id = "transformNode"
            , symbolRef = BareNode
            }
          )
        ]
      }
    ),
    ( "Group",
      { changes = Array.fromList
        [ SetRoot (
            { id = "groupNode"
            , symbolRef = BareNode
            }
          ),
          AppendChild "groupNode" (
            { id = "transform"
            , symbolRef = SymbolIdAsRef "Transform"
            }
          )
        ]
      }
    )
  ]}

story : Story SymbolRendering
story =
  Story.start { blocks = [], rootId = Nothing }
  |> runChangeInContextAsStep
      { contextId = Nothing
      , change =
          SetRoot
            { id = "group1"
            , symbolRef = SymbolIdAsRef "Group"
            }
      }
      myEnvironment
  |> catchUpCloning "group1" myEnvironment
  |> catchUpCloning "group1/transform" myEnvironment
  |> runChangeInContextAsStep
      { contextId = Nothing
      , change =
          AppendChild
            "group1/groupNode"
            { id = "group2"
            , symbolRef = SymbolIdAsRef "Group"
            }
      }
      myEnvironment
  |> catchUpCloning "group2" myEnvironment

storyInJson : Json.Encode.Value
storyInJson = story |> Story.jsonEncodeStory jsonEncodeSymbolRendering

environmentInJson : Json.Encode.Value
environmentInJson = environmentToJson myEnvironment
