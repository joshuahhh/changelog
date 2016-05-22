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
import Story exposing ( Story )

-- And here's the dynamic world of (partially) rendered logs

type alias SymbolRendering =
  { blocks : List Block
  , rootId : Maybe BlockId
  }

-- To apply a symbol's change in a cloning of that symbol (in a symbol
-- rendering), you need to know which cloning you're working with, so you know
-- how to resolve the cloning-specific IDs into symbol-rendering IDs. You refer
-- to that with a ChangeContext. A ChangeContext of Nothing means that you're
-- working wit hthe symbol-rendering's root context – outside of any clonings.
type alias ChangeContext = Maybe BlockId

type alias ChangeInContext =
  { change : Change
  , changeContext : ChangeContext
  }

changeInContextToString : ChangeInContext -> String
changeInContextToString { change, changeContext } =
  let
    contextPart =
      case changeContext of
        Just changeContext -> "in '" ++ changeContext ++ "', "
        Nothing        -> "in root context, "
  in
    contextPart ++ (changeToString change)

runSetRoot : Cloning -> Maybe BlockId -> Environment -> Story SymbolRendering -> Story SymbolRendering
runSetRoot cloning changeContext environment =
  Story.map (\ symbolRendering ->
    let
      newBlock = cloningToBlock cloning changeContext
      newBlocks = newBlock ::
        case changeContext of
          Just blockId ->
            mapWhen
              (idIs blockId)
              (setRootOfCloning newBlock.id)
              symbolRendering.blocks
          Nothing ->
            symbolRendering.blocks
      newRootId =
        case changeContext of
          Just blockId -> symbolRendering.rootId
          Nothing -> Just cloning.id
      newSymbolRendering = { symbolRendering | blocks = newBlocks, rootId = newRootId }
    in
      newSymbolRendering
  )

runAppendChild : NodeId -> Cloning -> ChangeContext -> Environment -> Story SymbolRendering -> Story SymbolRendering
runAppendChild nodeId cloning changeContext environment =
  let
    newBlock = cloningToBlock cloning changeContext
    blockIdOfParent = constructBlockId changeContext nodeId
  in
    catchUpNode blockIdOfParent changeContext environment
    >>
    Story.step "and now the intended operation" (Story.map (\ symbolRendering ->
      let
        newBlocks = newBlock ::
          mapWhen
            (idIs blockIdOfParent)
            (appendChildToNode (constructBlockId changeContext cloning.id))
            symbolRendering.blocks
        newSymbolRendering = { symbolRendering | blocks = newBlocks }
      in
        newSymbolRendering
    ))
    >>
    Story.flattenLastIfLonesome

runChangeInContext : ChangeInContext -> Environment -> Story SymbolRendering -> Story SymbolRendering
runChangeInContext { change, changeContext } =
  case change of
    SetRoot cloning ->
      runSetRoot cloning changeContext
    AppendChild nodeId cloning ->
      runAppendChild nodeId cloning changeContext

runChangeInContextAsStep : ChangeInContext -> Environment -> Story SymbolRendering -> Story SymbolRendering
runChangeInContextAsStep changeInContext environment =
  Story.step
    (changeInContextToString changeInContext)
    (runChangeInContext changeInContext environment)

incrementNextChangeOfCloningInSymbolRendering : BlockId -> SymbolRendering -> SymbolRendering
incrementNextChangeOfCloningInSymbolRendering blockId symbolRendering =
  { symbolRendering | blocks =
      symbolRendering.blocks |>
        mapWhen (idIs blockId) incrementNextChangeIdxOfCloning
  }

catchUpNode : BlockId -> ChangeContext -> Environment -> Story SymbolRendering -> Story SymbolRendering
catchUpNode blockId changeContext environment story =
  let
    allCloningIds = blockId |> ownerHierarchy
    cloningIdsToCheck =
      case changeContext of
        Just changeContext -> allCloningIds |> List.filter (\ owner -> changeContext |> String.startsWith owner |> not)
        Nothing -> allCloningIds
  in
    List.foldl (\ cloningId story -> catchUpCloning cloningId environment story) story cloningIdsToCheck

catchUpCloning : BlockId -> Environment -> Story SymbolRendering -> Story SymbolRendering
catchUpCloning blockId environment =
  Story.step ("catch up cloning '" ++ blockId ++ "'")
    (catchUpCloningHelper blockId environment)

catchUpCloningHelper : BlockId -> Environment -> Story SymbolRendering -> Story SymbolRendering
catchUpCloningHelper blockId environment =
  Story.do (\ symbolRendering ->
    let
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
        identity
      else
        -- catch up one change, then recurse
        let
          change = changes |> Array.get nextChangeIdx |> unwrapOrCrash "Could not find nextChangeIdx"
          changeInContext = { change = change, changeContext = Just blockId }
          changeNarration =
            cloningBody.symbolId ++ " step " ++ (toString nextChangeIdx) ++ ":\n"
            ++ (changeInContextToString changeInContext)
        in
          Story.step changeNarration (
            runChangeInContext changeInContext environment
            >>
            Story.map (incrementNextChangeOfCloningInSymbolRendering blockId))
          >>
          catchUpCloningHelper blockId environment
  )

jsonEncodeSymbolRendering : SymbolRendering -> Json.Encode.Value
jsonEncodeSymbolRendering symbolRendering =
  let
    blockValues = List.map jsonEncodeBlock symbolRendering.blocks
  in
    Json.Encode.object
    [ ( "blocks", Json.Encode.list blockValues )
    , ( "rootId", JsonEncodeUtils.maybeString symbolRendering.rootId)
    ]
