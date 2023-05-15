-- Common file for all high-<what> modules
-- Author: Christoph Reller
-- Copyright: Christoph Reller
-- License: GNU General Public License

userdata = userdata or {}
userdata.high = userdata.high or {}
local high = userdata.high

local P, S, patterns = lpeg.P, lpeg.S, lpeg.patterns

-- Some pattern definitions mostly from l-lpeg.lua

high.startofstring = P(function(s, i) return i == 1 end)
high.endofstring = patterns.endofstring
high.newline = P("\r\n") + S("\r\n") -- or patterns.newline ?
high.utf8char = patterns.utf8char
high.sign = patterns.sign
high.digit = patterns.digit
high.octdigit = patterns.octdigit
high.hexdigit = patterns.hexdigit
high.underscore = patterns.underscore
high.spacer = patterns.spacer
high.nonwhitespace = patterns.nonwhitespace
high.dquote = patterns.dquote
high.squote = patterns.squote
high.backslash = P("\\")
high.slash = P("/")
high.percent = P("%")
high.exclam = P("!")
high.tilde = P("~")
high.colon = patterns.colon
high.equal = patterns.equal
high.dollar = P("$")
high.comma = patterns.comma
high.lowercase = patterns.lowercase
high.uppercase = patterns.uppercase
high.letter = patterns.letter
high.utf8character = patterns.utf8character

-- Build a list of patterns from a space-separated string of words
function high.words2patt(words, wordchar)
   local list = {}
--   logs.report("high", "words: " .. words)
   for word in words:gmatch '%S+' do
      list[#list + 1] = word
   end
   table.sort(list, function(a, b) return #a > #b end)
   local pattern
   for _, word in ipairs(list) do
      local p = P(word)
      pattern = pattern and (pattern + p) or p
   end
   -- Left (starting) word boundary
   local left = lpeg.B(1 - wordchar, 1) + high.startofstring
   -- Right (ending) word boundary
   local right = lpeg.B(-wordchar, 1) + high.endofstring
   return left * pattern * right
end

-- Build a list of case-ignoring patterns from a space-separated string of
-- lower case words
function high.words2pattignorecase(words, wordchar)
--   logs.report("high", "words2pattignorecase entered.")
--   logs.report("high", "words: " .. words)
   local list = {}
   for word in words:gmatch '%S+' do
      list[#list + 1] = word
   end
   table.sort(list, function(a, b) return #a > #b end)
   local pattern
   for _, word in ipairs(list) do
      local p
      for c in word:gmatch '.' do
         local charpat = S(c .. string.upper(c))
         p = p and (p * charpat) or charpat
      end
      pattern = pattern and (pattern + p) or p
   end
   -- Left (starting) word boundary
   local left = lpeg.B(1 - wordchar, 1) + high.startofstring
   -- Right (ending) word boundary
   local right = lpeg.B(-wordchar, 1) + high.endofstring
   return left * pattern * right
end
