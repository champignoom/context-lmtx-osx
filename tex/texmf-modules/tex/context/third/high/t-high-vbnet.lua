if not modules then
   modules = {}
end

modules ['t-high-vbnet'] = {
    version   = 1.0,
    comment   = "Syntax Highlighter for Visual Basic .NET",
    author    = "Christoph Reller",
    copyright = "Christoph Reller",
    license   = "GNU General Public License"
}

local P, S, V = lpeg.P, lpeg.S, lpeg.V

local keywords = [[ AddHandler Alias Ansi As Assembly Auto ByRef ByVal Call Case
Catch Class Const Date Decimal Declare Default Delegate Dim DirectCast Do Each Else
ElseIf End EndIf Enum Erase Error Event Exit Finally For Friend Function Get GoSub
GoTo Handles If Implements Imports In Inherits Interface Let Lib Loop Me Module
MustInherit MustOverride MyBase MyClass Namespace New Next NotInheritable
NotOverridable On Option Optional Overloads Overridable Overrides ParamArray Preserve
Private Property Protected Public RaiseEvent ReDim ReadOnly RemoveHandler Resume
Return Select Set Shadows Shared Static Step Stop Structure Sub SyncLock Then Throw
To Try TypeOf Unicode Until Variant Wend When While With WithEvents WriteOnly ]]

local literalwords = [[ False Nothing True ]]

local types = [[ Boolean Byte CBool CByte CChar CDate CDbl CDec CInt CLng CObj CSByte
CShort CSng CStr CType CUInt CULng CUShort Char Date DateTime Decimal Double Int16
Int32 Int64 IntPtr Integer Long Object SByte Short Single String UInteger ULong
UShort UintPtr Variant ]]

local operatorwords = [[ AddressOf And AndAlso GetType Is Like Mod Not Or OrElse Xor
]]

local directives = [[ #Const #Else #ElseIf #End #Region ]]

local context = context
local verbatim = context.verbatim
local makepattern = visualizers.makepattern
local high = userdata.high

local handler = visualizers.newhandler {
   startinline  = function() context.VbSnippet(false,"{") end,
   stopinline   = function() context("}") end,
   startdisplay = function() context.startVbSnippet() end,
   stopdisplay  = function() context.stopVbSnippet() end,

   identifier   = function(s) verbatim.VbSnippetIdent(s) end,
   keyword      = function(s) verbatim.VbSnippetKeyword(s) end,
   type         = function(s) verbatim.VbSnippetType(s) end,
   variable     = function(s) verbatim.VbSnippetVariable(s) end,
   import       = function(s) verbatim.VbSnippetImport(s) end,
   directive    = function(s) verbatim.VbSnippetDirective(s) end,
   operator     = function(s) verbatim.VbSnippetOperator(s) end,
   boundary     = function(s) verbatim.VbSnippetBoundary(s) end,
   comment      = function(s) verbatim.VbSnippetComment(s) end,
   literal      = function(s) verbatim.VbSnippetLiteral(s) end
}

local wordchar = high.lowercase + high.uppercase
local newline = P("\r\n") + S("\r\n")

local keywordpatt = high.words2patt(keywords, wordchar)
local literalwordpatt = high.words2patt(literalwords, wordchar)
local typepatt = high.words2patt(types, wordchar)
local operatorwordpatt = high.words2patt(operatorwords, wordchar)
local operatorchars = S("=+-*/><&^")
local directivepatt = high.words2patt(directives, wordchar + P("#"))

local spacer = high.spacer
local digit = high.digit
local octdigit = high.digit
local hexdigit = high.hexdigit

local integersuffix =  P("U")^-1 * S("SIL%&")^-1
local decimalliteral = digit^1 * integersuffix
local hexliteral = P("&H") * hexdigit^1 * integersuffix
local octliteral = P("&O") * octdigit^1 * integersuffix
local integerliteral = decimalliteral + hexliteral + octliteral

local exponent = P("E") * S("+-")^-1 * digit^1
local floatsuffix = S("RFD@!#")
local floatliteral1 = digit^0 * P(".") * digit^1 * exponent^-1 * floatsuffix^-1
local floatliteral2 = digit^1 * exponent * floatsuffix^-1
local floatliteral3 = digit^1 * floatsuffix
local floatliteral = floatliteral1 + floatliteral2 + floatliteral3

local doublequote = high.dquote + P("“") + P("”")
local stringcharacter = (high.utf8char - doublequote + (doublequote * doublequote))
local stringliteral = doublequote * stringcharacter^0 * doublequote * P("c")^-1

local ampm = P("AM") + P("PM")
local time = digit^1 * P(":") * digit^1 * (P(":") * digit^1)^-1 * spacer^0 * ampm^-1
local date = digit^1 * S("/-") * digit^1 * S("/-") * digit^1
local dateortime = (date * spacer^1 * time) + date + time
local dateliteral = P("#") * spacer^0 * dateortime * spacer^0 * P("#")

local literal = integerliteral + floatliteral + stringliteral + dateliteral

local boundary = S("(){}!#,.:")

local identchar = high.utf8character - spacer - newline - operatorchars - boundary
local identifier = identchar^1

local comment = (S("'‘’") + P("REM")) * (high.utf8char - newline)^0

local grammar = visualizers.newgrammar(
   "default",
   {
      "visualizer",

      spacer = makepattern(handler, "space", spacer),

      comment = makepattern(handler, "comment", comment),

      literal = makepattern(handler, "literal", literal + literalwordpatt),

      keyword = makepattern(handler, "keyword", keywordpatt + operatorwordpatt),

      type = makepattern(handler, "type", typepatt),

      operator = makepattern(handler, "operator", operatorchars),

      boundary = makepattern(handler, "boundary", boundary),

      identifier = makepattern(handler, "identifier", identifier),

      import = makepattern(handler, "keyword", P("Imports")),
      importname = makepattern(handler, "import", identifier),
      equal = makepattern(handler, "operator", P("=")),
      dotsign = makepattern(handler, "boundary", P(".")),

      directive = makepattern(handler, "directive", directivepatt),

      variable = makepattern(handler, "variable", identifier),
      assignment =
         (V("line") + high.startofstring) *
         V("spacer")^0 *
         (V("type") + V("identifier")) *
         V("spacer")^1 *
         V("variable") *
         V("spacer")^0 *
         V("equal"),

      importline =
         V("import") *
         (
            V("spacer")^0 *
            V("importname") *
            V("spacer")^0 *
            V("equal")
         )^-1 *
         V("spacer")^0 *
         V("importname") *
         (
            V("dotsign") *
            V("importname")
         )^0,

      pattern =
         V("comment") +
         V("importline") +
         V("assignment") +
         V("keyword") +
         V("type") +
         V("directive") +
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

visualizers.register("vbnet", { parser = parser, handler = hander, grammar = grammar } )
