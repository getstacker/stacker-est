CoffeeScript = require 'coffee-script'
esc = require './escape'

indentChars =
  ":": ":"
  ">": ">"

compile = (template, options) ->
  lineNo = 1
  bufferStack = ["__estOutput"]
  bufferStackPointer = 0
  buffer = bufferStack[bufferStackPointer] + " = '"
  matches = template.split(new RegExp(esc.regExp(options.open) + "((?:.|[\r\n])+?)(?:" + esc.regExp(options.close) + "|$)"))
  output = undefined
  text = undefined
  command = undefined
  line = undefined
  prefix = undefined
  postfix = undefined
  newline = undefined
  indentChar = undefined
  indentation = ""
  indent = false
  indentStack = []
  indentStackPointer = -1
  baseIndent = undefined
  lines = undefined
  j = undefined
  i = 0

  for text, i in matches
    command = ''
    if i % 2 is 1
      line = "__estFileInfo.line = " + lineNo
      switch text.charAt 0
        when "="
          prefix = "' + (" + line + "\n'') + __estTemplateContext.escape("
          postfix = ") + '"
          newline = ""
          text = text.substr 1
          output = "escaped"
        when "-"
          prefix = "' + (" + line + "\n'') + (("
          postfix = ") ? '') + '"
          newline = ""
          text = text.substr 1
          output = "unescaped"
        else
          prefix = "'\n" + line
          postfix = "\n" + bufferStack[bufferStackPointer] + " += '"
          newline = "\n"
          output = "none"
      text = text.replace(esc.trim, "")
      command = text.split(/[^a-z]+/)[0]
      if indentChar = indentChars[text.charAt(text.length - 1)]
        text = text.replace(/:$/, '').replace esc.trim, ''
        if indentChar is ">"
          if /[$a-z_][0-9a-z_$]*[^=]+(-|=)>/i.test(text.replace(/'.*'|".*"/, ""))
            indentStack.push "capture_output_" + output
            indentStackPointer++
          bufferStack.push "__estFunction" + bufferStackPointer
          bufferStackPointer++
          postfix = "\n" + bufferStack[bufferStackPointer] + " = '"
          command = "function"
        indentStack.push command
        indentStackPointer++
        indent = true
      switch command
        when "include"
          if output is "none"
            prefix = "' + (" + line + "\n'') + ("
            postfix = ") + '"
          buffer += prefix.replace(esc.newline, "\n" + indentation) + text + postfix.replace(esc.newline, "\n" + indentation)
        when "block"
          bufferStack.push "__estTemplateContext.blocks['" + text.replace(/block\s+('|")([^'"]+)('|").*/, "$2") + "']"
          bufferStackPointer++
          prefix = "'\n"
          postfix = "\n" + bufferStack[bufferStackPointer] + " += '"
          text = "if " + text
          buffer += prefix.replace(esc.newline, "\n" + indentation) + text
          if indent
            indentation += "  "
            indent = false
          buffer += postfix.replace(esc.newline, "\n" + indentation)
        when "content"
          if output is "none"
            prefix = "' + (" + line + "\n'') + ("
            postfix = ") + '"
          text = "content()"  if text is "content"
          buffer += prefix.replace(esc.newline, "\n" + indentation) + text + postfix.replace(esc.newline, "\n" + indentation)
        when "end"
          prefix = "'"
          switch indentStack[indentStackPointer]
            when "block"
              bufferStack.pop()
              bufferStackPointer--
              prefix = "'"
              postfix = "\n" + bufferStack[bufferStackPointer] + " += '"
              buffer += prefix.replace(esc.newline, "\n" + indentation)
              indentation = indentation.substr(2)
              buffer += postfix.replace(esc.newline, "\n" + indentation)
            when "when"
              postfix = "\n" + bufferStack[bufferStackPointer] + " += ''"
              buffer += prefix.replace(esc.newline, "\n" + indentation) + postfix.replace(esc.newline, "\n" + indentation)
              indentation = indentation.substr(2)
            when "function"
              prefix = "'\n" + bufferStack[bufferStackPointer]
              buffer += prefix.replace(esc.newline, "\n" + indentation)
              indentation = indentation.substr(2)
              bufferStack.pop()
              bufferStackPointer--
              postfix = "\n" + bufferStack[bufferStackPointer] + " += '"
              switch indentStack[indentStackPointer - 1]
                when "capture_output_escaped"
                  indentStack.pop()
                  indentStackPointer--
                  buffer += ")"
                when "capture_output_unescaped"
                  indentStack.pop()
                  indentStackPointer--
                  buffer += ") ? '')"
                when "capture_output_none"
                  indentStack.pop()
                  indentStackPointer--
              buffer += postfix.replace(esc.newline, "\n" + indentation)
            when "switch"
              prefix = "\n" + line
            else
              postfix = ""  if indentStack[indentStackPointer - 1] is "switch"
              indentation = indentation.substr(2)
              buffer += prefix.replace(esc.newline, "\n" + indentation) + postfix.replace(esc.newline, "\n" + indentation)
          indentStack.pop()
          indentStackPointer--
        when "else"
          if indentStack[indentStackPointer - 1] is "switch"
            prefix = ""
          else
            prefix = "'"
          buffer += prefix.replace(esc.newline, "\n" + indentation)
          if indentStack[indentStackPointer - 1] is "if" or indentStack[indentStackPointer - 1] is "else" or indentStack[indentStackPointer - 1] is "unless"
            indentStack.splice -2, 1
            indentStackPointer--
            indentation = indentation.substr(2)
          buffer += ((if newline.length then newline + indentation else "")) + text
          if indent
            indentation += "  "
            indent = false
          buffer += postfix.replace(esc.newline, "\n" + indentation)
        when "switch"
          buffer += prefix.replace(esc.newline, "\n" + indentation) + ((if newline.length then newline + indentation else "")) + text
          if indent
            indentation += "  "
            indent = false
        when "when"
          buffer += ((if newline.length then newline + indentation else "")) + text
          if indent
            indentation += "  "
            indent = false
          buffer += postfix.replace(esc.newline, "\n" + indentation)
        else
          if command is "extend"
            text = "__estExtended = true\n__estParent = #{text.replace /extend\s+/, ''}"
          if /\n/.test(text)
            lines = text.split /\n/
            buffer += prefix.replace(esc.newline, "\n#{indentation}")
            for line in lines
              continue  if /^\s*$/.test line
              if typeof baseIndent is 'undefined'
                baseIndent = new RegExp '^' + line.substr(0, line.search /[^\s]/)
              buffer += newline + indentation  if newline.length
              buffer += line.replace baseIndent, ''
            lines = undefined
            baseIndent = undefined
          else
            buffer += prefix.replace(esc.newline, "\n" + indentation) + ((if newline.length then newline + indentation else "")) + text
          if indent
            indentation += "  "
            indent = false
          buffer += postfix.replace(esc.newline, "\n" + indentation)
    else if indentStack[indentStackPointer] isnt "switch"
      buffer += text.replace(/[\\']/g, "\\$&").replace(/\r/g, "").replace(esc.newline, "\\n").replace(/^\\n/, "")
    lineNo += text.split(esc.newline).length - 1
  buffer += "'\nif not __estExtended\n  return __estOutput\nelse\n  __estContainer = __estTemplateContext.load __estParent\n  __estFileInfo.file = __estContainer.file\n  __estFileInfo.line = 1\n  __estTemplateContext.childContent = __estOutput\n  return __estContainer.compiled.call(this, __estTemplateContext, __estFileInfo, include, content, block)"
  buffer = "__estExtended = false\n#{buffer}"
  eval "(function __estTemplate(__estTemplateContext, __estFileInfo, include, content, block) {\n" + CoffeeScript.compile(buffer,
    bare: true
  ) + "});"


module.exports = compile
