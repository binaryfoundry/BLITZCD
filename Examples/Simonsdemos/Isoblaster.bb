;
; IsoBlaster V0.1 by Simon Armstrong
;
; You have to run Isorender first to create the shapes

;
; set up all the main types and arrays
;

NEWTYPE .object  ;same is IsoRender.bb but with extra fields
  depth.q:id     ;depth and shape id 0=me 1=mozzy
  x:y:z          ;3D coordinates of shape
  vx:vy          ;velocity in both x and y
  rot:rot2:rotv  ;rotation variables
  sx:sy          ;screen position after an iso-projection
End NEWTYPE

Dim List bob.object(50)

DEFTYPE .object *me

Dim qsin(255),qcos(255)  ;set up array of sin/cos values so
For r=0 To 255           ;we don't have to call sys ones in game
  qsin(r)=Sin(Pi*r/128):qcos(r)=Cos(Pi*r/128)
Next

Dim map.w(20,20) ;bit smaller than the dungeon (at present)

;
; load all the graphics from disk
;

LoadShapes 0,"blocks.shapes"  ;tiles for the ground
LoadShapes 4,"balls.shapes"   ;balls for fx etc.
LoadPalette 0,"balls.iff"     ;palette for forground playfield
LoadPalette 0,"blocks.iff",8  ;palette for backrground
LoadShapes 16,"isoshapes"     ;shapes rendered by IsoRender.bb

BitMap 0,320+64,256+80,3  ;foreground A
BitMap 1,320+64,256+80,3  ;foreground B
BitMap 2,640,512,3        ;large scrolling background

Queue 0,32:Queue 1,32     ;two queues for double buffered blitting

Macro p 320+(`1-`2)ASL 4,128+(`1+`2-`3)ASL3:End Macro       ;back
Macro f 320+32-sx+(`1-`2)ASL4,128+32-sy+(`1+`2-`3)ASL3:End Macro  ;front

;
; create Blitz Mode display which for this game is
; dual playfield with double buffered foreground!
;

BLITZ
Slice 0,44,320,256,$fffa,6,8,32,320+64,640
Use Palette 0

Gosub setupmap  ;place a few blocks in the 2D array
Gosub drawmap   ;draw map onto large background playfield
Gosub initgame  ;initialise objects in the game

; then of course the standard main loop of any game...

While Joyb(0)=0
  VWait:ShowF db,32,40,sx:ShowB 2,sx,sy,32  ;position bitmaps in display
  db=1-db:Use BitMap db     ;swap buffer for double buffered drawing
  Gosub moveme              ;move me
  Gosub movethem            ;and them
  UnQueue db:Gosub drawbobs ;then draw everyone in new pos
;  MOVE#-1,$dff180   ;view frame time!
Wend

End

;
; and now what makes everything work properly!
;

.moveme:
  USEPATH *me                     ;use pointer to my object in list
  \rot=QWrap(\rot-Joyx(1)/2,0,16) ;rotate according to joystick
  If Joyb(1)=1                    ;if fire
    \vx+qsin(\rot ASL 4) ASR 6    ;then thrust in direction I
    \vy+qcos(\rot ASL 4) ASR 6    ;am pointing (my \rot)
  EndIf
  \vx-\vx ASR 5          ;this subtracts a fraction of my velocity
  \vy-\vy ASR 5          ;off my velocity (same as drag)
  \x=QLimit(\x+\vx,0,19) ;this adds celocity to my position
  \y=QLimit(\y+\vy,0,19)
  \sx=!p{\x,\y,\z}         ;calculate screen coordinates
  sx=QLimit(\sx-160,0,320) ;calulate scroll values for display so
  sy=QLimit(\sy-128,0,256) ;I am as close to center as possible
  \sx-sx+32:\sy-sy+32
  \depth=\x+\y             ;don't forget my depth variable
  If map(\x,\y)=1          ;oh and colour in block if I stand on one
    Use BitMap 2:x=Int(\x):y=Int(\y):Blit 2,!p{x,y,0}:Use BitMap db
  EndIf
  Return

.movethem:
  USEPATH bob()           ;simple routine that loops through
  ResetList bob()         ;all shapes makeing /id=2 shapes
  While NextItem(bob())   ;fly round in circles...
    If \id=2
      \rot=QWrap(\rot+\rotv,0,16)
      \rot2=QWrap(\rot2+1,0,16)
      \x+qsin(\rot ASL 4) ASR 4:\y+qcos(\rot ASL 4) ASR 4
      \sx=!f{\x,\y,\z}
      \depth=\x+\y
    EndIf
  Wend

.drawbobs:
  SortList bob(),0        ;sort from back to front
  ResetList bob()         ;loop through and draw, if they
  USEPATH bob()           ;are \id=2 draw propellor as well
  While NextItem(bob())
    If RectsHit(\sx,\sy,1,1,16,40,320+31,256+40)
      QBlit db,\id*16+\rot,\sx,\sy
      If \id=2 Then QBlit db,\id*16+16+\rot2,\sx,\sy
    EndIf
  Wend
  Return

.initgame:
  ClearList bob()
  AddItem bob():*me.object=bob()
  *me\id=1,.5,.5,0
  For i=0 To 2
    If AddItem(bob())
      bob()\id=2,Rnd(19),Rnd(19):\rotv=(Rnd(1)-.5)ASR 2
    EndIf
  Next
  Return

.setupmap:
  For x=0 To 19:For y=0 To 19:map(x,y)=1:Next:Next
  For x=9 To 11:For y=9 To 11:map(x,y)=-1:Next:Next
  Return

.drawmap:
  Use BitMap 2
  For x=0 To 19
    For y=0 To 19
      If map(x,y)>-1 Then Blit map(x,y),!p{x,y,0}
    Next
  Next
  Return

