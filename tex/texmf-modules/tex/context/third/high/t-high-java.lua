if not modules then
   modules = {}
end

modules ['t-high-java'] = {
    version   = 1.0,
    comment   = "Syntax Highlighter for Java",
    author    = "Christoph Reller",
    copyright = "Christoph Reller",
    license   = "GNU General Public License"
}

local P, R, S, V = lpeg.P, lpeg.R, lpeg.S, lpeg.V

local keywords = [[ abstract assert break case catch class const continue
default do else extends final finally for goto if implements import instanceof
interface native new package private protected public return static strictfp
super switch synchronized this throw throws transient try volatile while ]]

local literalwords = [[ false null true ]]

local types = [[ boolean byte char double enum float int long short void ]]

local operatorwords = [[ new instanceof ]]

local context = context
local verbatim = context.verbatim
local makepattern = visualizers.makepattern
local high = userdata.high

local handler = visualizers.newhandler {
   startinline  = function() context.JavaSnippet(false,"{") end,
   stopinline   = function() context("}") end,
   startdisplay = function() context.startJavaSnippet() end,
   stopdisplay  = function() context.stopJavaSnippet() end ,

   boundary     = function(s) verbatim.JavaSnippetBoundary(s) end,
   comment      = function(s) verbatim.JavaSnippetComment(s) end,
   keyword      = function(s) verbatim.JavaSnippetKeyword(s) end,
   type         = function(s) verbatim.JavaSnippetType(s) end,
   identifier   = function(s) verbatim.JavaSnippetIdent(s) end,
   variable     = function(s) verbatim.JavaSnippetVariable(s) end,
   string       = function(s) verbatim.JavaSnippetString(s) end,
   literal      = function(s) verbatim.JavaSnippetLiteral(s) end,
   operator     = function(s) verbatim.JavaSnippetOperator(s) end,
   annotation   = function(s) verbatim.JavaSnippetAnnotation(s) end,
   package      = function(s) verbatim.JavaSnippetPackage(s) end,
}

local underscore = high.underscore
local wordchar = high.lowercase + high.uppercase + underscore

local keywordpatt = high.words2patt(keywords, wordchar)
local literalwordpatt = high.words2patt(literalwords, wordchar)
local typepatt = high.words2patt(types, wordchar)
local operatorchars = S("=+-*/%!><&|~^.?:[]")
local operatorwordpatt = high.words2patt(operatorwords, wordchar)

local spacer = high.spacer
local nonwhitespace = high.nonwhitespace
local newline = P("\r\n") + S("\r\n")
local comment1start = P("//")
local comment1 = comment1start * (high.utf8char - newline)^0
local comment2open = P("/*")
local comment2close = P("*/")
local comment2interior = high.utf8char - comment2close - newline
local commentinline = comment2open * (high.utf8char - newline - comment2close)^0 * comment2close

local dstring =
   P('"') *
   (
      P("\\\"") +
      (high.utf8char - newline - P('"')) +
      (P("\\") * newline)
   )^0 *
   P('"')

local sstring =
   P("'") *
   (
      P("\\'") +
      (high.utf8char - newline - P("'"))
   )^0
   * P("'")

local digit = high.digit
local octdigit = high.digit
local hexdigit = high.hexdigit
local bindigit = S("01")
local decimalliteral = R("19") * (digit + underscore)^0
local octalliteral = P("0") * (octdigit + underscore)^0
local hexprefix = P("0x")
local hexliteral = hexprefix * (hexdigit + underscore)^0
local binaryliteral = P("0b") * (bindigit + underscore)^0
local integerliteral = hexliteral + binaryliteral + octalliteral + decimalliteral
local floatsuffix = S("dflDFL")^-1
local floatexponent = R("eE") * S("+-")^-1 * digit^1
local floatliteral1 = digit^1 * P(".") * digit^0 * floatexponent^-1 * floatsuffix
local floatliteral2 = digit^0 * P(".") * digit^1 * floatexponent^-1 * floatsuffix
local floatliteral3 = digit^1 * floatexponent^1 * floatsuffix
local floatexponentx = R("pP") * S("+-")^-1 * digit^1
local floatliteralx1 = hexprefix * hexdigit^1 * P(".") * hexdigit^0 * floatexponentx^-1 * floatsuffix
local floatliteralx2 = hexprefix * hexdigit^0 * P(".") * hexdigit^1 * floatexponentx^-1 * floatsuffix
local floatliteralx3 = hexprefix * hexdigit^1 * floatexponentx^-1 * floatsuffix
local floatliteral = floatliteral1 + floatliteral2 + floatliteral3 + floatliteralx1 + floatliteralx2 + floatliteralx3
local literal = dstring + sstring + integerliteral + floatliteral + literalwordpatt

local boundary = S("(){};,")

local name = wordchar^1 * (wordchar + R("09"))^0
local annotation = P("@") * name
local package = name * (P(".") * name)^0

local grammar = visualizers.newgrammar(
   "default",
   {
      "visualizer",

      comment1 = makepattern(handler, "comment", comment1),
      comment2 =
         makepattern(handler, "comment", comment2open) *
         (
            makepattern(handler, "comment", comment2interior) +
            V("whitespace")
         )^0 *
         makepattern(handler, "comment", comment2close),
      commentinline = makepattern(handler, "comment", commentinline),

      spacer = makepattern(handler, "space", spacer) + V("commentinline"),

      packagekeywords = makepattern(handler, "keyword", P("package") + P("import")),
      package = makepattern(handler, "package", package),
      packageline = V("packagekeywords") * V("spacer")^1 * V("package"),

      annotation = makepattern(handler, "annotation", annotation),

      literal = makepattern(handler, "literal", literal),

      keyword = makepattern(handler, "keyword", keywordpatt + operatorwordpatt),

      type = makepattern(handler, "type", typepatt),

      operator = makepattern(handler, "operator", operatorchars),

      boundary = makepattern(handler, "boundary", boundary),

      identifier = makepattern(handler, "identifier", name),

      variable = makepattern(handler, "variable", name),

      equal = makepattern(handler, "operator", P("=")),

      assignment =
         (
            V("type") +
            V("identifier")
         ) *
         V("spacer")^1 *
         V("variable") *
         V("spacer")^0 *
         V("equal"),

      pattern =
         V("comment1") +
         V("comment2") +
         V("packageline") +
         V("annotation") +
         V("assignment") +
         V("keyword") +
         V("type") +
         V("literal") +
         V("operator") +
         V("identifier") +
         V("boundary") +
         V("line") +
         V("spacer") +
         V("default"),

      visualizer =
         V("pattern")^1
   }
)

local parser = P(grammar)

visualizers.register("java", { parser = parser, handler = handler, grammar = grammar } )
