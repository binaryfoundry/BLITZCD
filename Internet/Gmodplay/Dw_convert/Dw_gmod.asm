* DW_GMOD.asm
*
* This is a very simple example of a GMOD interface.  It can be used
* to turn Dave Whittaker modules into GMOD modules by tacking a
* short GMOD header onto the beginning of the file.  (I chose this
* particular format since the player code is already embedded in the
* module, so it doesn't need to be included here.)  To make a
* working example program, you'll have to link it with DW_Convert.c
* (assuming you have a C compiler).
*
* To use this code (or a variation you create to play your own type
* of module), the main program that actually writes modules to disk
* simply needs to copy this bit of code out just before the main
* module.  An example of how to do this is in a high-level language
* is shown in DW_Convert.c; in assembly language this operation is
* trivial.
*
* If you want to assemble this code directly into a module (i.e.
* using 'INCBIN' at the end to include the module), you can do this,
* but you'll either have to tell your assembler to output in 'raw'
* format (without standard AmigaDOS object file headers and such) or
* manually strip off the baggage after assembling.
*
* Always remember that all GMOD code such as this must be completely
* PC-relative (unless you do your own relocation or use the
* gmod_LoadAddress to specify an absolute start address, which
* hopefully you won't do).


	include "GMOD.i"


	section	"__MERGED",data

*** Entrypoints in Dave Whittaker modules
*** (offsets from the beginning of the original DW module)

* Note that DW modules nicely save all registers, so we can jump to these
* entrypoints directly.  Other types of player code may need a little
* code to save and restore registers D2-D7/A2-A6.

dwstartentry	equ	$00
dwvbentry	equ	$0e
dwstopentry	equ	$1c


* We use the _HeaderBegin and _HeaderEnd labels in the DW_Convert.c program
* to find out where and how big the header is.
	xdef	_HeaderBegin,_HeaderEnd
_HeaderBegin:


* This structure must be at the very beginning of the file.
first:
	dc.l	'GMOD'                  ; ID
	dc.l	'_DW_'                  ; Maker (doesn't really matter in this case)
	dc.l	0                       ; LoadAddress (zero means relocatable)
	dc.l	gmod_Hook               ; MaxVecOfs (one entry past the last one)
	gmodnop                         ; InitMusic
	gmodbra	dwmodule+dwstartentry   ; StartMusic
	gmodbra	dwmodule+dwstopentry    ; StopMusic
	gmodnop                         ; EndMusic
	gmodnop                         ; Reserved
	gmodnop                         ; ContinueMusic
	gmodbra dwmodule+dwvbentry      ; VBlank50
	gmodnop                         ; VBlank60
	gmodnop                         ; Channel0
	gmodnop                         ; Channel1
	gmodnop                         ; Channel2
	gmodnop                         ; Channel3
	gmodnop                         ; GetNumSongs
	gmodnop                         ; GetSongName
	gmodbra getauthor               ; GetSongAuthor
	gmodnop	                        ; GetFrequency
	gmodnop                         ; TimerTick
        gmodnop                         ; GetMakerName
	                                ; Hook (first unused entry)


* Example of an optional entrypoint for author identification
getauthor:
	lea	authorname(pc),a0
	move.l	a0,d0	; All returns are in D0
	rts

authorname	dc.b	"Dave Whittaker",0

	cnop	0,4	; Pad out to the next longword boundary just to be safe

* DW_Convert.c uses this label to find out how big the header is...
_HeaderEnd:


* The actual module begins right at this label...
dwmodule:


	end
