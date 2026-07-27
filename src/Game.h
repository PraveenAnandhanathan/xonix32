
//===========================
// Game.h
// by Shawn A. VanNess
// created 08 Mar 1997
// for the Win32 platform
//===========================
// CGame
// This class contains all the major functionality of the game 
// that is not appropriate for CGameWnd, which is more generic.  
// In future releases, this class may be derived from CGameWnd 
// (as it is, they're somewhat redundant).
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

#ifndef __GAME_H__
#define __GAME_H__

//===========================
// Class declarations

//-----------------
class CGame
{
private:
   // From frame wnd
   CXonScreen* m_pXS; // all drawing goes to dibsection-derived class
   CRect m_rcScr; // game-screen rect (quantized client area)

   // Game objs
   long m_iGuyStartX;
   CXonGuy m_Guy;
   UINT m_nBDots, m_nWDots, m_nLines;
   CXonDotB* m_pBDot;
   CXonDotW* m_pWDot;
   CXonLine* m_pLine;
   
   // Misc game vars
   UINT m_nLives,m_nLevel,m_nScore; // the obvious game vars
   long m_iLevelTimeLimit, m_iTimeRemaining; // time vars
   BOOL m_bBonusElligible; // flags

public:
   CGame(CRect* prcCli);
   virtual ~CGame();

   CDibSection* CreateDS(CDC* pdc, RGBQUAD* pColors, UINT nColors);
   void HandleKbd(UINT nChar);
   void PauseGame(BOOL bPause);

   long GetFillFrac() { return m_pXS->GetFillFraction(); }
   long GetLevel() { return m_nLevel; }
   long GetLives() { return m_nLives; }
   long GetScore() { return m_nScore; }
   long GetBonus() { return ((m_bBonusElligible)?BONUS_CALC(m_iTimeRemaining):0); }
   long GetTimer() { return (m_iTimeRemaining/NOM_FPS); }

   void InitSplash();
   void Splash();

   void InitDemo();
   void Demo();

   void InitGame(UINT nInitLevel);
   void InitLevel(BOOL bClear);
   UINT RunGame();
   void DrawObjects();
   void EraseObjects();
   void GameOver();
};


#endif // include-guard
