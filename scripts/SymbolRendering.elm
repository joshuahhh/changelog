module SymbolRendering where

import Json.Encode
import String
import Dict exposing ( Dict )
import Array exposing ( Array )

import Util exposing ( mapWhen, idIs, find, unwrapOrCrash )
import JsonEncodeUtils
import Block exposing (
  Block, BlockId, BlockBody(..), cloningToBlock, constructBlockId, jsonEncodeBlock,
  incrementNextChangeIdxOfCloning, setRootOfCloning, appendChildToNode, ownerHierarchy )
import Symbol exposing ( SymbolId, NodeId, SymbolRef(..), Cloning, Change(..),
  Environment, changeToString )
import Story exposing ( Story, outcome, applyStep, applySimpleStep, addStep, Explanation(..), emptyStory )

-- And here's the dynamic world of (partially) rendered logs

type alias SymbolRendering =
  { blocks : List Block
  , rootId : Maybe BlockId
  }

type alias ContextId = Maybe BlockId

type alias ChangeInContext =
  { change : Change
  , contextId : ContextId
  }

changeInContextToString : ChangeInContext -> String
changeInContextToString { change, contextId } =
  let
    contextPart =
      case contextId of
        Just contextId -> "in '" ++ contextId ++ "', "
        Nothing        -> "in root context, "
  in
    contextPart ++ (changeToString change)

runSetRoot : Cloning -> Maybe BlockId -> Environment -> Story SymbolRendering -> Story SymbolRendering
runSetRoot cloning contextId environment =
  applySimpleStep Nothing (\ symbolRendering ->
    let
      newBlock = cloningToBlock cloning contextId
      newBlocks = newBlock ::
        case contextId of
          Just blockId ->
            mapWhen
              (idIs blockId)
              (setRootOfCloning newBlock.id)
              symbolRendering.blocks
          Nothing ->
            symbolRendering.blocks
      newRootId =
        case contextId of
          Just blockId -> symbolRendering.rootId
          Nothing -> Just cloning.id
      newSymbolRendering = { symbolRendering | blocks = newBlocks, rootId = newRootId }
    in
      newSymbolRendering
  )

runAppendChild : NodeId -> Cloning -> ContextId -> Environment -> Story SymbolRendering -> Story SymbolRendering
runAppendChild nodeId cloning contextId environment story =
  let
    newBlock = cloningToBlock cloning contextId
    blockIdOfParent = constructBlockId contextId nodeId
    caughtUpStory = catchUpNode blockIdOfParent contextId environment story
    narration =
      if List.isEmpty caughtUpStory.steps then
        Nothing
      else
        Just "and now the intended operation"
  in
    applySimpleStep
      narration
      (\ symbolRendering ->
        let
          newBlocks = newBlock ::
            mapWhen
              (idIs blockIdOfParent)
              (appendChildToNode (constructBlockId contextId cloning.id))
              symbolRendering.blocks
          newSymbolRendering = { symbolRendering | blocks = newBlocks }
        in
          newSymbolRendering
      )
      caughtUpStory

runChangeInContext : ChangeInContext -> Environment -> Story SymbolRendering -> Story SymbolRendering
runChangeInContext { change, contextId } =
  case change of
    SetRoot cloning ->
      runSetRoot cloning contextId
    AppendChild nodeId cloning ->
      runAppendChild nodeId cloning contextId

runChangeInContextAsStep : ChangeInContext -> Environment -> Story SymbolRendering -> Story SymbolRendering
runChangeInContextAsStep changeInContext environment =
  applyStep
    (always <| Just (changeInContextToString changeInContext))
    (runChangeInContext changeInContext environment)

incrementNextChangeOfCloningInSymbolRendering : BlockId -> SymbolRendering -> SymbolRendering
incrementNextChangeOfCloningInSymbolRendering blockId symbolRendering =
  { symbolRendering | blocks =
      symbolRendering.blocks |>
        mapWhen (idIs blockId) incrementNextChangeIdxOfCloning
  }

catchUpNode : BlockId -> ContextId -> Environment -> Story SymbolRendering -> Story SymbolRendering
catchUpNode blockId contextId environment story =
  let
    allCloningIds = blockId |> ownerHierarchy
    cloningIdsToCheck =
      case contextId of
        Just contextId -> allCloningIds |> List.filter (\ owner -> contextId |> String.startsWith owner |> not)
        Nothing -> allCloningIds
  in
    List.foldl (\ cloningId story -> catchUpCloning cloningId environment story) story cloningIdsToCheck

catchUpCloning : BlockId -> Environment -> Story SymbolRendering -> Story SymbolRendering
catchUpCloning blockId environment story =
  let
    subStory = catchUpCloningHelper blockId environment (emptyStory (outcome story))
  in
    if List.isEmpty subStory.steps then
      story
    else
      story
      |> addStep
        { narration = Just ("catch up cloning '" ++ blockId ++ "'")
        , before = outcome story
        , explanation = Explanation subStory
        , after = outcome subStory }

catchUpCloningHelper : BlockId -> Environment -> Story SymbolRendering -> Story SymbolRendering
catchUpCloningHelper blockId environment story =
  let
    symbolRendering = outcome story
    block = find (idIs blockId) symbolRendering.blocks |> unwrapOrCrash (String.join "\n"
      [ "Could not find block"
      , toString blockId
      , toString (List.map .id symbolRendering.blocks)
      ])
    cloningBody =
      case block.body of
        CloningBlockBody cloningBody -> cloningBody
        _ -> Debug.crash "you can only catch up clonings!"
    nextChangeIdx = cloningBody.nextChangeIdx
    symbol = environment.symbols |> Dict.get cloningBody.symbolId |> unwrapOrCrash "Could not find symbol!"
    changes = symbol.changes
  in
    if nextChangeIdx == Array.length changes then
      -- we're caught up already!
      story
    else
      -- catch up one change, then recurse
      let
        change = changes |> Array.get nextChangeIdx |> unwrapOrCrash "Could not find nextChangeIdx"
        changeInContext = { change = change, contextId = Just blockId }
        changeNarration =
          cloningBody.symbolId ++ " step " ++ (toString nextChangeIdx) ++ ":\n"
          ++ (changeInContextToString changeInContext)
      in
        story
        |> applyStep
          (always <| Just changeNarration)
          (  runChangeInContext changeInContext environment
          >> applySimpleStep Nothing (incrementNextChangeOfCloningInSymbolRendering blockId)
          )
        |> catchUpCloningHelper blockId environment

jsonEncodeSymbolRendering : SymbolRendering -> Json.Encode.Value
jsonEncodeSymbolRendering symbolRendering =
  let
    blockValues = List.map jsonEncodeBlock symbolRendering.blocks
  in
    Json.Encode.object
    [ ( "blocks", Json.Encode.list blockValues )
    , ( "rootId", JsonEncodeUtils.maybeString symbolRendering.rootId)
    ]
