if not modules then
   modules = {}
end

modules ['t-high-cpp'] = {
    version   = 1.0,
    comment   = "Syntax Highlighter for C++",
    author    = "Christoph Reller",
    copyright = "Christoph Reller",
    license   = "GNU General Public License"
}

local P, R, S, V = lpeg.P, lpeg.R, lpeg.S, lpeg.V

local keywords = [[ alignas alignof and and_eq asm auto bitand bitor break case catch
class compl concept const constexpr continue decltype default do else explicit export
extern for friend goto if inline mutable namespace noexcept not not_eq operator or
or_eq private protected public register requires return signed static static_assert
struct switch template this thread_local throw try typedef typeid typename union
unsigned using virtual volatile while xor xor_eq ]]

local literalwords = [[ false true nullptr ]]

local types = [[ bool char char16_t char32_t double enum float int long short void
wchar_t ]]

local preprocs = [[ #define #defined #elif #endif #if #ifdef #ifndef #include #pragma
]]

local operatorwords = [[ sizeof alignof typeid static_cast dynamic_cast const_cast
reinterpret_cast new delete ]]

local context = context
local verbatim = context.verbatim
local makepattern = visualizers.makepattern
local high = userdata.high

local handler = visualizers.newhandler {
   startinline  = function() context.CppSnippet(false,"{") end,
   stopinline   = function() context("}") end,
   startdisplay = function() context.startCppSnippet() end,
   stopdisplay  = function() context.stopCppSnippet() end ,

   boundary     = function(s) verbatim.CppSnippetBoundary(s) end,
   comment      = function(s) verbatim.CppSnippetComment(s) end,
   keyword      = function(s) verbatim.CppSnippetKeyword(s) end,
   type         = function(s) verbatim.CppSnippetType(s) end,
   identifier   = function(s) verbatim.CppSnippetIdent(s) end,
   variable     = function(s) verbatim.CppSnippetVariable(s) end,
   string       = function(s) verbatim.CppSnippetString(s) end,
   literal      = function(s) verbatim.CppSnippetLiteral(s) end,
   operator     = function(s) verbatim.CppSnippetOperator(s) end,
   preproc      = function(s) verbatim.CppSnippetPreproc(s) end,
   include      = function(s) verbatim.CppSnippetInclude(s) end,
   macro        = function(s) verbatim.CppSnippetMacro(s) end,
}

local wordchar = high.lowercase + high.uppercase + high.underscore

local preprocpatt = high.words2patt(preprocs, wordchar + P("#"))
local keywordpatt = high.words2patt(keywords, wordchar)
local literalwordpatt = high.words2patt(literalwords, wordchar)
local typepatt = high.words2patt(types, wordchar)
local operatorchars = S("=+-*/%!><&|~^.?:[]")
local operatorwordpatt = high.words2patt(operatorwords, wordchar)

local spacer = high.spacer
local nonwhitespace = high.nonwhitespace
local newline = P("\r\n") + S("\r\n")
local backslash = P("\\")
local comment1start = P("//")
local comment1 = comment1start * (high.utf8char - newline)^0
local comment2open = P("/*")
local comment2close = P("*/")
local comment2interior = high.utf8char - comment2close - newline
local commentinline = comment2open * (high.utf8char - newline - comment2close)^0 * comment2close

local dstring = P('"') * (P("\\\"") + (1 - newline - P('"')) + (P("\\") * newline))^0 * P('"')
local sstring = P("'") * (P("\\'") + (1 - newline - P("'")))^0 * P("'")
local lt = P("<")
local gt = P(">")
local ltgtstring = lt * (high.utf8char - newline - gt)^0 * gt
local includestring = ltgtstring + dstring

local digit = high.digit
local octdigit = high.digit
local hexdigit = high.hexdigit
local bindigit = S("01")
local integersuffix = (S("Uu") + P("Uu") + P("uU"))^-1
local decimalliteral = R("19") * digit^0 * integersuffix
local octalliteral = P("0") * octdigit^0 * integersuffix
local hexprefix = P("0x")
local hexliteral = hexprefix * hexdigit^0 * integersuffix
local binaryliteral = P("0b") * bindigit^0 * integersuffix
local integerliteral = hexliteral + binaryliteral + octalliteral + decimalliteral
local floatsuffix = S("dflDFL")^-1
local floatexponent = R("eE") * S("+-")^-1 * digit^1
local floatliteral1 = digit^1 * P(".") * digit^0 * floatexponent^-1 * floatsuffix
local floatliteral2 = digit^0 * P(".") * digit^1 * floatexponent^-1 * floatsuffix
local floatliteral3 = digit^1 * floatexponent * floatsuffix
local floatexponentx = R("pP") * S("+-")^-1 * digit^1
local floatliteralx1 = hexprefix * hexdigit^1 * P(".") * hexdigit^0 * floatexponentx^-1 * floatsuffix
local floatliteralx2 = hexprefix * hexdigit^0 * P(".") * hexdigit^1 * floatexponentx^-1 * floatsuffix
local floatliteralx3 = hexprefix * hexdigit^1 * floatexponentx * floatsuffix
local floatliteral = floatliteral1 + floatliteral2 + floatliteral3 + floatliteralx1 + floatliteralx2 + floatliteralx3
local literal = dstring + sstring + integerliteral + floatliteral + literalwordpatt

local boundary = S("(){};,")

local name = wordchar^1 * (wordchar + R("09"))^0
local identifier = (P("::")^-1 * name)^1

local grammar = visualizers.newgrammar(
   "default",
   {
      "visualizer",

      newline = makepattern(handler, "newline", newline),

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

      preproc = makepattern(handler, "preproc", preprocpatt),

      includestring = makepattern(handler, "include", includestring),

      literal = makepattern(handler, "literal", literal),

      nonwhitespace = makepattern(handler, "default", nonwhitespace^1),

      macro = makepattern(handler, "macro", high.utf8char - newline - comment2open - comment1start - lt - backslash),

      macrocont =
         makepattern(handler, "macro", backslash) *
         V("spacer")^0 *
         V("comment1")^0 *
         V("newline"),

      keyword = makepattern(handler, "keyword", keywordpatt + operatorwordpatt),

      type = makepattern(handler, "type",  typepatt),

      operator = makepattern(handler, "operator", operatorchars),

      boundary = makepattern(handler, "boundary", boundary),

      identifier = makepattern(handler, "identifier", identifier),

      name = makepattern(handler, "identifier", name),

      variable = makepattern(handler, "variable", name),

      equal = makepattern(handler, "operator", P("=")),

      assignment =
         (
            V("type") +
            V("name")
         ) *
         V("spacer")^1 *
         V("variable") *
         V("spacer")^0 *
         V("equal"),

      preprocline =
         V("spacer")^0 *
         V("preproc") *
         (
            V("includestring") +
            V("commentinline") +
            V("keyword") +
            V("comment1") +
            V("operator") +
            V("boundary") +
            V("macro") +
            V("macrocont")
         )^0 *
         (
            V("comment2") +
            V("newline")
         ),

      pattern =
         V("comment1") +
         V("comment2") +
         V("preprocline") +
         V("assignment") +
         V("keyword") +
         V("type") +
         V("operator") +
         V("literal") +
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

visualizers.register("cpp", { parser = parser, handler = handler, grammar = grammar } )
