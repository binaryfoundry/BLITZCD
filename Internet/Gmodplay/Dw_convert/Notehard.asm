* notehard.asm - NotePlayer that directly uses the Amiga audio hardware
* Copyright 1992 Bryan Ford
* See distribution terms in NotePlayer.doc
* $Id: notehard.asm,v 1.1 92/05/15 15:08:26 BAF Exp $

        include "exec/types.i"
        include "hardware/custom.i"
        include "hardware/dmabits.i"
        include "bry/macros.i"

VERSION         equ     1       ; Version of Player.doc this NotePlayer is written for
REVISION        equ     0

CLOCK           equ     3579545

CUSTOM          equ     $dff000

        code    text

*** NoteHard - Jump table providing the hardware NotePlayer interface
        xdef    NoteHard,_NoteHard
NoteHard
_NoteHard
        jmp     noteinfo(pc)
        jmp     noteinit(pc)
        jmp     notefinish(pc)
        jmp     notestart(pc)
        jmp     notestop(pc)
        jmp     notefreqvol(pc)
        jmp     notefreq(pc)
        jmp     notevol(pc)

*** NoteHardDMACall - Pointer to routine client needs to call after about 7 scanlines, or NULL
        xdef    NoteHardDMACall,_NoteHardDMACall
NoteHardDMACall
_NoteHardDMACall
                ds.l    1

*** noteinfo - Return information about this note player
noteinfo
        lea     \noteinfo(pc),a0
        move.l  a0,d0
        rts

\noteinfo
        dc.b    VERSION
        dc.b    REVISION
        dc.b    3 ; NOTEF_CHIPSAMPLES!NOTEF_PERIOD
        dc.b    4
        dc.l    \noteplayername
\noteinfoend

\noteplayername         dc.b    "Amiga hardware NotePlayer",0
        even

*** noteinit - Initialize the note player
* d0.b = Number of channels needed (1-128) (ignored)
* a0 = Stereo orientation (ignored)
* Returns: d0 = Zero if successful, pointer to error message on failure
noteinit
        moveq   #0,d0
        ; fall through...
*** notefinish - Shut down the note player
notefinish
        lea     CUSTOM,a0
        move.w  #DMAF_AUDIO,dmacon(a0)
        clr.w   aud0+ac_dat(a0)
        clr.w   aud1+ac_dat(a0)
        clr.w   aud2+ac_dat(a0)
        clr.w   aud3+ac_dat(a0)
        rts

*** findchan - Find hardware channel address
* d2.b = Channel number
* Returns:
* a1 = Channel address
* a0/d0 = Saved
findchan
        moveq   #0,d1
        move.b  d2,d1
        lsl.w   #4,d1
        lea     CUSTOM+aud0,a1
        adda.w  d1,a1
        rts

*** notestop - Stop any currently playing note in a channel
* May be called from interrupt code level 4 or lower
* d2.b = Channel number
notestop
        moveq   #0,d0
        moveq   #0,d1
        ; fall through...
*** notestart - Start playing a note immediately
* May be called from interrupt code level 4 or lower
* d2.b = Channel number
* a0 = One-shot sample data
* d0.l = One-shot sample length (0 if no one-shot part)
* a1 = Repeat sample data
* d1.l = Repeat sample length (0 if no repeat part)
* d3.w = Sample frequency (if 0, then high word contains period)
* d4.w = Volume at which to play sample (0-$100)
notestart
        move.l  a1,-(sp)
        move.w  d1,-(sp)

        or.w    d0,d1                           ; See if we're just turning the note off
        bz      \noteoff

        bsr     findchan

        bsr     calcper
        bsr     calcvol

        lsr.w   #1,d0                           ; Stuff the one-shot pointers
        bnz     \hasoneshot
        moveq   #2,d0
        sub.l   a0,a0
\hasoneshot
        move.l  a0,ac_ptr(a1)
        move.w  d0,ac_len(a1)

        moveq   #0,d0                           ; Turn DMA for this channel off
        bset    d2,d0
        move.w  d0,CUSTOM+dmacon

        move.w  (sp)+,d1                        ; Find repeat part (a1/d1.w)
        move.l  (sp)+,a1
        lsr.w   #1,d1
        bnz     \hasrepeat
        moveq   #2,d1
        sub.l   a1,a1
