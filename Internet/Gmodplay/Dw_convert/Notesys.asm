* notesys.asm - NotePlayer module for Amiga using system (audio.device)
* Copyright 1992 Bryan Ford
* See distribution terms in NotePlayer.doc
* $Id: notesys.asm,v 3.1 92/09/14 18:35:19 BAF Exp Locker: BAF $

        include "exec/types.i"
        include "exec/io.i"
        include "exec/tasks.i"
        include "exec/funcdef.i"
        include "exec/exec_lib.i"
        include "devices/audio.i"
        include "bry/macros.i"

VERSION         equ     1       ; Version of Player.doc this NotePlayer is written for
REVISION        equ     0

IOREQS          equ     3*4+2   ; Two WRITEs and another command per channel, plus two extra for good measure

STACKSIZE       equ     256

CLOCK           equ     3579545

        code    text

*** NoteSys - Jump table providing standard note player interface
        xdef    NoteSys,_NoteSys
NoteSys
_NoteSys
        jmp     noteinfo(pc)
        jmp     noteinit(pc)
        jmp     notefinish(pc)
        jmp     notestart(pc)
        jmp     notestop(pc)
        jmp     notefreqvol(pc)
        jmp     notefreq(pc)
        jmp     notevol(pc)

*** NoteSysMasterVol - Set the (mono) master volume at which to play notes
* d0 = New master volume, 0-$100
        xdef    NoteSysMasterVol,_NoteSysMasterVol,@NoteSysMasterVol
_NoteSysMasterVol
        move.w  4+2(sp),d0
NoteSysMasterVol
@NoteSysMasterVol
        move.w  d0,d1
        bra     NoteSysMasterVolBal

*** NoteSysMasterVolBal - Set the master volume/balance
* d0 = New master volume for left channels, 0-$100
* d1 = New master volume for right channels, 0-$100
        xdef    NoteSysMasterVolBal,_NoteSysMasterVolBal,@NoteSysMasterVolBal
_NoteSysMasterVolBal
        movem.l 4(sp),d0/d1
NoteSysMasterVolBal
@NoteSysMasterVolBal
        movem.l d2/d6-d7/a4/a6,-(sp)
        lea     k,a4

        st.b    volinitflag-k(a4)

        lsr.w   #2,d0
        lsr.w   #2,d1

        cmp.b   mastervoltab+1-1-k(a4),d0
        bne     \changed
        cmp.b   mastervoltab+2-1-k(a4),d1
        beq     \out
\changed
        move.b  d0,mastervoltab-1+1-k(a4)
        move.b  d1,mastervoltab-1+2-k(a4)
        move.b  d1,mastervoltab-1+4-k(a4)
        move.b  d0,mastervoltab-1+8-k(a4)

        move.b  channels-k(a4),d2
        subq.b  #1,d2
\loop
        bsr     findquickreq
        bz      \next
        move.w  chanpervol-k(a4,d6.w),ioa_Period(a1)
        move.w  IO_UNIT+2(a1),d1
        moveq   #0,d0
        move.b  mastervoltab-1-k(a4,d1.w),d0
        mulu.w  chanpervol+2-k(a4,d6.w),d0
        move.w  d0,-(sp)
        move.b  (sp)+,ioa_Volume+1(a1)
        moveq   #ADCMD_PERVOL,d0
        bsr     doquickreq
\next
        dbra    d2,\loop
\out
        movem.l (sp)+,d2/d6-d7/a4/a6
        rts

*** NoteSysAudioPri - Set the audio channel allocation priority
        xdef    NoteSysAudioPri,_NoteSysAudioPri,@NoteSysAudioPri
* d0 = New audio allocation priority (-128 to 127)
_NoteSysAudioPri
        move.l  4(sp),d0
NoteSysAudioPri
@NoteSysAudioPri
        move.b  d0,allocpri
        rts

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

\noteplayername         dc.b    "Amiga audio.device NotePlayer",0
        even

