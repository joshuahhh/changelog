import React from 'react';
import _ from 'underscore';

const nl2br = (text) => text.split('\n').map((line) =>
  <span>
    {line}
    <br/>
  </span>
);

const storyIsNotEmpty = (story) =>
  _.any(story.steps.map((step) => step.narration));


const Story = ({story, characterRenderer, showStart}) =>
  <table>
    <tbody>
      {showStart &&
        <tr>
          <td style={{textAlign: 'right', verticalAlign: 'top', paddingRight: 30}}>
            start
          </td>
          <td style={{textAlign: 'left', verticalAlign: 'top', paddingRight: 30, paddingBottom: 35}}>
            {characterRenderer(story.start)}
          </td>
        </tr>
      }
      {story.steps.map((step, i) =>
        step.narration &&
          <tr key={i}>
            <td style={{textAlign: 'right', verticalAlign: 'top', paddingRight: 30}}>
              {nl2br(step.narration)}
            </td>
            {storyIsNotEmpty(step.explanation) &&
              <td style={{textAlign: 'left', verticalAlign: 'top', paddingRight: 30, paddingBottom: 35}}>
                <div style={{border: '1px solid gray', padding: 10, boxShadow: '0px 0px 10px lightgray'}}>
                  <Story story={step.explanation} characterRenderer={characterRenderer} />
                </div>
              </td>
            }
            {!storyIsNotEmpty(step.explanation) &&
              <td style={{textAlign: 'left', verticalAlign: 'top', paddingRight: 30, paddingBottom: 35}}>
                {characterRenderer(step.after)}
              </td>
            }
          </tr>
      )}
    </tbody>
  </table>;

export default Story;
