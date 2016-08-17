import React from 'react';
import _ from 'underscore';

import {byType} from '../SymbolDiagram';
import {SymbolDiagramLayout} from '../SymbolDiagramLayout';

const SimpleSymbolDiagram = React.createClass({
  render() {
    const {symbolDiagram, environment} = this.props;
    const style = {verticalAlign: 'top'};

    if (!symbolDiagram.rootId) {
      return <span style={{fontStyle: 'italic', ...style}}>[Empty]</span>;
    }

    const then = +(new Date());
    const layout = new SymbolDiagramLayout(symbolDiagram);
    layout.resolve();
    console.log('laid out in', +(new Date()) - then);

    const svgWidth = _.max(layout.blocks.map((block) => block.outerBox.right.value)) + 2;
    const svgHeight = _.max(layout.blocks.map((block) => block.outerBox.bottom.value)) + 2;

    return (
      <svg width={svgWidth} height={svgHeight} style={style}>
        {layout.blocks.map((block) => block.type == 'node' &&
          block.childIds.map((childId) => {
            const child = layout.blocksById[childId];
            const deepestRoot = layout.blocksById[child.deepestRootId]; // || child;
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
          node: (node) => <SimpleSymbolDiagramNode node={node} />,
          cloning: (cloning) => <SimpleSymbolDiagramCloning cloning={cloning} environment={environment} />
        }))}
      </svg>
    );
  },
});

const WigglyLine = ({x1, y1, x2, y2, ...otherProps}) =>
  <g>
    <line x1={x1} y1={y1} x2={x1} y2={y2 + 20} {...otherProps}/>
    <line x1={x1} y1={y2 + 20} x2={x2} y2={y2 + 20} {...otherProps}/>
    <line x1={x2} y1={y2 + 20} x2={x2} y2={y2} {...otherProps}/>
  </g>;

const SimpleSymbolDiagramNode = React.createClass({
  getInitialState() {
    return {
      hovered: false,
    };
  },

  render() {
    const {node} = this.props;
    const {hovered} = this.state;

    return (
      <g onMouseOver={() => this.setState({hovered: true})} onMouseOut={() => this.setState({hovered: false})}>
        <rect
          x={node.outerBox.left.value} y={node.outerBox.top.value}
          width={node.outerBox.width.value} height={node.outerBox.height.value} fill={hovered ? "#E2D2D2" : "#F2F2F2"} stroke="black"/>
        <text
            x={node.outerBox.centerX.value} y={node.outerBox.top.value + 2}
            style={{dominantBaseline: 'hanging', textAnchor: 'middle', fontSize: 8}}>
          {node.localId}
        </text>
      </g>
    );
  }
});

const SimpleSymbolDiagramCloning = React.createClass({
  render() {
    const {cloning, environment} = this.props;

    return (
      <g>
        <rect
          x={cloning.innerBox.left.value} y={cloning.innerBox.top.value}
          width={cloning.innerBox.width.value} height={cloning.innerBox.height.value}
          fill="none" stroke="gray" strokeDasharray="4" strokeWidth="1"/>
        <g transform={`translate(${cloning.innerBox.right.value + 5}, ${cloning.innerBox.top.value + 2})`}>
          <text
              style={{dominantBaseline: 'hanging', fontSize: 8}}>
            {cloning.localId}
          </text>
          <text
              y={10}
              style={{dominantBaseline: 'hanging', fontSize: 8}}>
            {cloning.symbolId}
          </text>
          <text
              y={20}
              style={{dominantBaseline: 'hanging', fontSize: 8}}>
            {cloning.nextChangeIdx + ' / ' + environment.symbols[cloning.symbolId].changes.length}
          </text>
        </g>
      </g>
    );
  }
});

export default SimpleSymbolDiagram;
