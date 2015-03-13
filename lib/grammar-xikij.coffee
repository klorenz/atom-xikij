"""

$ coffee grammar-xikij.coffee

../../filter-lines

"""

makeGrammar = require "atom-syntax-tools"

# return a block, which includes scope for given file suffix
#
# In a xikij tree view, you can open files inline.  This is responsible
# for highlighting it.
highlight_expanded_file = (suffix, scope) ->
  if suffix instanceof RegExp
    suffix = suffix.source
  else if suffix[0] == '.'
    suffix = "\\#{suffix}$"
  else
    suffix = "#{suffix}$"

  {
    N: "meta.embedded.block.#{scope}"
    b: "^(\\s*)(-)\\s(.*/|).*#{suffix}"
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
  injectionSelector: "text, text markup.raw, source string.heredoc, source string.double.heredoc, source string.quoted.double.heredoc, source comment.block, source.gfm, source markup.raw"
  fileTypes: ["xikij"]

  # Lookbehinds are not supported by javascript regexes, so use macros for
  # them.
  macros:
    lbNoBackslash: "(?<!\\\\)"
    #laNotIndented: "(?!\\1\\s|\\n)"
    laNotIndented: "(?!\\1\\s|\\n)"
    lbLeftPathSep: "(?<=/|\\s)"
    csonNumeric: /\b((0([box])[0-9a-fA-F]+)|([0-9]+(\.[0-9]+)?(e[+\-]?[0-9]+)?))\b/
    csonTrue: /\b(true|on|yes)\b/
    csonFalse: /\b(false|off|no)\b/
    csonNull: /\b(null)\b/
    laCson: /(?=(?:""".*|'''.*|".*"|'.*'|{csonNumeric}|{csonTrue}|{csonFalse}|{csonNull})\s*$)/

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
      m: /^(\s*)(~~|~)(\/.*|$)/
      c:
        2: "variable.language"
        3:
          p: "#xikijPath"
    }
    {
      m: /^(\s*)(\.\.)(\/.*|$)/
      c:
        2: "constant.directory.parent"
        3:
          p: "#xikijPath"
    }
    {
      m: /^(\s*)(\.)(\/.*|$)/
      c:
        2: "constant.directory.current"
        3:
          p: "#xikijPath"
    }
    {
      b: /^(\s*){laCson}/
      L: yes
      e: /(?=[\s\S])/
      p: "#cson"
    }
    {
      b: /^(\s*)([\w\-]+)(:)\s+{laCson}/
      c:
        2: "entity.name"
        3: "keyword.operator.definition"
      p: "#cson"
      L: yes
      e: /(?=[\s\S])/
    }
    {
      m: /^(\s*)([\w\-]+)(:)(?=\s|$)/
      c:
        2: "entity.name"
        3: "keyword.operator.definition"
      p: "#cson"
      L: yes
      e: /(?=[\s\S])/
    }
    {
      m: /^\s*(\/.*)$/
      c:
        1:
          p: "#xikijPath"
    }

    {
      m: /^\s*((!) .*)/
      c:
        1: "keyword.operator"
        2: "error.exception"
    }

    "#shellCommand"

    highlight_expanded_file(".py", "source.python")
    highlight_expanded_file(".coffee", "source.coffee")
    highlight_expanded_file(".cson", "source.coffee")
    highlight_expanded_file(".json", "source.json")
    highlight_expanded_file(".(cc|cxx|cpp|hh|hxx|hpp|inc|inl|imp|impl)", "source.cpp")
    highlight_expanded_file(".(c|h)", "source.c")
    highlight_expanded_file(".rst", "text.restructuredtext")
    highlight_expanded_file(".sh", "source.shell")
    highlight_expanded_file(".css", "source.css")
    highlight_expanded_file(".html", "source.html")
    highlight_expanded_file(".php", "text.html.php")
    highlight_expanded_file(".xml", "source.xml")
    highlight_expanded_file(".sql", "source.sql")
    highlight_expanded_file(".rb", "source.ruby")
    highlight_expanded_file(".mak", "source.makefile")
    highlight_expanded_file("Makefile", "source.makefile")
    highlight_expanded_file(".less", "source.css.less")
    highlight_expanded_file(".md", "text.markdown")
    highlight_expanded_file(".cmake", "source.cmake")
    highlight_expanded_file("CMakeLists.txt", "source.cmake")

    {
      b: /^(\s*)(-)\s{laCson}/
      c:
        2:
          n: "keyword.operator"
      L: yes
      e: /(?=[\s\S])/
      p: "#cson"
    }

    {
      b: /^(\s*)(-)\s(?=.*$)/
      c:
        2:
          n: "keyword.operator"
      e: /$/
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
    cson: [
        # {
        #   b: /(''')/
        #   c:
        #     1: "punctuation.definition.string.begin"
        #   e: /(''')/
        #   c:
        #     1: "punctuation.definition.string.end"
        #   n: "string.quoted.heredoc"
        # }
        # {
        #   b: /(""")/
        #   c:
        #     1: "punctuation.definition.string.begin"
        #   e: /(""")/
        #   C:
        #     1: "punctuation.definition.string.end"
        #   n: "string.quoted.double.heredoc"
        # }
        "#csonSingleLineString"
        {
          m: /{csonNumeric}\s*$/
          n: "constant.numeric"
        }
        {
          m: /{csonTrue}\s*$/
          c:
            1: "constant.language.boolean.true"
        }
        {
          m: /{csonFalse}\s*$/
          c:
            1: "constant.language.boolean.false"
        }
        {
          m: /{csonNull}\s*$/
          c:
            1: "constant.language.boolean.null"
        }
      ]
    csonSingleLineString: [
      {
        b: '(?<!")(")(?!"")(?=.*"\\s*$)'
        c:
          1: "punctuation.definition.string.begin"
        e: /(")/
        C:
          1: "punctuation.definition.string.end"
        n: "string.quoted.double"
      }
      {
        b: "(?<!')(')(?!'')(?=.*'\\s*$)"
        c:
          1: "punctuation.definition.string.begin"
        e: /(')/
        C:
          1: "punctuation.definition.string.end"
        n: "string.quoted.single"
      }
    ]


if require.main is module
  path = require "path"
  makeGrammar grammar, path.resolve(__dirname, "..", "grammars", "xikij.cson")