*** noteinit - Initialize the note player
* d0.b = Number of channels needed (1-128)
* a0 = Preferred stereo orientation for each channel (NULL = Amiga default)
* Returns: d0 = Zero if successful, pointer to error message on failure
noteinit
        movem.l d2/a2/a4/a6,-(sp)
        move.l  4,a6
        lea     k,a4

        cmp.b   #4,d0                           ; Number of channels requested
        bhi     \toomanychannels
        move.b  d0,channels-k(a4)

        lea     chanpos-k(a4),a1                ; Copy channel position preference array
        clr.l   (a1)
        move.l  a0,d1
        bz      \defchanprefs
\chanprefsloop
        move.b  (a0)+,(a1)+
        subq.b  #1,d0
        bhi     \chanprefsloop
\defchanprefs

        bsr     notefinish                      ; Stop anything we were doing before

        bset.b  #0,volinitflag-k(a4)            ; Make sure master volume is initialized
        bnz     \masvolinit
        moveq   #$40,d0
        move.b  d0,mastervoltab-1+1-k(a4)
        move.b  d0,mastervoltab-1+2-k(a4)
        move.b  d0,mastervoltab-1+4-k(a4)
        move.b  d0,mastervoltab-1+8-k(a4)
\masvolinit

        lea     sitport-k+MP_MSGLIST(a4),a1     ; Initialize sitport
        NEWLIST a1
        move.b  #NT_MSGPORT,sitport-k+LN_TYPE(a4)
        move.b  #PA_IGNORE,sitport-k+MP_FLAGS(a4)

        lea     taskport-k+MP_MSGLIST(a4),a1    ; Initialize taskport
        NEWLIST a1
        move.b  #NT_MSGPORT,taskport-k+LN_TYPE(a4)
        move.b  #PA_IGNORE,taskport-k+MP_FLAGS(a4)      ; The task will change this right away

        lea     sitport-k(a4),a0                ; Initialize the first IO request
        move.l  a0,ioreqs+MN_REPLYPORT-k(a4)
        clr.l   ioreqs+ioa_Length-k(a4)         ; Don't allocate channels on opening the device

        lea     \audiodevname(pc),a0            ; Open audio.device
        moveq   #0,d0
        lea     ioreqs-k(a4),a1
        moveq   #0,d1
        jsr     _LVOOpenDevice(a6)
        tst.b   d0
        bne     \openfail

        move.w  #(IOREQS-1)*ioa_SIZEOF/4-1,d0   ; Replicate the IO request
        lea     ioreqs-k(a4),a0
        lea     ioa_SIZEOF(a0),a1
        move.b  #NT_REPLYMSG,LN_TYPE(a0)
\rep
        move.l  (a0)+,(a1)+
        dbra    d0,\rep

        moveq   #IOREQS-1,d2                    ; Collect all requests on the sitport
        lea     ioreqs-k(a4),a2
\collect
        move.l  a2,a1
        jsr     _LVOReplyMsg(a6)
        lea     ioa_SIZEOF(a2),a2
        dbra    d2,\collect

        move.w  #(NT_TASK<<8)!(100),tc-k+LN_TYPE(a4)    ; Initialize task
        move.l  #\notetaskname,tc-k+LN_NAME(a4)
        move.l  #stack,tc-k+TC_SPLOWER(a4)
        lea     stack+STACKSIZE-k(a4),a0
        move.l  a0,tc-k+TC_SPUPPER(a4)
        move.l  a0,tc-k+TC_SPREG(a4)
        lea     tc-k+TC_MEMENTRY(a4),a0
        NEWLIST a0

        lea     tc-k(a4),a1                     ; Start the task
        lea     notetask(pc),a2
        jsr     _LVOAddTask(a6)
        tst.l   d0
        bnz     \taskok
        cmp.w   #36,LIB_VERSION(a6)
        bhs     \addtaskfail
\taskok
        st.b    taskadded-k(a4)

        move.b  channels-k(a4),d2               ; Try to allocate the channels we need now
        subq.b  #1,d2
        clr.l   chanallocflags-k(a4)
\allocloop
        bsr     notestop
        subq.b  #1,d2
        bhs     \allocloop

        moveq   #0,d0
\out
        movem.l (sp)+,d2/a2/a4/a6
        rts

\openfail
        clr.l   ioreqs+IO_DEVICE-k(a4)
        pea     \openfailmes(pc)
        bra     \errerr
