import React from 'react';
// import _ from 'underscore';
import {SymbolDiagram, node, transform, group, byType} from '../SymbolDiagram';
import {SymbolDiagramLayout} from '../SymbolDiagramLayout';

import Elm from 'exports?Elm!../Main';
const ElmMain = Elm.Main.make(Elm);
window.Elm = Elm;
window.ElmMain = ElmMain;

const WigglyLine = ({x1, y1, x2, y2, ...otherProps}) =>
  <g>
    <line x1={x1} y1={y1} x2={x1} y2={y2 + 20} {...otherProps}/>
    <line x1={x1} y1={y2 + 20} x2={x2} y2={y2 + 20} {...otherProps}/>
    <line x1={x2} y1={y2 + 20} x2={x2} y2={y2} {...otherProps}/>
  </g>;

var App = React.createClass({
  render() {
    var then = +(new Date());
    const symbolDiagram = group.clone('Top-Group').appendChild('Top-Group/group/node', group.clone('Bottom-Group'));
    // const symbolDiagramJson = ElmMain.finalJsonFormatIUse;
    // const symbolDiagram = new SymbolDiagram(symbolDiagramJson.nodes, symbolDiagramJson.clonings, symbolDiagramJson.rootCloningId);
    window.symbolDiagram = symbolDiagram;
    window.node = node;
    window.transform = transform;
    window.group = group;
    // console.log(symbolDiagram);
    var layout = new SymbolDiagramLayout(symbolDiagram);
    // var layout = new SymbolDiagramLayout(group);
    layout.resolve();
    console.log(+(new Date()) - then);

    return (
      <div>
        <svg width="2400" height="1000">
          {layout.blocks.map((block) => block.type == 'node' &&
            block.childIds.map((childId) => {
              const child = layout.blocksById[childId];
              const deepestRoot = layout.blocksById[child.deepestRootId];
              // TODO: get rid of this if a node gets an innerBox
              const deepestRootBox = deepestRoot.innerBox || deepestRoot.outerBox;
              return (
                <WigglyLine
                  x1={deepestRootBox.centerX.value} y1={deepestRootBox.top.value}
                  x2={block.outerBox.centerX.value} y2={block.outerBox.bottom.value}
                  stroke="#888888" strokeWidth="2"
                />);
            })
          )}
          {layout.blocks.map(byType({
            node: (node) =>
              <g transform={"translate(" + node.outerBox.left.value + "," + node.outerBox.top.value + ")"}>
                <rect width={node.outerBox.width.value} height={node.outerBox.height.value} fill="#F2F2F2" stroke="black"/>
              </g>,
            cloning: (cloning) =>
              <g>
                <rect
                  x={cloning.innerBox.left.value} y={cloning.innerBox.top.value}
                  width={cloning.innerBox.width.value} height={cloning.innerBox.height.value}
                  fill="none" stroke="gray" strokeDasharray="4" strokeWidth="1"/>
                <text
                    x={cloning.innerBox.right.value + 10} y={cloning.innerBox.top.value + 5}
                    style={{dominantBaseline: 'hanging', fontSize: 8}}>
                  {cloning.id}
                </text>
              </g>
          }))}
        </svg>
      </div>
    );
  },
});

export default App;
