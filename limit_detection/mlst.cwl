cwlVersion: v1.0
class: CommandLineTool
baseCommand: mlst
stdout: ${
        var splitAll = function (str) {
            return str.split('\\').pop().split('/').reverse()[0].split('_')[0];
            };
        var dir = splitAll(inputs.contigs.location);
        return dir + '_mlst.tab';
        }
inputs:
  contigs:
    type: File
    inputBinding:
      position: 1
outputs:
    mlstout:
        type: stdout
