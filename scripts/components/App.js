import React from 'react';
// import _ from 'underscore';

import SimpleSymbolDiagram from './SimpleSymbolDiagram';

import {SymbolDiagram} from '../SymbolDiagram';

import Elm from 'exports?Elm!../Main';
const ElmMain = Elm.Main.make(Elm);
window.Elm = Elm;
window.ElmMain = ElmMain;

var App = React.createClass({
  render() {
    // const symbolDiagram = group.clone('Top-Group').appendChild('Top-Group/group/node', group.clone('Bottom-Group'));
    const {symbolRenderingsInJson} = ElmMain;
    window.symbolRenderingsInJson = symbolRenderingsInJson;
    const symbolDiagrams = symbolRenderingsInJson.map((symbolDiagramJson) =>
      new SymbolDiagram(symbolDiagramJson.blocks, symbolDiagramJson.rootId));

    return (
      <div style={{paddingTop: 20}}>
        {symbolDiagrams.map((symbolDiagram) => <SimpleSymbolDiagram symbolDiagram={symbolDiagram} />)}
      </div>
    );
  },
});

export default App;
