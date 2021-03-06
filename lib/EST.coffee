# EST: Embedded Stacker Template
# removed watch option; this should be handled by another library that calls ect

###!
EST CoffeeScript Template Engine for Stacker
https://github.com/getstacker/stacker-est

Copyright 2014, Joe Johnston <joe@simple10.com>
Licensed under the MIT license
https://github.com/getstacker/stacker-est/LICENSE

Based on ECT by Vadim M. Baryshev <vadimbaryshev@gmail.com>
https://github.com/baryshev/ect
###


compile = require './compile'
TemplateContext = require './TemplateContext'


class EST
  # Defaults
  defaults:
    open: '<%'
    close: '%>'
    ext: '.est'
    cache: true
    root: ''

  cache: {}
  options: {}


  constructor: (options) ->
    @configure options
    @clearCache()


  configure: (options = {}) ->
    @options = {}
    for k,v of @defaults
      @options[k] = v
    for k,v of options
      @options[k] = v
    @options


  compile: (template) ->
    try
      compile template, @options
    catch e
      e.message = e.message.replace RegExp(" on line \\d+"), ''
      throw e


  render: (template, data, callback) ->
    if typeof arguments[arguments.length - 1] is 'function'
      if arguments.length is 2
        callback = data
        data = {}
      context = @newTemplate data
      try
        callback undefined, context.render template
      catch e
        callback e
    else
      context = @newTemplate data
      context.render template


  newTemplate: (data) ->
    new TemplateContext data, @options, @cache


  clearCache: (template) ->
    if template
      delete (@cache[template])
    else
      @cache = {}



module.exports = EST
