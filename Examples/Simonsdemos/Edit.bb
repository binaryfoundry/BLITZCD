;
; Dungeon Editor by Simon Armstrong
;

width=128  ;map/dungeon constants same as dungeon.bb
height=64
size=width*height

MaxLen pa$=160 ;fix length of strings for use with Blitz2
MaxLen fi$=64  ;filerequester

Gosub initmap     ;dimension array and draw border
Gosub initchars   ;string array for our objects
Gosub initui      ;open user interface
Gosub sizewindow  ;refresh map window

Repeat            ;main loop based on Intuition events
  ev.l=WaitEvent
  Select ev
    Case 2
      Gosub sizewindow
    Case 8
      If EventWindow=0 AND MButtons=1 Then Gosub draw
    Case $40
      If GadgetHit<2
        posy=Int(VPropPot(0,0)*height) ;scroll map
        posx=Int(HPropPot(0,1)*width)
        Gosub drawdungeon
      Else
        brush=GadgetHit-2  ;select brush from tool window
      EndIf
    Case 256
      If MenuHit=0 AND ItemHit=0 Then Gosub loadmap
      If MenuHit=0 AND ItemHit=1 Then Gosub savemap
      If MenuHit=0 AND ItemHit=2 Then End
    Case $40000
      Use Window 0:Redraw 0,0:Redraw 0,1
  End Select
Forever

.initmap
  Dim map.b(width-1,height-1)
  For y=0 To height-1:map(0,y)=1:map(width-1,y)=1:Next
  For x=0 To width-1:map(x,0)=1:map(x,height-1)=1:Next
  Return

.initchars
  Dim c$(4)
  c$(0)=Chr$(32):c$(1)="*":c$(2)="O":c$(3)="M":c$(4)="B"
  Return

.draw
  Repeat
    Use Window 0
    cx=QLimit(Int((WMouseX-6)/8),0,ww-1)
    cy=QLimit(Int((WMouseY-10)/8),0,wh-1)
    map(posx+cx,posy+cy)=brush
    WindowOutput 0:WLocate cx*8,cy*8:Print c$(brush)
  Until Event
  Return

.sizewindow
  Use Window 0
  ww=Int(WindowWidth/8)-3    ;num blocks we can display
  wh=Int(WindowHeight/8)-3   ;with current window size
  Gosub drawdungeon
  SetVProp 0,0,posy/height,wh/height ;position sliders
  SetHProp 0,1,posx/width,ww/width
  Redraw 0,0:Redraw 0,1
  Return

.drawdungeon
  WindowOutput 0
  posx=QLimit(posx,0,width-ww)   ;get topleft coordinate with
  posy=QLimit(posy,0,height-wh)  ;limit of upper/lower value
  InnerCls
  For y=0 To wh-1
    For x=0 To ww-1    ;character based on value in map
      ch=map(posx+x,posy+y)
      If ch Then WLocate x*8,y*8:Print c$(ch)
    Next
  Next
  Return

.initui
  MenuTitle 0,0,"PROJECT"             ;set up menus for our editor
  MenuItem 0,0,0,0,"LOAD      ","L"
  MenuItem 0,0,0,1,"SAVE      ","S"
  MenuItem 0,0,0,2,"QUIT      ","Q"
  PropGadget 0,-16,10,2+16+128,0,16,-20 ;gadgets for sliders
  PropGadget 0,4,-9,4+8+64,1,-22,10
  For i=0 To 4                          ;gadgets for brush select
    TextGadget 1,i*24+12,12,512,2+i,c$(i)
  Next
  brush=1:Toggle 1,3,On
  Screen 0,10,"Dungeon Editor"          ;and a screen and windows
  Window 0,0,12,640,240,$1001,"DUNGEON",1,2,0:SetMenu 0
  Window 1,400,0,140,28,$1002,"BLOCKS",1,2,1:SetMenu 0
  Use Window 0:Redraw 0,0:Redraw 0,1
  Return

.loadmap
  a$=FileRequest$("LOAD DUNGEON",pa$,fi$)       ;do a file request
  If ReadFile(0,a$)                             ;if file there
    If Lof(0)=size Then ReadMem 0,&map(0,0),size;read it into map
    CloseFile 0                                 ;array (raw!)
    Gosub drawdungeon                           ;refresh screen
  EndIf
  Return

.savemap
  a$=FileRequest$("SAVE DUNGEON",pa$,fi$)
  If WriteFile(0,a$)
    WriteMem 0,&map(0,0),size:CloseFile 0  ;write array to file raw
  EndIf
  Return