\hasrepeat

        lea     \dmaflags(pc),a0                ; Save the information we'll need later
        or.w    d0,(a0)
        move.b  d2,d0
        add.w   d0,d0
        move.w  d1,\repeatlen-\dmaflags(a0,d0.w)
        add.w   d0,d0
        move.l  a1,\repeatptr-\dmaflags(a0,d0.w)

        lea     \dma1(pc),a0                    ; Client will call us back after about 7 scanlines
        move.l  a0,NoteHardDMACall ; -\dmaflags(a0)  FIXME
        rts

\dma1
        move.w  #DMAF_SETCLR,d0                 ; Turn DMA on
        or.w    \dmaflags(pc),d0
        move.w  d0,CUSTOM+dmacon

        lea     \dma2(pc),a0                    ; Wait another 7 scanlines or so
        move.l  a0,NoteHardDMACall
        rts

\dma2
        lea     CUSTOM,a0                       ; Set the repeat pointers
        move.w  \dmaflags(pc),d0
        lsr.w   #1,d0
        bcc     \dmano0
        move.l  \repeatptr+4*0(pc),aud0+ac_ptr(a0)
        move.w  \repeatlen+2*0(pc),aud0+ac_len(a0)
\dmano0
        lsr.w   #1,d0
        bcc     \dmano1
        move.l  \repeatptr+4*1(pc),aud1+ac_ptr(a0)
        move.w  \repeatlen+2*1(pc),aud1+ac_len(a0)
\dmano1
        lsr.w   #1,d0
        bcc     \dmano2
        move.l  \repeatptr+4*2(pc),aud2+ac_ptr(a0)
        move.w  \repeatlen+2*2(pc),aud2+ac_len(a0)
\dmano2
        lsr.w   #1,d0
        bcc     \dmano3
        move.l  \repeatptr+4*3(pc),aud3+ac_ptr(a0)
        move.w  \repeatlen+2*3(pc),aud3+ac_len(a0)
\dmano3
        clr.l   NoteHardDMACall
        clr.w   \dmaflags
        rts

\dmaflags       ds.w    1
\repeatlen      ds.w    4
\repeatptr      ds.l    4

\noteoff
        addq    #6,sp

        moveq   #0,d0                           ; Turn DMA for this channel off
        bset    d2,d0
        move.w  d0,CUSTOM+dmacon
        rts

*** calcper - Calculate period and insert it in an IOAudio
* a1 = Hardware channel
* d3.l = Frequency/period value
* a0/a1/d0 = Saved
calcper
        tst.w   d3
        bnz     \freq
        swap    d3
        move.w  d3,ac_per(a1)
        swap    d3
        rts
\freq
        move.l  #CLOCK,d1
        divu.w  d3,d1
        move.w  d1,ac_per(a1)
        rts

*** calcvol - Calculate volume and insert it in an IOAudio
* a1 = Hardware channel
* d4.w = Volume (0-$100)
* a0/a1/d0 = Saved
calcvol
        move.w  d4,d1
        lsr.w   #2,d1
        move.w  d1,ac_vol(a1)
        rts

*** notefreqvol - Change the frequency and volume of the currently playing note
* May be called from interrupt code level 4 or lower
* d2.b = Channel number
* d3.w = New sample frequency (if 0, then high word contains period)
* d4.w = New volume (0-$100)
notefreqvol
        bsr     findchan
        bsr     calcper
        bra     calcvol

*** notefreq - Change the frequency of the currently playing note
* May be called from interrupt code level 4 or lower
* d2.b = Channel number
* d3.w = New sample frequency (if 0, then high word contains period)
notefreq
        bsr     findchan
        bra     calcper

*** notevol - Change the volume of the currently playing note
* May be called from interrupt code level 4 or lower
* d2.b = Channel number
* d4.w = New volume (0-$100)
notevol
        bsr     findchan
        bra     calcvol

        end