\addtaskfail
        pea     \addtaskfailmes(pc)
        bra     \errerr
\toomanychannels
        pea     \toomanychannelsmes(pc)
\errerr
        bsr     notefinish
        move.l  (sp)+,d0
        bra     \out

\audiodevname           dc.b    "audio.device",0

\notetaskname           dc.b    "NotePlayer",0

\toomanychannelsmes     dc.b    "Too many channels requested",0
\addtaskfailmes         dc.b    "Unable to create NotePlayer task",0
\openfailmes            dc.b    "Unable to open audio.device",0

        even

*** notefinish - Shut down the note player, free audio hardware
notefinish
        movem.l d2/a2/a4/a6,-(sp)
        lea     k,a4
        move.l  4,a6

        jsr     _LVOForbid(a6)                  ; Maybe not necessary, but just in case...

        sub.l   a1,a1                           ; Point both ports to this task for closing down
        jsr     _LVOFindTask(a6)
        move.l  d0,sitport+MP_SIGTASK-k(a4)
        move.w  #(PA_SIGNAL<<8)!(SIGB_SINGLE),sitport+MP_FLAGS-k(a4)
        move.l  d0,taskport+MP_SIGTASK-k(a4)
        move.w  #(PA_SIGNAL<<8)!(SIGB_SINGLE),taskport+MP_FLAGS-k(a4)

        tst.b   taskadded-k(a4)                 ; Get rid of the task
        bz      \notask
        lea     tc-k(a4),a1
        jsr     _LVORemTask(a6)
        clr.b   taskadded-k(a4)
\notask

        jsr     _LVOPermit(a6)

        tst.l   ioreqs+IO_DEVICE-k(a4)
        bz      \audioclosed

        moveq   #4-1,d2                         ; Free all audio channels
\freechans
        lea     ioreqs-k(a4),a1
        move.w  #ADCMD_FREE,IO_COMMAND(a1)
        move.b  chanmasks-k(a4,d2),IO_UNIT+3(a1)
        jsr     _LVODoIO(a6)
        dbra    d2,\freechans
\alreadyfree
        clr.l   chanmasks-k(a4)

        moveq   #IOREQS-1,d2                    ; Abort any IO requests still in progress
        lea     ioreqs-k(a4),a2
\abortreqs
        move.l  a2,a1
        jsr     _LVOAbortIO(a6)
        move.l  a2,a1
        jsr     _LVOWaitIO(a6)
        lea     ioa_SIZEOF(a2),a2
        dbra    d2,\abortreqs

        lea     ioreqs-k(a4),a1                 ; Close the audio.device
        jsr     _LVOCloseDevice(a6)
        clr.l   ioreqs+IO_DEVICE-k(a4)
\audioclosed

        movem.l (sp)+,d2/a2/a4/a6
        rts

