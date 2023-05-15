The files you have downloaded allow you to use the GFSDidot OpenType fonts
with CONTEXT. In order to use them, put this into the preamble of your tex
files:

\usetypescriptfile[gfsdidot]
\usetypescript[GFSDidot][ec] % or [texnansi]
\setupbodyfont[MyGFSDidot,12pt]

(or whatever size you want). The fonts work with texnansi- and
ec-encoding. 

The font has oldstyle-figures by default. If you prefer lining figures,
there's a variant that you call like so:

\usetypescriptfile[gfsdidot]
\usetypescript[GFSDidotlf][ec] % or texnansi
\setupbodyfont[MyGFSDidotlf,12pt]

The fonts themselves are copyrighted by the Greek Font Society; their
readme and a specimen are included. The metrics, mapfile, and typescript
have been produced by Thomas A. Schmitz and are given to the public domain.

Happy TeXing!
