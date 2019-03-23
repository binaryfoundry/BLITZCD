[c][b]The HyperHelp 2.0 Command List[b][c][T The Commands, Page 1][h]
[i]What follows here are all the HyperHelp Commands of version 1.5b with a
little explanation if that seemed useful to me.[i][p]
First of all, all commands in HyperHelp 2 documents are surrounded by square
brackets ( [] and ] ). The commands can be in any case (upper or lower that is)
you like. One more important thing is to finish you document with a NewLine
(enter).[EOP][b]The Commands[b]
[h][]B] - Bold[T The Commands, Page 2][e]
This command simply [b]boldens[b] the text. Place this at the beginning and end
of the piece of text you would like to see in boldface. You can even use this in
links, if you wish.
[e]Example: []B]This is Bold![]B]
[p][]I] - Italics[e]
This is another text-style command, and it [i]italicizes[i] you text. Again,
place the text to be italicized between two of these commands.
[e]Example: []I]These are Italics.[]I]
[p][]U] - Underline[e]
Another style command, this one. It [u]underlines[u] the text you put between
two of these commands.
[e]Example: []U]This text is Underlined![]U]
[p][]H] - Horizontal Line[e]
Whenever this is encountered, a horizontal black line will be drawn across the
screen. It always starts at the beginning of a line, so if there is any text in
front of it, a NewLine will be added first.
[e]Example: This line[]H]breaks the text in two.
[p][p][]P] - Paragraph[T The Commands, Page 3][e]
This command causes a new paragraph to be begun, with an empty line between it
and the previous one. If followed by a NewLine in the document, the paragraph
will be indented.
[e]Example: []P]This paragraph is [b]NOT[b] indented.
[p][]E] - NewLine[e]
This here causes the line to end, and a new line to begin. It only has effect if
the imaginary cursor was not at the beginning of a line yet. It is best to put
this directly before the new line of text, or it will become indented.
[e]Example: The next word is on a new[]E]line.
[p][]T] - Title[e]
This piece of work changes the window title. The title is always displayed in
UPPER-case. You can change the title of the window on each page of the document,
so as to add pages, or something.
[p][]L filename|type] - HyperLink[e]
This is one of the most powerful commands of HyperHelp 2. It allows the
creator of the document to link other objects to his document. The other objects
are Documents (DOC), images (IMG), sounds (SND), the Index Document (IDX),
ProTracker Modules (MOD), SID Songs (SID), Player6.1 Modules (P61) and Executables (PRW or PRG). As you can see, you must
type in the filename of the object, followed by a pipe ( | ), and after that the
type. For an Index Object, the filename doesn't matter. The types were stated above
([L hhhelp.hh|doc]DOC[l], [L hhimage.iff|img]IMG[l],
[L hhblue.snd|snd]SND[l],
[L hhwhocares.hh|IDX]IDX[l],
[L hhmusic.mus|MOD]MOD[l],
[L hhsid.mus#1|SID]SID[l],
[L hhplayer61.mus|P61]P61[l],
[L hhplayer61.prg|PRW]PRW[l] and
[L hhplayer61.prg|PRG]PRG[l]). 
To end a link, you must
add a []L]. All the text between the two commands will be blue.[e]
An [T The Commands, Page 4]image must be of the IFF-ILBM type (like a DPaint pic), and a sound must be
8SVX (ProTracker makes those).[e] Pictures will pop up in their own windows, and
can have as many colours as you like. 
You can use as many [L hhimage2.iff|img]colours[l] as you like.
Images can be any size, but will only be shown up to
the size of your workbench. Larger images will only be partially visible.
An image can be removed by clicking on the close-gadget. If this does not work,
click in the image, and it should close.[e]
Sound are loaded from disk and then played. If music is playing, the sound will
be heard, but may be malformed.[e]
Executables can be called in two ways. One is with PRG, which just executes
the program. The other way (PRW) first opens an output window for the program to
dump comments in.[e]
Player 61 Modules must have uncrunched samples, directly behind the module.
People who wish to include these will probably know what this means.[e]
SIDs have a different filename structure, namely FILENAME#songnumber,
where the # is the separator. So you can [l hhsid.mus#2|sid]listen[l]
to more than one song per SID. 
[e]Example: []L title.iff|IMG]Title[[L]
[EOP][]S] - Force Spaces[e]
This command lets you put more than one space between two words. Just put them
around the text you wish to have spaced out. Be careful though, a NewLine is
also counted as a space, so for that use []E] instead.
[e]Example: []S][s]  many     spaces   here[s][]S]
[p][]C] - Center Text[e]
With this command you can cause text to be centered. Put the text between two
of these commands. 
[p][]F fontname|size][e]
Use this to load and use a new font. Fontname must include the DIR where the
font can be found (EG. FONTS:topaz.font), and size is the Y-size of the font.
You can use proportional fonts. For each new page the font is reset to Topaz 8.
[e]Example: []F FONTS:topaz.font|11]Use Topaz 11
[p]EOP - End Of Page marker.[t the commands, page 5]
You can cause an artificial pagebreak by including EOP (between square
brackets)  in your document.
[h][l hhhelp.hh|doc]Back to the Index[l]
