if not modules then
   modules = {}
end

modules ['t-high-cs'] = {
    version   = 1.0,
    comment   = "Syntax Highlighter for C#",
    author    = "Christoph Reller",
    copyright = "Christoph Reller",
    license   = "GNU General Public License"
}

local P, R, S, V = lpeg.P, lpeg.R, lpeg.S, lpeg.V

local keywords = [[ abstract base break by case catch class const continue default
delegate do descending explicit event extern else enum finally fixed for foreach from
goto group if implicit in interface internal into lock namespace object operator out
override orderby params private protected public readonly ref return switch struct
sealed stackalloc static select this throw try unsafe using var virtual volatile
while where void yield ]]

local literalwords = [[ false true null ]]

local types = [[ bool byte char decimal double float int long sbyte short string uint
ulong ushort ]]

local operatorwords = [[ as checked is new sizeof typeof unchecked ]]

local preprocwords = [[ #define #elif #else #endif #endregion #error #if #line
#pragma #region #undef #warning ]]

local context = context
local verbatim = context.verbatim
local makepattern = visualizers.makepattern
local high = userdata.high

local handler = visualizers.newhandler {
   startinline  = function() context.CsSnippet(false,"{") end,
   stopinline   = function() context("}") end,
   startdisplay = function() context.startCsSnippet() end,
   stopdisplay  = function() context.stopCsSnippet() end,

   boundary     = function(s) verbatim.CsSnippetBoundary(s) end,
   comment      = function(s) verbatim.CsSnippetComment(s) end,
   keyword      = function(s) verbatim.CsSnippetKeyword(s) end,
   type         = function(s) verbatim.CsSnippetType(s) end,
   identifier   = function(s) verbatim.CsSnippetIdent(s) end,
   variable     = function(s) verbatim.CsSnippetVariable(s) end,
   string       = function(s) verbatim.CsSnippetString(s) end,
   literal      = function(s) verbatim.CsSnippetLiteral(s) end,
   operator     = function(s) verbatim.CsSnippetOperator(s) end,
   attribute    = function(s) verbatim.CsSnippetAttribute(s) end,
   import       = function(s) verbatim.CsSnippetImport(s) end,
   preproc      = function(s) verbatim.CsSnippetPreproc(s) end,
   preprocarg   = function(s) verbatim.CsSnippetPreprocarg(s) end,
}

local underscore = high.underscore
local wordchar = high.lowercase + high.uppercase + high.underscore

local keywordpatt = high.words2patt(keywords, wordchar)
local literalwordpatt = high.words2patt(literalwords, wordchar)
local typepatt = high.words2patt(types, wordchar)
local operatorchars = S("=+-*/%!><&|~^.?:[]")
local operatorwordpatt = high.words2patt(operatorwords, wordchar)
local preprocpatt = high.words2patt(preprocwords, wordchar + P("#"))

local spacer = high.spacer
local nonwhitespace = high.nonwhitespace
local newline = P("\r\n") + S("\r\n")
local comment1start = P("//")
local comment1 = comment1start * (high.utf8char - newline)^0
local comment2open = P("/*")
local comment2close = P("*/")
local comment2interior= high.utf8char - comment2close - newline
local commentinline = comment2open * (high.utf8char - newline - comment2close)^0 * comment2close

local dstringescape = P("\\") * (P('"') + P("'") + P("\\") + S("0abfnrtuUxv"))
local dstring = P('"') * (dstringescape + (high.utf8char - newline - P('"')))^0 * P('"')
local vstring = P('@"') * (P("\"\"") + (high.utf8char - P('"')))^0 * P('"')
local sstring = P("'") * (P("\\'") + (high.utf8char - newline - P("'")))^0 * P("'")

local digit = high.digit
local hexdigit = high.hexdigit
local integersuffix = (S("lL") * S("uU")) + (S("uU") * S("lL"))
local decimalliteral = digit^1 * integersuffix^-1
local hexprefix = P("0x")
local hexliteral = hexprefix * hexdigit^0 * integersuffix^-1
local integerliteral = hexliteral + decimalliteral
local realsuffix = S("FfDdMm")
local realexponent = R("eE") * S("+-")^-1 * digit^1
local realliteral1 = digit^1 * P(".") * digit^0 * realexponent^-1 * realsuffix^-1
local realliteral2 = digit^0 * P(".") * digit^1 * realexponent^-1 * realsuffix^-1
local realliteral3 = digit^1 * realexponent * realsuffix^-1
local realliteral = realliteral1 + realliteral2 + realliteral3
local literal = vstring + dstring + sstring + integerliteral + realliteral + literalwordpatt

local boundary = S("(){};,")

local name = wordchar^1 * (wordchar + R("09"))^0
local import = name * (P(".") * name)^0

local attribute = P("[") * (high.utf8char - P("]"))^0 * P("]")

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

      importkeyword = makepattern(handler, "keyword", P("using")),
      import = makepattern(handler, "import", import),
      importline = V("importkeyword") * V("spacer")^1 * V("import"),

      attribute = makepattern(handler, "attribute", attribute),

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

      openingbracket = V("identifier") * V("spacer")^0 * makepattern(handler, "operator", P("[")),

      preproc = makepattern(handler, "preproc", preprocpatt),
      preprocarg = makepattern(handler, "preprocarg", P(high.utf8char - newline)^1),
      preprocline = V("preproc") * V("preprocarg")^0,

      pattern =
         V("comment1") +
         V("comment2") +
         V("importline") +
         V("preprocline") +
         V("openingbracket") +
         V("attribute") +
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

visualizers.register("cs", { parser = parser, handler = handler, grammar = grammar } )
