import React from 'react';

import {Box} from '../Constraints';


var App = React.createClass({
  render() {
    var solver = new c.SimplexSolver();

    var box1 = new Box('box1', {width: 200, height: 200});
    var box2 = new Box('box2', {width: 200, height: 100});
    solver.addStay(box1.width);
    solver.addStay(box1.height);
    solver.addStay(box2.width);
    solver.addStay(box2.height);

    solver.addConstraint(new c.Equation(box1.left, 0));
    solver.addConstraint(new c.Equation(box1.top, 0));

    solver.addConstraint(new c.Equation(box2.left, c.plus(box1.right, 10)));
    solver.addConstraint(new c.Equation(box2.bottom, box1.bottom));

    box1.getConstraints().map(solver.addConstraint.bind(solver))
    box2.getConstraints().map(solver.addConstraint.bind(solver))

    solver.resolve();

    return (
      <div>
        <div>{JSON.stringify(box1.getBoundValues())}</div>
        <div>{JSON.stringify(box2.getBoundValues())}</div>
        <svg width="500" height="500">
          <rect x={box1.left.value} y={box1.top.value} width={box1.width.value} height={box1.height.value} />
          <rect x={box2.left.value} y={box2.top.value} width={box2.width.value} height={box2.height.value} />
        </svg>
      </div>
    );
  },
});

export default App;
