
//===========================
// Macros.h
// by Shawn A. VanNess
// created 08 Mar 1997
// for the Win32 platform
//===========================
// Miscellaneous macros and extern definitions
//===========================
// Copyright (C) 1997-1998  Shawn A. VanNess
// <xonix@mindspring.com>
// 
// For copyright information, see the file gnu_license.txt included
// with this source code distribution.
// 
// This program is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 2 of the License, or
// (at your option) any later version.
// 
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
//===========================

#ifndef __MACROS_H__
#define __MACROS_H__

// Game info!
#define GAME_TITLE "Xonix32"
#define RELEASE "Version 2.51 (31 Dec 1998)"
//#define BENCHMARK

// Game Modes
#define MODE_SPLASH        (0x00010000)
#define MODE_DEMO          (0x00020000)
#define MODE_PLAY          (0x00030000)
#define MODE_PLAY_NEWLEVEL (0x00030001)
#define MODE_PLAY_SUCCESS  (0x00030002)
#define MODE_PLAY_DEATH    (0x00030003)
#define MODE_PLAY_TIMEOUT  (0x00030004)
#define MODE_PLAY_GAMEOVER (0x00030005)

// Return codes
#define RET_ERROR      (0)
#define RET_OKAY       (1)
#define RET_NEWLEVEL   (2)
#define RET_DEATH      (3)
#define RET_TIMEOUT    (4)

// Timer IDs (arbitrary nonzero constants)
#define IDT_GAMECLK (101)

// Game params
#define WND_SIZEX (128*4) ///532
#define WND_SIZEY (128*3) ///400
#define MIN_FPS (10)
#define MAX_FPS (50)
#define NOM_FPS ((MIN_FPS+MAX_FPS)/2)
#define BONUS_CALC(time) (10*max(0,time/NOM_FPS))

#define MAXBDOTS (4)
#define MAXWDOTS (8)
#define MAXLINES (4)
#define LEVEL2BDOTS(lev) (min(MAXBDOTS,(1+(lev-1)/3)))
#define LEVEL2WDOTS(lev) (min(MAXWDOTS,(3+(lev+0)/3)))
#define LEVEL2LINES(lev) (min(MAXLINES,(0+(lev+1)/3)))

// Sizing params
#define OBJ_OFFSET (3)
#define OBJ_SIZE ((2*OBJ_OFFSET)+1)
#define OBJ_MOVE (4)
#define BRD_SIZE ((4*OBJ_MOVE)+OBJ_SIZE-1)

// Colors
#define RGB_BLACK   (RGB(  0,  0,  0))
#define RGB_RED     (RGB(255,  0,  0))
#define RGB_YTEXT   (RGB(255,255,  0))
#define RGB_WHITE   (RGB(255,255,255))

#define XBC_BLACK   ((BYTE)0x00) // 00000000
#define XBC_RED     ((BYTE)0x01) // 00000001
#define XBC_BLUEGRN ((BYTE)0x02) // 00000010
#define XBC_YELLOW  ((BYTE)0x04) // 00000100
#define XBC_WHITE   ((BYTE)0x08) // 00001000
#define XBC_YTEXT   ((BYTE)0x10) // 00010000

#define XBC_MARK1   ((BYTE)0x40) // 01000000

// Misc functions macros
#define BOUND(x,lo,hi) (x = (min(max(x,lo),hi)))
#define ABS(x) ((x < 0)?(-x):(x))
#define LI2DOUBLE(pli) (((double)(pli)->HighPart*(double)0xffffffff)+(double)(pli)->LowPart)


#endif // include-guard
