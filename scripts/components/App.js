import React from 'react';

import {Box} from '../Constraints';
import {TreeLayout} from '../TreeLayout';
// import {TreeLayout} from '../TreeLayoutN';

const myTree = {
  name: "Parent",
  children: [{
    name: "Child 2",
    children: [{
      name: "Grandchild 2.1"
    }, {
      name: "Grandchild 2.2"
    }, {
      name: "Grandchild 2.3"
    }, {
      name: "Grandchild 2.4",
      children: [{
        name: "GGC 2.4.1"
      }, {
        name: "GGC 2.4.2"
      }]
    }]
  }, {
    name: "Child 3",
    children: [{
      name: "Grandchild 3.1",
      children: [{
        name: "GGC 3.1.1"
      }, {
        name: "GGC 3.1.2"
      }]
    }, {
      name: "Grandchild 3.2"
    }, {
      name: "Grandchild 3.3"
    }, {
      name: "Grandchild 3.4"
    }]
  }]
}

// const myTree = {
//   name: "Parent",
//   children: [{
//     name: "Child 1"
//   }, {
//     name: "Child 2"
//   }, {
//     name: "Child 3"
//   }]
// }

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
        <svg width="1000" height="1000">
          {treeLayout.boxes.map((box) =>
            box.parentBox &&
              <line
                x1={box.centerX.value} y1={box.centerY.value}
                x2={box.parentBox.centerX.value} y2={box.parentBox.centerY.value}
                stroke="black"
              />
          )}
          {treeLayout.boxes.map((box) =>
            <g transform={"translate(" + box.left.value + "," + box.top.value + ")"}>
              <rect width={box.width.value} height={box.height.value} fill="white" stroke="black"/>
              <text x="5" y="20">{box.name}</text>
            </g>
          )}
        </svg>
      </div>
    );
  },
});

export default App;
