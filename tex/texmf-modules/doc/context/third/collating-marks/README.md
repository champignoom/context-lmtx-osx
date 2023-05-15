# Module: Collating Marks

## Editorial

Author  = W. Egger
Version = 2023.04.15
License = Public Domain

## Introduction

Collating marks are small black rules placed on the spine of printed sections. On each section the mark is moved by the length of the black rule. When the book is assembled on the spine appears a stair like pattern. Continuity of this pattern insures that the book is ordered in the correct sequence of sections.

## Usage

The module is used in connection with arranging pages for folding to form sections.

Depending on the arranging scheme used the module must be set up accordingly in the set of MetaPost variables.

### Example:

Example setup for the collating marks:

\usemodule[collatingmarks][Collatingmarks=yes]

\setupMPvariables
	[pages=8,         % pages per sheet of paper doublesided
	sheets=2,         % sheets of paper used per section
	horpageshift=0.5mm, % used for correction if horizontal page-shifting is used
	frenchdoors=false,
	wickel=false]             

This setup is used for the arranging scheme \setuparranging[2*4*2] which indicates that it is double-sided printed with 4 pages recto and verso and there are two sheets of paper forming together the sections containing 16 pages.

The shift parameter is used to adjust the position of the collating mark centered on the spine. This is specially important when a horizontal shift-list is used for arranging!

Example setup for horizontal page shifting:

\definepageshift
  [hor]
	[horizontal]
	[1mm,-1mm,.75mm,-.75mm,.5mm,-.5mm,.25mm,0mm,
	 0mm,-.25mm,.5mm,-.5mm,.75mm,-.75mm,1mm,-1mm]

\setuppageshift[paper][hor] %paper= arrange only, horizontal only

\setuparranging[2*4*2]
