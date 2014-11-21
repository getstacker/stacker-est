CoffeeScript = require 'coffee-script'
esc = require './escape'

indentChars =
  ":": ":"
  ">": ">"

compile = (template, options) ->
  lineNo = 1
  bufferStack = ["__ectOutput"]
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

  while i < matches.length
    text = matches[i]
    command = ""
    if i % 2 is 1
      line = "__ectFileInfo.line = " + lineNo
      switch text.charAt(0)
        when "="
          prefix = "' + (" + line + "\n'') + __ectTemplateContext.escape("
          postfix = ") + '"
          newline = ""
          text = text.substr(1)
          output = "escaped"
        when "-"
          prefix = "' + (" + line + "\n'') + (("
          postfix = ") ? '') + '"
          newline = ""
          text = text.substr(1)
          output = "unescaped"
        else
          prefix = "'\n" + line
          postfix = "\n" + bufferStack[bufferStackPointer] + " += '"
          newline = "\n"
          output = "none"
      text = text.replace(esc.trim, "")
      command = text.split(/[^a-z]+/)[0]
      if indentChar = indentChars[text.charAt(text.length - 1)]
        text = text.replace(/:$/, "").replace(esc.trim, "")
        if indentChar is ">"
          if /[$a-z_][0-9a-z_$]*[^=]+(-|=)>/i.test(text.replace(/'.*'|".*"/, ""))
            indentStack.push "capture_output_" + output
            indentStackPointer++
          bufferStack.push "__ectFunction" + bufferStackPointer
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
          bufferStack.push "__ectTemplateContext.blocks['" + text.replace(/block\s+('|")([^'"]+)('|").*/, "$2") + "']"
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
        when "extend"
          text = "__ectExtended = true\n__ectParent = " + text.replace(/extend\s+/, "")
        else
          if /\n/.test(text)
            lines = text.split(/\n/)
            buffer += prefix.replace(esc.newline, "\n" + indentation)
            j = 0
            while j < lines.length
              continue  if /^\s*$/.test(lines[j])
              baseIndent = new RegExp("^" + lines[j].substr(0, lines[j].search(/[^\s]/)))  if typeof baseIndent is "undefined"
              buffer += ((if newline.length then newline + indentation else "")) + lines[j].replace(baseIndent, "")
              j++
            lines = undefined
            baseIndent = undefined
          else
            buffer += prefix.replace(esc.newline, "\n" + indentation) + ((if newline.length then newline + indentation else "")) + text
          if indent
            indentation += "  "
            indent = false
          buffer += postfix.replace(esc.newline, "\n" + indentation)
    else
      buffer += text.replace(/[\\']/g, "\\$&").replace(/\r/g, "").replace(esc.newline, "\\n").replace(/^\\n/, "")  if indentStack[indentStackPointer] isnt "switch"
    lineNo += text.split(esc.newline).length - 1
    i++
  buffer += "'\nif not __ectExtended\n  return __ectOutput\nelse\n  __ectContainer = __ectTemplateContext.load __ectParent\n  __ectFileInfo.file = __ectContainer.file\n  __ectFileInfo.line = 1\n  __ectTemplateContext.childContent = __ectOutput\n  return __ectContainer.compiled.call(this, __ectTemplateContext, __ectFileInfo, include, content, block)"
  buffer = "__ectExtended = false\n" + buffer
  eval "(function __ectTemplate(__ectTemplateContext, __ectFileInfo, include, content, block) {\n" + CoffeeScript.compile(buffer,
    bare: true
  ) + "});"


module.exports = compile
