if not modules then
   modules = {}
end

modules ['t-high-ini'] = {
   version   = 1.0,
   comment   = "Syntax Highlighter for INI Files",
   author    = "Christoph Reller",
   copyright = "Christoph Reller",
   license   = "GNU General Public License"
}

local P, S, V = lpeg.P, lpeg.S, lpeg.V

local context = context
local verbatim = context.verbatim
local makepattern = visualizers.makepattern
local high = userdata.high

local handler = visualizers.newhandler {
   startinline  = function() context.IniSnippet(false,"{") end,
   stopinline   = function() context("}") end,
   startdisplay = function() context.startIniSnippet() end,
   stopdisplay  = function() context.stopIniSnippet() end,
   boundary     = function(s) verbatim.IniSnippetBoundary(s) end,
   section      = function(s) verbatim.IniSnippetSection(s) end,
   key          = function(s) verbatim.IniSnippetKey(s) end,
   value        = function(s) verbatim.IniSnippetValue(s) end,
   equal        = function(s) verbatim.IniSnippetEqual(s) end,
   comment      = function(s) verbatim.IniSnippetComment(s) end,
}

local spacer = high.spacer
local opensection = P("[")
local closesection = P("]")
local opencomment = P(";")
local key = (high.utf8char - high.equal - high.newline)^1
local word = high.nonwhitespace^1
local sectionname = (high.utf8char - closesection)^0

local grammar = visualizers.newgrammar(
   "default",
   {
      "visualizer",

      spacer = makepattern(handler, "space", spacer),

     opensection = makepattern(handler, "boundary", opensection),
     closesection = makepattern(handler, "boundary", closesection),
     sectionname =  makepattern(handler, "section", sectionname),

     section =
        V("opensection") *
        V("sectionname") *
        V("closesection") *
        V("spacer")^0,

     key = makepattern(handler, "key", key),
     equal = makepattern(handler, "equal", high.equal),

     valuestring = makepattern(handler, "value", word),
     value =
        (
           V("spacer") +
           V("valuestring")
        ),

     config =
        V("key") *
        V("equal") *
        V("value")^0,

     opencomment = makepattern(handler, "comment", opencomment),
     commentstring = makepattern(handler, "comment", word),

     comment = V("opencomment") *
        (
           V("spacer") +
           V("commentstring")
        )^0,

     pattern =
        V("section") +
        V("config") +
        V("comment") +
        (
           V("opensection") *
           V("optionalwhitespace")
        ) +
        (
           V("closesection") *
           V("optionalwhitespace")
        ) +
        V("value")^1 +
        V("spacer") +
        V("default"),

     visualizer =
        V("pattern")^1
   } )

local parser = P(grammar)

visualizers.register("ini", { parser = parser, handler = handler, grammar = grammar } )
