fs = require 'fs'
path = require 'path'
esc = require './escape'
compile = require './compile'


read = (file, options) ->
  if Object::toString.call(options.root) is '[object Object]'
    contents = file.split('.').reduce (currentContext, key) ->
      currentContext[key]
    , options.root
    return contents  if Object::toString.call(contents) is '[object String]'
    throw new Error "Failed to load template #{file}"
  else
    try
      fs.readFileSync file, 'utf8'
    catch e
      throw new Error "Failed to load template #{file}"



class TemplateContext
  blocks: {}
  data: {}
  childContent = ''

  constructor: (data, options = {}, cache = {}) ->
    @data = data  if data
    @options = options
    @cache = cache

  escape: (text) ->
    return ""  unless text?
    result = text.toString()
    return result  unless esc.exp.test(result)
    result.replace(esc.amp, "&#38;").replace(esc.lt, "&#60;").replace(esc.gt, "&#62;").replace esc.quote, "&#34;"

  block: (name) ->
    @blocks[name] = ""  unless @blocks[name]
    not @blocks[name].length

  content: (block) ->
    if block and block.length
      return ""  unless @blocks[block]
      @blocks[block]
    else
      @childContent

  load: (template) ->
    if @options.cache and @cache[template]
      @cache[template]
    else
      extExp = new RegExp(esc.regExp(@options.ext) + "$")
      if Object::toString.call(@options.root) is "[object String]"
        if typeof process isnt "undefined" and process.platform is "win32"
          file = path.normalize(((if @options.root.length and template.charAt(0) isnt "/" and template.charAt(0) isnt "\\" and not /^[a-zA-Z]:/.test(template) then (@options.root + "/") else "")) + template.replace(extExp, "") + @options.ext)
        else
          file = path.normalize(((if @options.root.length and template.charAt(0) isnt "/" then (@options.root + "/") else "")) + template.replace(extExp, "") + @options.ext)
      else
        file = template
      contents = read file, @options
      if contents.substr(0, 24) is "(function __estTemplate("
        try
          compiled = eval contents
        catch e
          e.message = "#{e.message} in #{file}"
          throw e
      else
        try
          compiled = compile contents, @options
        catch e
          e.message = e.message.replace(RegExp(" on line \\d+"), "") + " in " + file
          throw e
      container =
        file: file
        compiled: compiled
        source: "(" + compiled.toString() + ");"
        lastModified: new Date().toUTCString()
        gzip: null

      @cache[template] = container  if @options.cache
      container

  render: (template, data) ->
    container = @load template
    fileInfo =
      file: container.file
      line: 1
    try
      container.compiled.call(data or @data, @, fileInfo, =>
        @render.apply @, arguments
      , =>
        @content.apply @, arguments
      , =>
        @block.apply @, arguments
      )
    catch e
      e.message = e.message + " in " + fileInfo.file + " on line " + fileInfo.line  unless RegExp(" in ").test(e.message)
      throw e


module.exports = TemplateContext

