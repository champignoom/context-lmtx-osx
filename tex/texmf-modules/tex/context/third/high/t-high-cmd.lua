if not modules then
   modules = {}
end

modules ['t-high-cmd'] = {
    version   = 1.0,
    comment   = "Syntax Highlighter for Windows Batch Scripts (CMD)",
    author    = "Christoph Reller",
    copyright = "Christoph Reller",
    license   = "GNU General Public License"
}

local P, R, S, V = lpeg.P, lpeg.R, lpeg.S, lpeg.V

local keywords = [[ break call cd chdir cls color copy date del dir dir echo
else endlocal equ erase exist exit findstr for ftype geq goto gtr if leq lss md
mkdir move neq not path pause popd prompt pushd rd reg rem ren rename rmdir
runas set setlocal shift start time title type ver verify vol ]]

local context = context
local verbatim = context.verbatim
local makepattern = visualizers.makepattern
local high = userdata.high

local handler = visualizers.newhandler {
   startinline  = function() context.CmdSnippet(false,"{") end,
   stopinline   = function() context("}") end,
   startdisplay = function() context.startCmdSnippet() end,
   stopdisplay  = function() context.stopCmdSnippet() end,
   keyword      = function(s) verbatim.CmdSnippetKeyword(s) end,
   variable     = function(s) verbatim.CmdSnippetVariable(s) end,
   boundary     = function(s) verbatim.CmdSnippetBoundary(s) end,
   comment      = function(s) verbatim.CmdSnippetComment(s) end,
   label        = function(s) verbatim.CmdSnippetLabel(s) end,
}

local wordchar = high.lowercase + high.uppercase + high.underscore

local keywordpatt = high.words2pattignorecase(keywords, 1 - high.spacer - high.newline - P("(") - P(")"))

local key_rem = high.words2pattignorecase("rem", wordchar)
local comment = (P("::") + key_rem) * (high.utf8char - high.newline)^0

local variablename = wordchar * (wordchar + high.digit)^0

local label = high.colon * variablename

local option = high.slash * (high.uppercase + high.lowercase)

local boundary = S('()[]"%')

local key_set = high.words2pattignorecase("set", wordchar)

local filechar = S("fdpnxsatz")

local variablechar = high.uppercase + high.lowercase
local variableordigit = variablechar + high.digit
local variablename = wordchar * (wordchar + high.digit)^0

local grammar = visualizers.newgrammar(
   "default",
   {
      "visualizer",

      comment = makepattern(handler, "comment", comment),

      keyword = makepattern(handler, "keyword", keywordpatt),

      boundary = makepattern(handler, "boundary", boundary),

      variablename = makepattern(handler, "variable", variablename),
      variableordigit = makepattern(handler, "variable", variableordigit),
      percent = makepattern(handler, "boundary", high.percent),
      exclam = makepattern(handler, "boundary", high.exclam),
      tilde = makepattern(handler, "boundary", high.tilde),
      colon = makepattern(handler, "boundary", high.colon),
      equal = makepattern(handler, "boundary", high.equal),
      dollar = makepattern(handler, "boundary", high.dollar),
      sign = makepattern(handler, "default", high.sign),
      digit = makepattern(handler, "default", high.digit),
      comma = makepattern(handler, "boundary", high.comma),
      stringperc = makepattern(handler, "default", 1 - high.newline - high.percent - high.equal),
      stringexclam = makepattern(handler, "default", 1 - high.newline - high.exclam - high.equal),

      substring =
         V("tilde") *
         V("sign")^-1 *
         V("digit")^1 *
         (
            V("comma") *
            V("sign")^-1 *
            V("digit")^1
         )^0,

      varinnerperc =
         V("colon") *
         (
            (
               V("stringperc")^1 *
               V("equal") *
               (
                  V("variableexclam") +
                  V("stringperc")
               )^0
            ) +
            V("substring")
         ),
      varinnerexclam =
         V("colon") *
         (
            (
               V("stringexclam")^1 *
               V("equal") *
               (
                  V("variableperc") +
                  V("stringexclam")
               )^0
            ) +
            V("substring")
         ),

      variableperc = V("percent") * V("variablename") * V("varinnerperc")^-1 * V("percent"),
      variableexclam = V("exclam") * V("variablename") * V("varinnerexclam")^-1 * V("exclam"),

      varshortinnersuffix = V("dollar") * V("variablename") * V("colon"),
      filechar = makepattern(handler, "boundary", filechar),
      varshortinner = V("tilde") * V("filechar")^1 * V("varshortinnersuffix")^-1,
      variableshort = V("percent") * V("varshortinner")^-1 * V("variableordigit"),

      variable = V("variableperc") + V("variableexclam") + V("variableshort"),

      key_set = makepattern(handler, "keyword", key_set),
      spacer = makepattern(handler, "space", high.spacer),
      option = makepattern(handler, "default", option),
      dquote = makepattern(handler, "boundary", high.dquote),

      assignment =
         V("key_set") *
         V("spacer")^1 *
         (
            V("option") *
            V("spacer")^1
         )^0 *
         V("dquote")^-1 *
         V("variablename"),

      label = makepattern(handler, "label", label),

      pattern =
         V("comment") +
         V("assignment") +
         V("keyword") +
         V("variable") +
         V("label") +
         V("boundary") +
         V("line") +
         V("spacer") +
         V("default"),

      visualizer =
         V("pattern")^1
   }
)

local parser = P(grammar)

visualizers.register("cmd", { parser = parser, handler = handler, grammar = grammar } )
