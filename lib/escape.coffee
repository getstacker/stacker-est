
module.exports =
  exp: /[&<>"]/
  amp: /&/g
  lt: /</g
  gt: />/g
  quote: /"/g
  trim: /^[ \t]+|[ \t]+$/g
  newline: /\n/g

  regExp: (str) ->
    String(str).replace /[\-\[\]{}()*+?.,\\\^$|#\s]/g, "\\$&"

