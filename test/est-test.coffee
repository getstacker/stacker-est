EST = require '../lib/EST'
expect = require('./helpers/Common').expect
path = require 'path'


describe 'EST', ->
  before ->
    @est = new EST root: path.join __dirname, '/fixtures'

  describe '#render', ->
    it 'simple template', ->
      contents = @est.render 'simple'
      expect(contents).to.contain 'ping: pong pong'

    it 'multiline coffee', ->
      contents = @est.render 'multiline'
      expect(contents).to.contain 'c :: ab'
      expect(contents).to.contain 'e -> f'

    it 'yaml', ->
      contents = @est.render 'yaml'
      expect(contents).to.match /^val1: 123$/m
      expect(contents).to.match /^\s+val3: 2$/m
      expect(contents).to.match /^\s+val4: yo$/m
      expect(contents).to.contain "obj:\n  nested:\n    val1: 123\n    val2: abc\n"
      expect(contents).to.match /- 0\n\s{4}- 123\n\s{4}- abc\n\s{4}- 3\n/
      expect(contents).to.match /^yaml_included: true$/m

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
