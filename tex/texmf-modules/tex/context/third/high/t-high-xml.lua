if not modules then
   modules = {}
end

modules ['t-high-xml'] = {
   version   = 1.0,
   comment   = "Syntax Highlighter for XML",
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
   startinline  = function() context.XmlSnippet(false,"{") end,
   stopinline   = function() context("}") end,
   startdisplay = function() context.startXmlSnippet() end,
   stopdisplay  = function() context.stopXmlSnippet () end,
   name         = function(s) verbatim.XmlSnippetName(s) end,
   key          = function(s) verbatim.XmlSnippetKey(s) end,
   boundary     = function(s) verbatim.XmlSnippetBoundary(s) end,
   string       = function(s) verbatim.XmlSnippetString(s) end,
   equal        = function(s) verbatim.XmlSnippetEqual(s) end,
   entity       = function(s) verbatim.XmlSnippetEntity(s) end,
   comment      = function(s) verbatim.XmlSnippetComment(s) end,
   cdata        = function(s) verbatim.XmlSnippetCdata(s) end,
   instruction  = function(s) verbatim.XmlSnippetInstruction(s) end,
   attrval      = function(s) verbatim.XmlSnippetAttrVal(s) end,
}

local comment = P("--")
local name = (high.letter + high.digit + S("_-."))^1
local entity = P("&") * (1-P(";"))^1 * P(";")
local openbegin = P("<")
local openend = P("</")
local closebegin = P("/>") + P(">")
local closeend = P(">")
local opencomment = P("<!--")
local closecomment = P("-->")
local openinstruction = P("<?")
local closeinstruction = P("?>")
local opencdata = P("<![CDATA[")
local closecdata = P("]]>")

local grammar = visualizers.newgrammar(
   "default",
   { "visualizer",

     sstring =
        makepattern(handler, "string", high.dquote) *
        (
           V("whitespace") +
           makepattern(handler, "attrval", high.utf8char - high.dquote)
        )^0 *
        makepattern(handler, "string", high.dquote),

     dstring =
        makepattern(handler, "string", high.squote) *
        (
           V("whitespace") +
           makepattern(handler, "attrval", high.utf8char - high.squote)
        )^0 *
        makepattern(handler, "string", high.squote),

     entity = makepattern(handler, "entity", entity),

     name =
        makepattern(handler, "name", name) *
        (
           makepattern(handler, "default", high.colon) *
           makepattern(handler, "name", name)
        )^0,

     key =
        makepattern(handler, "key", name) *
        (
           makepattern(handler, "key", high.colon) *
           makepattern(handler, "key", name)
        )^0,

     attribute =
        V("optionalwhitespace") *
        V("key") *
        V("optionalwhitespace") *
        makepattern(handler, "equal", high.equal) *
        V("optionalwhitespace") *
        (
           V("dstring") +
           V("sstring")
        ) *
        V("optionalwhitespace"),

     open =
        makepattern(handler, "boundary", openbegin)
        * V("name")
        * V("optionalwhitespace")
        * V("attribute")^0
        * makepattern(handler, "boundary", closebegin),

     close =
        makepattern(handler, "boundary", openend) *
        V("name") *
        V("optionalwhitespace") *
        makepattern(handler, "boundary", closeend),

     comment =
       makepattern(handler, "comment", opencomment) *
       (
          V("whitespace") +
          makepattern(handler, "comment", (high.utf8char - closecomment - high.newline)^1)
       )^0 *
       makepattern(handler, "comment", closecomment),

     cdata =
        makepattern(handler, "boundary", opencdata) *
        (
           V("whitespace") +
           makepattern(handler, "cdata", (1-closecdata)^1)
        )^0 *
        makepattern(handler, "boundary", closecdata),

     instruction =
        makepattern(handler, "instruction", openinstruction) *
        V("name") *
        V("optionalwhitespace") *
        V("attribute")^0 *
        V("optionalwhitespace") *
        makepattern(handler, "instruction", closeinstruction),

     pattern =
        V("comment") +
        V("instruction") +
        V("cdata") +
        V("close") +
        V("open") +
        V("entity") +
        V("space") +
        V("attribute")^1 +
        V("line") +
        V("default"),

     visualizer =
        V("pattern")^1
   }
)

local parser = P(grammar)

visualizers.register("xml", { parser = parser, handler = handler, grammar = grammar } )
