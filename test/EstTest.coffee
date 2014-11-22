EST = require '../lib/EST'
expect = require('./helpers/Common').expect
path = require 'path'


describe 'EST', ->
  before ->
    @est = new EST root: path.join __dirname, '/mocks'

  describe '#render', ->
    it  'simple template', ->
      contents = @est.render 'simple'
      expect(contents).to.contain 'ping: pong pong'

    it 'multiline coffee', ->
      contents = @est.render 'multiline'
      expect(contents).to.contain 'c :: ab'
      expect(contents).to.contain 'e -> f'

    # Example from http://ectjs.com/ to ensure compatibility.
    # Uses page, layout, list, footer templates.
    it 'multiple templates', ->
      contents = @est.render 'page',
        title: 'Hello, world!'
        id: 'main'
        links: [
          { name : 'Google', url : 'http://google.com/' }
          { name : 'Facebook', url : 'http://facebook.com/' }
          { name : 'Twitter', url : 'http://twitter.com/' }
        ]
        upperHelper: (str) ->
          str.toUpperCase()
      expect(contents).to.contain 'footer: page: main'
      expect(contents).to.contain 'HELLO, WORLD!'
      expect(contents).to.contain '<li><a href="http://facebook.com/">Facebook</a></li>'
