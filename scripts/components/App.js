import React from 'react';
// import _ from 'underscore';

import SimpleSymbolDiagram from './SimpleSymbolDiagram';
import Story from './Story';

import {SymbolDiagram} from '../SymbolDiagram';

import ElmDemoGroupInGroup from 'exports?Elm!../DemoGroupInGroup';
import ElmDemoInfinite from 'exports?Elm!../DemoInfinite';
import ElmDemoAutoCatchUp from 'exports?Elm!../DemoAutoCatchUp';
const DemoGroupInGroup = ElmDemoGroupInGroup.DemoGroupInGroup.make(ElmDemoGroupInGroup);
const DemoInfinite = ElmDemoInfinite.DemoInfinite.make(ElmDemoInfinite);
const DemoAutoCatchUp = ElmDemoAutoCatchUp.DemoAutoCatchUp.make(ElmDemoAutoCatchUp);
window.DemoGroupInGroup = DemoGroupInGroup;
window.DemoInfinite = DemoInfinite;
window.DemoAutoCatchUp = DemoAutoCatchUp;


var App = React.createClass({
  render() {
    // const {storyInJson, environmentInJson} = DemoGroupInGroup;
    // const {storyInJson, environmentInJson} = DemoInfinite;
    const {storyInJson, environmentInJson} = DemoAutoCatchUp;

    return (
      <div style={{paddingTop: 20, paddingLeft: 20}}>
        <Story
          story={storyInJson}
          characterRenderer={(symbolRendering =>
            <SimpleSymbolDiagram
              symbolDiagram={new SymbolDiagram(symbolRendering.blocks, symbolRendering.rootId)}
              environment={environmentInJson} />
            )}
          showStart={true} />
      </div>
    );
  },
});

export default App;
