module SymbolRendering where

import Json.Encode

import Util exposing ( mapWhen, idIs, find )
import Symbol exposing ( SymbolId, NodeId, SymbolRef(..), Cloning, Change(..) )

-- And here's the dynamic world of (partially) rendered logs

type alias SymbolRendering =
  { blocks : List Block
  , rootId : Maybe BlockId
  }

type alias BlockId = String

type alias Block =
  { id : BlockId
  , ownerId : Maybe BlockId
  , body : BlockBody
  }

type BlockBody = NodeBodyAsBlockBody NodeBody | CloningBodyAsBlockBody CloningBody

type alias NodeBody =
  { childIds: List BlockId }

type alias CloningBody =
  { rootId: Maybe BlockId, symbolId: SymbolId, nextChange: Int }

constructBlockId : Maybe BlockId -> NodeId -> BlockId
constructBlockId maybeBlockId nodeId =
  case maybeBlockId of
    Just blockId -> blockId ++ "/" ++ nodeId
    Nothing -> nodeId

cloningToBlock : Cloning -> Maybe BlockId -> Block
cloningToBlock cloning maybeOwnerId =
  let
    newId = constructBlockId maybeOwnerId cloning.id
    newBody = case cloning.symbolRef of
      BareNode ->
        NodeBodyAsBlockBody { childIds = [] }
      SymbolIdAsRef symbolId ->
        CloningBodyAsBlockBody { rootId = Nothing, symbolId = symbolId, nextChange = 0 }
  in
    Block newId maybeOwnerId newBody

appendChildToBlockWhichMustBeNode : BlockId -> Block -> Block
appendChildToBlockWhichMustBeNode childId block =
  let
    oldNodeBody = case block.body of
      NodeBodyAsBlockBody oldNodeBody -> oldNodeBody
      _ -> Debug.crash "you can only add a child to a node!"
    newBody = NodeBodyAsBlockBody { oldNodeBody | childIds = childId :: oldNodeBody.childIds }
  in
    { block | body = newBody }

setRootOfBlockWhichMustBeCloning : BlockId -> Block -> Block
setRootOfBlockWhichMustBeCloning rootId block =
  let
    oldCloningBody = case block.body of
      CloningBodyAsBlockBody oldCloningBody -> oldCloningBody
      _ -> Debug.crash "you can only set the root of a cloning!"
    newBody = CloningBodyAsBlockBody { oldCloningBody | rootId = Just rootId }
  in
    { block | body = newBody }

runChangeInSymbolRendering : SymbolRendering -> Maybe BlockId -> Change -> SymbolRendering
runChangeInSymbolRendering symbolRendering maybeBlockId change =
  case change of
    SetRoot cloning ->
      let
        newBlock = cloningToBlock cloning maybeBlockId
        newBlocks = newBlock ::
          case maybeBlockId of
            Just blockId ->
              mapWhen
                (idIs blockId)
                (setRootOfBlockWhichMustBeCloning newBlock.id)
                symbolRendering.blocks
            Nothing ->
              symbolRendering.blocks
        newRootId =
          case maybeBlockId of
            Just blockId -> symbolRendering.rootId
            Nothing -> Just cloning.id
      in
        { symbolRendering | blocks = newBlocks, rootId = newRootId }
    AppendChild nodeId cloning ->
      let
        newBlock = cloningToBlock cloning maybeBlockId
        blockIdOfParent = constructBlockId maybeBlockId nodeId
        newBlocks = newBlock ::
          mapWhen
            (idIs blockIdOfParent)
            (appendChildToBlockWhichMustBeNode (constructBlockId maybeBlockId cloning.id))
            symbolRendering.blocks
        newRootId = Just cloning.id
      in
        { symbolRendering | blocks = newBlocks }

type ExtractedNode =
  ExtractedNode { id : BlockId, children : List ExtractedNode }

extractNodes : SymbolRendering -> Maybe ExtractedNode
extractNodes { blocks, rootId } =
  case rootId of
    Just rootId -> extractNodesFromRoot blocks rootId
    Nothing -> Nothing

extractNodesFromRoot : List Block -> BlockId -> Maybe ExtractedNode
extractNodesFromRoot blocks rootId =
  let
    rootBlock = find (idIs rootId) blocks
  in
    case rootBlock.body of
      CloningBodyAsBlockBody cloningBody ->
        case cloningBody.rootId of
          Just rootId -> extractNodesFromRoot blocks rootId
          Nothing -> Nothing
      NodeBodyAsBlockBody blockBody ->
        Just (ExtractedNode
          { id = rootBlock.id
          , children = List.filterMap (extractNodesFromRoot blocks) blockBody.childIds })

jsonEncodeMaybeString : Maybe String -> Json.Encode.Value
jsonEncodeMaybeString maybeString =
  Maybe.map Json.Encode.string maybeString |> Maybe.withDefault Json.Encode.null

blockWithNodeBodyToThatJsonFormatIUse : Block -> NodeBody -> Json.Encode.Value
blockWithNodeBodyToThatJsonFormatIUse block nodeBody =
  Json.Encode.object
  [ ( "id", Json.Encode.string block.id )
  , ( "childIds", Json.Encode.list (List.map Json.Encode.string nodeBody.childIds) )
  ]

blockWithCloningBodyToThatJsonFormatIUse : Block -> CloningBody -> Json.Encode.Value
blockWithCloningBodyToThatJsonFormatIUse block cloningBody =
  Json.Encode.object
  [ ( "id", Json.Encode.string block.id )
  , ( "ownerId", jsonEncodeMaybeString block.ownerId )
  , ( "rootId", jsonEncodeMaybeString cloningBody.rootId )
  ]

symbolRenderingToThatJsonFormatIUse : SymbolRendering -> Json.Encode.Value
symbolRenderingToThatJsonFormatIUse symbolRendering =
  let
    nodeValues = List.filterMap
      (\block -> case block.body of
        NodeBodyAsBlockBody nodeBody ->
          Just (blockWithNodeBodyToThatJsonFormatIUse block nodeBody)
        _ ->
          Nothing)
      symbolRendering.blocks
    cloningValues = List.filterMap
      (\block -> case block.body of
        CloningBodyAsBlockBody cloningBody ->
          Just (blockWithCloningBodyToThatJsonFormatIUse block cloningBody)
        _ ->
          Nothing)
      symbolRendering.blocks
  in
    Json.Encode.object
    [ ( "nodes", Json.Encode.list nodeValues )
    , ( "clonings", Json.Encode.list cloningValues )
    , ( "rootCloningId", jsonEncodeMaybeString symbolRendering.rootId)
    ]
