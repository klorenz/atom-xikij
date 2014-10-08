"""
$ coffee shell-command-line.coffee
  write /home/kiwi/xikij/grammars/shell-command-line.cson
$ npm install season --save-dev $foo && foo

$ npm install

grammar-xikij.coffee


"""
makeGrammar = require "atom-syntax-tools"

grammar =
  name: "Shell Command Line"
  scopeName: "source.shell-commandline"
  fileTypes: []
  injectionSelector: 'text, source'
  patterns: [
    {
      N: "meta.command"
      b: /^\s*(\$)\s/
      c:
        1: "keyword.operator"
      e: '(?<!\\\\)\\n$'
      p: [
        "#source.shell"
        {
          m: /\s(--?)([\w\-]+)(=)?/
          c:
            1: "keyword.operator"
            2: "variable.parameter.function"
            3: "keyword.operator.assignment"
        }
      ]
    }
  ]

if require.main is module
  path = require "path"
  outputfile = path.join __dirname, "..", "grammars", "shell-command-line.cson"
  makeGrammar grammar, outputfile

module.exports = makeGrammar grammar
