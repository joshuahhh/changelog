import React from 'react';
import _ from 'underscore';

import {Box} from '../Constraints';
import {TreeLayout} from '../TreeLayout';
// import {TreeLayout} from '../TreeLayoutN';

const myTree = {
  id: "Parent",
  children: [{
    id: "Child 2",
    children: [{
      id: "Grandchild 2.1"
    }, {
      id: "Grandchild 2.2"
    }, {
      id: "Grandchild 2.3"
    }, {
      id: "Grandchild 2.4",
      children: [{
        id: "GGC 2.4.1"
      }, {
        id: "GGC 2.4.2"
      }]
    }]
  }, {
    id: "Child 3",
    children: [{
      id: "Grandchild 3.1",
      children: [{
        id: "GGC 3.1.1"
      }, {
        id: "GGC 3.1.2"
      }]
    }, {
      id: "Grandchild 3.2"
    }, {
      id: "Grandchild 3.3"
    }, {
      id: "Grandchild 3.4"
    }]
  }]
};

const myCrazyThing = {
  rootBox: {
    id: 'Group',
    cloneBoxId: 'Group-cloning',
    children: [{
      id: 'Transform',
      cloneBoxId: 'Group-cloning'
    }, {
      id: 'Smile',
      cloneBoxId: 'Smile-cloning',
      children: [{
        id: 'Happiness',
        cloneBoxId: 'Smile-cloning'
      }, {
        id: 'Circle',
        cloneBoxId: 'Circle-cloning'
      }]
    }]
  },
  cloneBoxes: [{
    id: 'Group-cloning'
  }, {
    id: 'Smile-cloning'
  }, {
    id: 'Circle-cloning',
    parentId: 'Smile-cloning'
  }]
}

const WigglyLine = ({x1, y1, x2, y2, ...otherProps}) =>
  <g>
    <line x1={x1} y1={y1} x2={x1} y2={(y1 + y2) / 2} {...otherProps}/>
    <line x1={x1} y1={(y1 + y2) / 2} x2={x2} y2={(y1 + y2) / 2} {...otherProps}/>
    <line x1={x2} y1={(y1 + y2) / 2} x2={x2} y2={y2} {...otherProps}/>
  </g>;

var App = React.createClass({
  render() {
    var then = +(new Date());
    var treeLayout = new TreeLayout(myTree);
    treeLayout.resolve();
    console.log(+(new Date()) - then);

    return (
      <div>
        {/*
        {treeLayout.boxes.map((box) =>
          <pre>
            {JSON.stringify(box.variables, null, 4)}
          </pre>
        )}
        */}
        <svg width="1200" height="1000">
          {_.map(treeLayout.boxesById, (box) => {
            if (box.parentId) {
              const parentBox = treeLayout.boxesById[box.parentId];
              return (
                <WigglyLine
                  x1={box.centerX.value} y1={box.centerY.value}
                  x2={parentBox.centerX.value} y2={parentBox.centerY.value}
                  stroke="black"
                />);
            }
          })}
          {_.map(treeLayout.boxesById, (box) =>
            <g transform={"translate(" + box.left.value + "," + box.top.value + ")"}>
              <rect width={box.width.value} height={box.height.value} fill="white" stroke="black"/>
              <text x="5" y="20">{box.id}</text>
            </g>
          )}
        </svg>
      </div>
    );
  },
});

export default App;
