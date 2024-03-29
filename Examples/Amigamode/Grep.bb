;
;averages 14k per second on 68000
;         112k per second on 68030 (25Mhz) (cache & burst on)
;
;you need to create an executable and run this from the CLI

Function.l gline{start.l}
    UNLK a4
    MOVE.l  a2,-(a7)
    MOVE.l  d0,a0
    MOVE.l  d0,a1
lp1:CMP.b   #32,-(a0)
    BGE     lp1
    ADDQ.l  #1,a0
    MOVE.l  a0,d0       ;start pos..
lp2:CMP.b   #32,(a1)+
    BGE     lp2
    SUBQ.l  #1,a1
    MOVE.l  a1,d1       ;end pos...

    SUB.l   d0,d1       ;len..
    SUBQ    #1,d1

    LEA     str(pc),a2
lp:
    MOVE.b  (a0)+,(a2)+
    DBF     d1,lp
    MOVE.b  #0,(a2)+
    LEA     str(pc),a0
    MOVE.l  a0,d0
    MOVE.l  (a7)+,a2
    RTS

str:    Dcb.b 258,0

End Function


buf.l=30000     ;buffer size

If NumPars=1 AND Par$(1)="?"
    c$=Chr$(27)+"[33m"
    d$=Chr$(27)+"[>0m"+Chr$(27)+"[31;40m"
    NPrint c$,"GREP V1.2",d$
    NPrint "GREP type program by Paul Andrews. Written in Blitz 2."
    NPrint "GREP [-bxx] [-c] key file"
    NPrint "Where -b changes default buffer size, xx is in Kb."
    NPrint "e.g. -b100 allocates 100K. Default is 30K"
    NPrint "-c switches on case sensitivity."
    End
EndIf

If NumPars<2
    NPrint "Error: Not Enough Parameters"
    NPrint "? for help"
    End
EndIf

f$=""
k$=""
b$="30"
casesen.w=0     ;case insensitive

For p=1 To NumPars
    If Left$(Par$(p),1)="-"
        If Mid$(Par$(p),2,1)="b"
            b$=Right$(Par$(p),Len(Par$(p))-2)
        EndIf
        If Mid$(Par$(p),2,1)="c"
            casesen.w=1
        EndIf
    Else
        If k$=""
            k$=Par$(p)
        Else
            If f$<>""
                Pop For
                NPrint "Error: Too Many Parameters."
                NPrint "? for help"
                End
            EndIf
            f$=Par$(p)
        EndIf
    EndIf
Next

If Len(k$)>32
    NPrint "Error: Key too long."
    NPrint "? for help"
    End
EndIf

buf.l=Val(b$)*1024

Dim CV.l(256)
pat$=k$
m.l=0
Dim bit.l(32)

Dim match$(200)
cmatch.l=0

m=Len(pat$)
For j=0 To 32-1
    bit(j)=(1 LSL (32-j-1))
Next
For i=0 To 256-1
    CV(i)=0
    For j=0 To m-1
        If Mid$(pat$,j+1,1)=Chr$(i)
            CV(i)=CV(i) OR bit(j)
        EndIf
        If casesen.w=0      ;ignore case..
            If UCase$(Mid$(pat$,j+1,1))=Chr$(i)
                CV(i)=CV(i) OR bit(j)
            EndIf
            If LCase$(Mid$(pat$,j+1,1))=Chr$(i)
                CV(i)=CV(i) OR bit(j)
            EndIf
        Else    ;case sensitive..
            If Mid$(pat$,j+1,1)=Chr$(i)
                CV(i)=CV(i) OR bit(j)
            EndIf
        EndIf


    Next
Next

If casesen=0
    NPrint "Ignoring Case."
Else
    NPrint "Case Sensitive."
EndIf

InitBank 0,buf,0
src.l=BankLoc(0)

h.l=Open_(f$,1005)  ;old file..

If h.l=0
    NPrint "Error: Couldn't open ",f$,"."
    End
EndIf

totlen.l=0
NPrint "Searching file ",f$,"..."
NPrint ""
SetInt 5
    tim.l+1
End SetInt

tim.l=0

Loop:
bread.l=Read_(h,src,buf)
totlen+bread
If bread=0 Then Goto finished
text.l=src
textend.l=src+bread

endpos.l=bit(m-1)
R.l=bit(0)
bit0.l=R
a$=""

While (text<textend)
    cc.l=CV(Peek.b(text)):text+1
    R=((R LSR 1) OR bit0 )AND cc
    If (R&endpos)
        If cmatch<200
            start.l=text
            as.l=gline{start}
            a$=Peek$(as)
            NPrint a$
            cmatch+1
        EndIf
    EndIf
Wend

Goto Loop

finished:

tt.f=tim:fr.f=50:If NTSC<>0 Then fr=60
thruput.l=Int((totlen/1024)/(tt/fr)+.5)
NPrint ""
NPrint "Finished. Scanned ",totlen," bytes in ",tt/fr," seconds. ",thruput,"K per second."
If cmatch>0
    NPrint "Found ",cmatch-1," Matches."
Else
    NPrint "No Matches Found."
EndIf


