/* DW_Convert.c */

/* This short C program takes a Dave Whittaker module as an input file, and
writes it out as a GMOD module.  This is not incredibly useful, since
MultiPlayer and many other player programs can play Dave Whittaker modules
without any help.  However, it illustrates how you can add GMOD support to
music composer programs and such.  */

#include <stdio.h>
#include <stdlib.h>

/* These labels are defined in DW_GMOD.asm */
extern char HeaderBegin[], HeaderEnd[];

FILE *infh, *outfh;

char copybuf[8192];

int gotsize;

void die(char *mes)
  {
    puts(mes);
    exit(10);
  }

void main(int argc,char **argv)
  {
    if(argc != 3)
      die("Usage: DW_Convert <infile> <outfile>\n");

    if(!(infh = fopen(argv[1],"r")))
      die("Can't open input file");

    if(!(outfh = fopen(argv[2],"w")))
      die("Can't open output file");

    /* First write the DW_GMOD header */
    if(fwrite(HeaderBegin,1,(long)(HeaderEnd-HeaderBegin),outfh) <= 0)
      die("Error writing GMOD header");

    /* Then just copy everything else over */
    while((gotsize = fread(copybuf,1,8192,infh)) > 0)
      if(fwrite(copybuf,1,gotsize,outfh) <= 0)
        die("Error copying to output file");
    if(gotsize < 0)
      die("Error reading from input file");

    /* Let the startup code close our files (I'm lazy I know) */
  }

