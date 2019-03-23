* note.i - Note player public include file - Copyright 1992 Bryan Ford *
* $Id: note.i,v 1.1 92/05/25 10:48:15 BAF Exp $
        ifnd    BRY_NOTE_I
BRY_NOTE_I      set     1


*** Entrypoints into the NotePlayer jump table
                rsreset
NoteInfo        rs.l    1       ; info = NoteInfo()
NoteInit        rs.l    1       ; success = NoteInit(channels,stereoarray)
NoteFinish      rs.l    1       ; NoteFinish()
NoteStart       rs.l    1       ; NoteStart(chan:d2,oneshot:a0,oneshotlen:d0,rep:a1,replen:d0,freq:d3,vol:d4)
NoteStop        rs.l    1       ; NoteStop(chan:d2)
NoteFreqVol     rs.l    1       ; NoteFreqVol(chan:d2,freq:d3,vol:d4)
NoteFreq        rs.l    1       ; NoteFreq(chan,freq:d3)
NoteVol         rs.l    1       ; NoteVol(chan,vol:d4)


*** Info structure returned by NoteInfo entrypoint
                rsreset
note_Version    rs.b    1       ; Version of NotePlayer.doc that applies to this NotePlayer
note_Revision   rs.b    1       ; Revision number of this NotePlayer
note_Flags      rs.b    1       ; Defined below
note_Channels   rs.b    1       ; Maximum number of channels this NotePlayer can handle
note_Name       rs.l    1       ; Pointer to descriptive name of this NotePlayer


* Values for note_Flags
NOTEB_CHIPSAMPLES       equ     0       ; All samples must be in chip memory (applies only to Amiga)
NOTEB_PERIOD            equ     1       ; Amiga period supported as an alternative to frequency

NOTEF_CHIPSAMPLES       equ     1
NOTEF_PERIOD            equ     2


        end
