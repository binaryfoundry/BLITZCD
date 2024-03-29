;
; accessing exec level devices
;

NEWTYPE.Node:*ln_Succ.Node:*ln_Pred:ln_Type.b:ln_Pri:*ln_Name.b:End NEWTYPE

NEWTYPE.List:*lh_Head.Node:*lh_Tail:*lh_TailPred:lh_Type.b:l_pad:End NEWTYPE

NEWTYPE.MsgPort
  mp_Node.Node
  mp_Flags.b
  mp_SigBit.b
  *mp_SigTask.w
  mp_MsgList.List
End NEWTYPE

NEWTYPE.Message
  mn_Node.Node
  *mn_ReplyPort.MsgPort
  mn_Length.w
End NEWTYPE

NEWTYPE.IOStdReq
  io_Message.Message
  *io_Device.b           ;Device
  *io_Unit.b             ;Unit
  io_Command.w
  io_Flags.b
  io_Error.b
  io_Actual.l
  io_Length.l
  *io_Data.b
  io_Offset.l

;add particulars to device here
;  rate.w:pitch:mode:sex:chmask.l:nmmask.w:vol:sampfreq
;  mouths.b:chanmask.b:numchan.b:pad.b

End NEWTYPE

;
;initialise messageport and iorequest for talking to device
;

DEFTYPE .IOStdReq cdio
DEFTYPE .MsgPort myport

myport\mp_Node\ln_Type=4
myport\mp_MsgList\lh_Head=&myport\mp_MsgList\lh_Tail
myport\mp_MsgList\lh_TailPred=&myport\mp_MsgList\lh_Head

cdio\io_Message\mn_Node\ln_Type=5
cdio\io_Message\mn_ReplyPort=&myport
cdio\io_Message\mn_Length=SizeOf.IOStdReq

;
; attempt to open device
;

If OpenDevice_("cdtv.device",0,cdio,0)<>0 Then Print "cant open cdtv":MouseWait:End

signal.l=AllocSignal_(-1):If signal<0 Then End
myport\mp_SigBit=signal
myport\mp_SigTask=FindTask_(0)

;
; cdtv package specific stuff
;


NEWTYPE .subq
  status.b:addrctrl:track:index
  diskposition.l:trackposition.l
  validupc.b:pad1:pad2:pad3
End NEWTYPE

DEFTYPE .subq mysubq

;
; test command
;

  #_INVALID=0:#_RESET=1:#_READ=2:#_WRITE=3:#_UPDATE=4
  #_CLEAR=5:#_STOP=6:#_START=7:#_FLUSH=8:#_NONSTD= 9

  #SUBQMSF=51
  #PLAYTRACK=43

cdio\io_Command=#PLAYTRACK                    ;SUBQMSF
                                              ;cdio\io_Data=0     ;mysubq
cdio\io_Offset=1                ; start track
cdio\io_Length=2                ; end track

DoIO_ cdio                ; err.l=DoIO_(cdio)

;NPrint mysubq\status
;NPrint mysubq\status
;NPrint mysubq\status
;NPrint mysubq\status
;MouseWait

CloseDevice_ cdio
FreeSignal_ signal
MouseWait
End

