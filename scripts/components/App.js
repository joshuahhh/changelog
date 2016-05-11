import React from 'react';
// import _ from 'underscore';
import {node, transform, group} from '../SymbolDiagram';
import {SymbolDiagramLayout} from '../SymbolDiagramLayout';

const WigglyLine = ({x1, y1, x2, y2, ...otherProps}) =>
  <g>
    <line x1={x1} y1={y1} x2={x1} y2={y2 + 40} {...otherProps}/>
    <line x1={x1} y1={y2 + 40} x2={x2} y2={y2 + 40} {...otherProps}/>
    <line x1={x2} y1={y2 + 40} x2={x2} y2={y2} {...otherProps}/>
  </g>;

var App = React.createClass({
  render() {
    var then = +(new Date());
    var symbolDiagram = group.clone('Top-Group').appendChild('Top-Group/group/node', group.clone('Bottom-Group'));
    // console.log(symbolDiagram);
    var layout = new SymbolDiagramLayout(symbolDiagram);
    // var layout = new SymbolDiagramLayout(group);
    layout.resolve();
    console.log(+(new Date()) - then);

    return (
      <div>
        <svg width="1200" height="1000">
          {layout.nodes.map((node) =>
            node.childIds.map((childId) => {
              const childCloning = layout.cloningsById[childId];
              const underlyingNode = layout.nodesById[childCloning.underlyingNodeId];
              return (
                <WigglyLine
                  x1={underlyingNode.box.centerX.value} y1={underlyingNode.box.top.value}
                  x2={node.box.centerX.value} y2={node.box.bottom.value}
                  stroke="#888888" strokeWidth="2"
                />);
            })
          )}
          {layout.nodes.map((node) =>
            <g transform={"translate(" + node.box.left.value + "," + node.box.top.value + ")"}>
              <rect width={node.box.width.value} height={node.box.height.value} fill="#F2F2F2" stroke="black"/>
            </g>
          )}
          {layout.clonings.map((cloning) =>
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
          )}
        </svg>
      </div>
    );
  },
});

export default App;