*** findquickreq - Find an available IOAudio and prepare it for quick I/O
* d2.b = Channel number (NOT.B to set ADIOF_SYNCCYCLE)
* a4 = k
* Returns:
* NZ if successful, a1 = Ready IOAudio (still on sitport)
* Z if failed, d0 = 0
* d2.w = Real channel number
* d6.w = Channel number * 4
* d7.b = Flags for IORequest
findquickreq
        move.l  sitport+MP_MSGLIST+LH_HEAD,a1   ; Find any available request
        move.l  LN_SUCC(a1),d0                  ; (Don't even need to Disable around this)
        bz      \out

        moveq   #IOF_QUICK,d7                   ; Find channel and flags
        ext.w   d2
        bpl     \nosync
        moveq   #IOF_QUICK!ADIOF_SYNCCYCLE,d7
        not.w   d2
\nosync

        move.b  chanmasks-k(a4,d2.w),IO_UNIT+3(a1)
        bz      \nochan

        move.w  d2,d6
        lsl.w   #2,d6

        move.b  d7,IO_FLAGS(a1)
\out
        rts

\nochan
        bsr     allocbounce
        moveq   #0,d0
        rts

*** findreq - Find an available IOAudio and prepare it for slow I/O
* d2.w = Real channel number
* d7.b = Flags for IORequest
* a4 = k
* Returns:
* NZ if successful, a1 = Ready IOAudio (removed from sitport), a6 = IO_DEVICE from IO request
* Z if failed, d0 = 0
findreq
        move.l  4,a6                            ; Remove an IO request
        lea     sitport,a0
        jsr     _LVOGetMsg(a6)
        tst.l   d0
        bz      \out
        move.l  d0,a1

        move.b  chanmasks-k(a4,d2.w),IO_UNIT+3(a1)

        move.l  IO_DEVICE(a1),a6                ; Find audio.device address

        moveq   #1,d0
\out
        rts

*** notestop - Stop any currently playing note in a channel
* May be called from interrupt code level 4 or lower
* d2.b = Channel number (NOT.B to stop only after the current cycle completes)
notestop
        moveq   #0,d0
        moveq   #0,d1
        ; fall through...
*** notestart - Start playing a note immediately
* May be called from interrupt code level 4 or lower
* d2.b = Channel number (NOT.B to make the change only after the current cycle completes)
* a0 = One-shot sample data
* d0.l = One-shot sample length (0 if no one-shot part)
* a1 = Repeat sample data
* d1.l = Repeat sample length (0 if no repeat part)
* d3.w = Sample frequency (if 0, then high word contains period)
* d4.w = Volume at which to play sample (0-$100)
notestart
        movem.l d0-d2/d6-d7/a0-a2/a4/a6,-(sp)
        lea     k,a4

        tst.b   d2                              ; Stop current note
        bpl     \stopnow
\stopcycle                                      ; Stop at the end of this cycle
        bsr     findquickreq
        bz      \out
        move.l  chanoneshot-k(a4,d6.w),d0       ; Cancel the repeat part if we haven't gotten to it yet
        bz      \canrepout
        move.l  d0,a0
        cmp.b   #NT_MESSAGE,LN_TYPE(a0)
        bne     \canrepout
        move.l  chanrepeat-k(a4,d6.w),d0
        bz      \canrepout
        move.b  IO_UNIT+3(a1),d1
        move.l  a1,-(sp)
        move.l  d0,a1
        cmp.b   IO_UNIT+3(a1),d1
        bne     \canrepout2
        move.l  IO_DEVICE(a1),a6
        jsr     DEV_ABORTIO(a6)
\canrepout2
        move.l  (sp)+,a1
\canrepout
        moveq   #ADCMD_FINISH,d0
        bsr     doquickreq
        bz      \stopout
        bra     \out
\stopnow                                        ; Stop immediately
        bsr     findquickreq
        bz      \out
        moveq   #CMD_FLUSH,d0
        bsr     doquickreq
        bnz     \out
\stopout

        sub.l   a2,a2                           ; One-shot part
        tst.l   (sp)
        bz      \nooneshot
        bsr     findreq
        bz      \out
        move.w  #CMD_WRITE,IO_COMMAND(a1)
        move.l  20(sp),ioa_Data(a1)
        move.l  (sp),ioa_Length(a1)
        move.w  #1,ioa_Cycles(a1)
        move.b  #ADIOF_PERVOL,IO_FLAGS(a1)
        move.l  a1,a2
        bsr     calcper
        bsr     calcvol
        jsr     DEV_BEGINIO(a6)
\nooneshot
        move.l  a2,chanoneshot-k(a4,d6.w)

        sub.l   a2,a2                           ; Repeat part
        tst.l   4(sp)
        bz      \norepeat
        bsr     findreq
        bz      \out
        move.w  #CMD_WRITE,IO_COMMAND(a1)
        move.l  24(sp),ioa_Data(a1)
        move.l  4(sp),ioa_Length(a1)
        moveq   #0,d7
        move.w  d7,ioa_Cycles(a1)
        tst.l   (sp)
        bnz     \pervolalreadyset
        moveq   #ADIOF_PERVOL,d7
        bsr     calcper
        bsr     calcvol
        move.w  d0,ioa_Volume(a1)
\pervolalreadyset
        move.b  d7,IO_FLAGS(a1)
        move.l  a1,a2
        jsr     DEV_BEGINIO(a6)
\norepeat
        move.l  a2,chanrepeat-k(a4,d6.w)

\out
        movem.l (sp)+,d0-d2/d6-d7/a0-a2/a4/a6
        rts

*** calcper - Calculate period and insert it in an IOAudio
* d3.l = Frequency/period value
* d6.w = Channel * 4
* a1 = IOAudio to put period into
* a4 = k
calcper
        tst.w   d3
        bnz     \freq
        swap    d3
        move.w  d3,ioa_Period(a1)
        move.w  d3,chanpervol-k(a4,d6.w)
        swap    d3
        rts
\freq
        move.l  #CLOCK,d0
        divu.w  d3,d0
        move.w  d0,ioa_Period(a1)
        move.w  d0,chanpervol-k(a4,d6.w)
        rts

*** calcvol - Calculate volume and insert it in an IOAudio
* d4.w = Volume (0-$100)
* d6.w = Channel * 4
* a1 = IOAudio to put period into
* a4 = k
calcvol
        move.w  d4,chanpervol+2-k(a4,d6.w)
        move.w  IO_UNIT+2(a1),d1
        moveq   #0,d0
        move.b  mastervoltab-1-k(a4,d1.w),d0
        mulu.w  d4,d0
        move.w  d0,-(sp)
        move.b  (sp)+,ioa_Volume+1(a1)
        rts

*** notefreqvol - Change the frequency and volume of the currently playing note
* May be called from interrupt code level 4 or lower
* d2.b = Channel number (NOT.B to make the change only after the current cycle completes)
* d3.w = New sample frequency (if 0, then high word contains period)
* d4.w = New volume (0-$100)
notefreqvol
        movem.l d2/d6-d7/a4/a6,-(sp)
        lea     k,a4

        bsr     findquickreq
        bz      \out
        bsr     calcper
        bsr     calcvol
        moveq   #ADCMD_PERVOL,d0
        bsr     doquickreq
\out
        movem.l (sp)+,d2/d6-d7/a4/a6
        rts

*** notefreq - Change the frequency of the currently playing note
* May be called from interrupt code level 4 or lower
* d2.b = Channel number (NOT.B to make the change only after the current cycle completes)
* d3.w = New sample frequency (if 0, then high word contains period)
notefreq
        movem.l d2/d6-d7/a4/a6,-(sp)
        lea     k,a4

        bsr     findquickreq
        bz      \out

        bsr     calcper

        move.w  IO_UNIT+2(a1),d1
        moveq   #0,d0
        move.b  mastervoltab-1-k(a4,d1.w),d0
        mulu.w  chanpervol+2-k(a4,d6.w),d0
        move.w  d0,-(sp)
        move.b  (sp)+,ioa_Volume+1(a1)

        moveq   #ADCMD_PERVOL,d0
        bsr     doquickreq
\out
        movem.l (sp)+,d2/d6-d7/a4/a6
        rts

*** notevol - Change the volume of the currently playing note
* May be called from interrupt code level 4 or lower
* d2.b = Channel number (NOT.B to make the change only after the current cycle completes)
* d4.w = New volume (0-$100)
notevol
        movem.l d2/d6-d7/a4/a6,-(sp)
        lea     k,a4

        bsr     findquickreq
        bz      \out

        cmp.w   chanpervol+2-k(a4,d6.w),d4
        beq     \out

        move.w  chanpervol-k(a4,d6.w),ioa_Period(a1)

        bsr     calcvol

        moveq   #ADCMD_PERVOL,d0
        bsr     doquickreq
\out
        movem.l (sp)+,d2/d6-d7/a4/a6
        rts

*** doquickreq - Send an immediate command to the audio.device
* d0.w = IO Command
* a1 = IOAudio
* d2.w = Real channel number
* a4 = k
* Returns: Z = Successful, NZ = Audio error (generally channel stolen)
doquickreq
        move.w  d0,IO_COMMAND(a1)
        move.l  IO_DEVICE(a1),a6
        move.l  a1,-(sp)
        jsr     DEV_BEGINIO(a6)
        move.l  (sp)+,a1
        tst.b   IO_ERROR(a1)
        bnz     \err
        rts

\err
        bsr     allocbounce
        moveq   #1,d0
        rts

*** allocbounce - Bounce an IOAudio to the note player task for allocation
* a1 = IOAudio (on sitport)
* d2.w = Real channel number
* a4 = k
* Returns:
* a6 = SysBase
allocbounce
        move.l  4,a6

        bset.b  #0,chanallocflags-k(a4,d2.w)    ; Prevent multiple allocation requests from piling up
        bnz     \out

        move.l  a1,-(sp)                        ; Take the request off the sitport
        jsr     _LVODisable(a6)
        move.l  (sp),a1
        jsr     _LVORemove(a6)
        jsr     _LVOEnable(a6)
        move.l  (sp)+,a1

        move.w  #ADCMD_ALLOCATE,IO_COMMAND(a1)  ; Setup request for channel allocation
        move.b  allocpri-k(a4),LN_PRI(a1)
        move.w  d2,ioa_WriteMsg+LN_NAME(a1)     ; Hide the channel number in the message

        tst.b   chanpos-k(a4,d2.w)              ; Find the appropriate channel preference array
        bz      \middle
        bpl     \right
\left
        lea     \leftarray(pc),a0
        bra     \gotarray
\right
        lea     \rightarray(pc),a0
        bra     \gotarray
\middle
        lea     \middlearray(pc),a0
\gotarray
        move.l  a0,ioa_Data(a1)
        moveq   #4,d0
        move.l  d0,ioa_Length(a1)

        move.l  #taskport,MN_REPLYPORT(a1)      ; Send it off to our task
        jsr     _LVOReplyMsg(a6)

\out
        rts

\leftarray      dc.b    %1000,%0001,%0100,%0010
\rightarray     dc.b    %0100,%0010,%1000,%0001
\middlearray    dc.b    %1000,%0100,%0010,%0001

*** notetask - Entrypoint for NotePlayer task
notetask
        move.l  4,a6

        lea     taskport,a2                     ; Activate the taskport
        move.l  #tc,MP_SIGTASK(a2)
        move.w  #(PA_SIGNAL<<8)!(SIGB_SINGLE),MP_FLAGS(a2)

\loop
        move.l  a2,a0                           ; Grab waiting messages
        jsr     _LVOGetMsg(a6)
        tst.l   d0
        bz      \nomsgs
        move.l  d0,a3

        move.w  ioa_WriteMsg+LN_NAME(a3),d2     ; Channel number (d2)

        move.l  a3,a1                           ; IORequest is all ready for action
        jsr     _LVODoIO(a6)

        tst.b   IO_ERROR(a3)                    ; Remember the allocated channel
        bnz     \allocfailed
        move.b  IO_UNIT+3(a3),chanmasks-taskport(a2,d2.w)
\allocfailed

        move.l  #sitport,MN_REPLYPORT(a3)       ; Back to the menagerie it goes
        move.l  a3,a1
        jsr     _LVOReplyMsg(a6)

        clr.b   chanallocflags-taskport(a2,d2.w)

        bra     \loop

\nomsgs
        move.l  a2,a0
        jsr     _LVOWaitPort(a6)
        bra     \loop

        bss     __MERGED

k:

chanmasks       ds.b    4                       ; IO_UNIT for each channel
chanpos         ds.b    4                       ; Stereo position of each channel
chanallocflags  ds.b    4                       ; Set if an allocation request is pending
chanpervol      ds.w    4*2                     ; Current period (+0) and volume (+2) (0-$100)
chanoneshot     ds.l    4                       ; IOAudio of current one-shot sample
chanrepeat      ds.l    4                       ; IOAudio of current repeat sample

mastervoltab    ds.b    8                       ; Master volume (0-$40)

sitport         ds.b    MP_SIZE                 ; "Silent" port where idle IORequests sit around
taskport        ds.b    MP_SIZE                 ; Port where allocation requests go to

ioreqs          ds.b    ioa_SIZEOF*IOREQS       ; A bunch of IO requests for playing notes and such

tc              ds.b    TC_SIZE                 ; Task control block
stack           ds.b    STACKSIZE               ; Stack for task

taskadded       ds.b    1                       ; The allocation task is currently running

channels        ds.b    1                       ; Number of channels we're using

volinitflag     ds.b    1                       ; Nonzero if master volume's been initialized

allocpri        ds.b    1                       ; Audio channel allocation priority

        end
