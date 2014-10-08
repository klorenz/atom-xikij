"""
$ npm install atom-syntax-tools

$ coffee grammar-xikij.coffee

"""

makeGrammar = require "atom-syntax-tools"

highlight_expanded_file = (suffix, scope) ->
  {
    N: "meta.embedded.block.#{scope}"
    b: "^(\\s*)(-)\\s(.*/|).*\\.#{suffix}$"
    #b: "^(\\s*)(-)\\s.*(\\.#{suffix})$"
    c:
      2: "keyword.operator"
      3:
        p: "#xikijPath"

    p: scope
    e: /^{laNotIndented}/
  }


grammar =
  name: "Xikij"
  scopeName: "source.xikij"
  injectionSelector: "text, source"
  macros:
    lbNoBackslash: "(?<!\\\\)"
    #laNotIndented: "(?!\\1\\s|\\n)"
    laNotIndented: "(?!\\1\\s|\\n)"
    lbLeftPathSep: "(?<=/|\\s)"

  # entry points for xikij parsing
  patterns: [


    # make sure that final filename is not matched here, such that file specific
    # syntax can be detected
    {
      m: /^(\s*)(\+)\s(.*)$/
      c:
        2:
          n: "keyword.operator"
        3:
          p: "#xikijPath"
    }
    {
      b: /^(\s*)(~~|~)(?=\/|$)/
      c:
        2: "variable.language"
      e: /^{laNotIndented}/
      p: "#xikijPath"
    }
    {
      b: /^(\s*)(\.\.)(?=\/|$)/
      c:
        2: "constant.directory.parent"
      e: /^{laNotIndented}/
      p: "#xikijPath"
    }
    {
      b: /^(\s*)(\.)(?=\/|$)/
      c:
        2: "constant.directory.current"
      e: /^{laNotIndented}/
      p: "#xikijPath"
    }
    {
      m: /^\s*(\/.*)$/
      c:
        1:
          p: "#xikijPath"
    }

    "#shellCommand"

    highlight_expanded_file("py", "source.python")
    highlight_expanded_file("coffee", "source.coffee")
    highlight_expanded_file("cson", "source.coffee")
    highlight_expanded_file("json", "source.json")
    highlight_expanded_file("(cc|cxx|cpp|hh|hxx|hpp|inc|inl|imp|impl)", "source.c++")
    highlight_expanded_file("(c|h)", "source.c")
    highlight_expanded_file("rst", "text.restructuredtext")
    highlight_expanded_file("sh", "source.shell")
    highlight_expanded_file("rb", "source.ruby")
    highlight_expanded_file("mak", "source.makefile")
    highlight_expanded_file("less", "source.css.less")

    {
      m: /^(\s*)(-)\s(.*)$/
      c:
        2:
          n: "keyword.operator"
        3:
          p: "#xikijPath"
    }
    # {
    #   b: /^(?=(\s*)\$\s)/
    #   p: [
    #     "#shellCommand"
    #     "#shellCommandOutput"
    #   ]
    #   e: /^{laNotIndented}/
    # }
  ]
  repository:
    xikijPath: [
      {
        m: /(\/)/
        n: "punctuation.separator.path"
      }
      {
        m: /{lbLeftPathSep}(\.\.)(?=\/|$)/
        n: "constant.directory.parent"
      }
      {
        m: /{lbLeftPathSep}(\.)(?=\/|$)/
        n: "constant.directory.current"
      }
      {
        m: /{lbLeftPathSep}(\.\w+)(?=\/|$)/
        n: "variable.language"
      }
      {
        m: /(\[)(\d+)(\])(?=\/|$)/
        c:
          1: "punctuation.definition.list.begin"
          2: "constant.numeric.integer"
          3: "punctuation.definition.list.end"

        n: "meta.structure.list"
      }
    ]
    shellCommand: [
      # shell with continuation lines
      # {
      #   N: "meta.command"
      #   b: /^\s*(\$)\s(?=.*\\\n)/
      #   c:
      #     1: "keyword.operator"
      #   e: '(?<!\\\\)\\n$'
      #   p: [
      #     "#source.shell"
      #     {
      #       m: /\s(--?)([\w\-]+)(=)?/
      #       c:
      #         1: "keyword.operator"
      #         2: "variable.parameter.function"
      #         3: "keyword.operator.assignment"
      #     }
      #   ]
      # }

      {
        b: /^(\s*)(\$)\s(.*)/
        c:
          2: "keyword.operator"
          3: {
            n: "meta.command"
            p: [
               "source.shell"
               {
                 m: /\s(--?)([\w\-]+)(=)?/
                 c:
                   1: "keyword.operator"
                   2: "variable.parameter.function"
                   3: "keyword.operator.assignment"
               }
            ]
          }
        e: /^(?!\1\s)/
        p: [ "#shellCommandOutput" ]
      }
    ]
    shellCommandOutput: [
      {
        m: "(?i).*\\berror\\b.*"
        n: "error"
      }
    ]


if require.main is module
  path = require "path"
  makeGrammar grammar, path.resolve(__dirname, "..", "grammars", "xikij.cson")
