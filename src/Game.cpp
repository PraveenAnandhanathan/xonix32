
//===========================
// Game.cpp
// by Shawn A. VanNess
// created 08 Mar 1997
// for the Win32 platform
//===========================
// See header file for description
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

#include "StdAfx.h"
#include "GameApp.h"

#ifdef _DEBUG
#define new DEBUG_NEW
#undef THIS_FILE
static char THIS_FILE[] = __FILE__; 
#endif

//===========================
// CGame

//-----------------
CGame::CGame(CRect* prc)
{
// Adjust the client rectangle...
// size = n*OBJ_MOVE + OBJ_SIZE, where n is even
long n;
n = ((prc->right-prc->left)-OBJ_SIZE)/OBJ_MOVE;
if (n&0x01) n--; // n must be even to center the start pos
prc->right = prc->left + ((n*OBJ_MOVE)+OBJ_SIZE);
m_iGuyStartX = (n/2)*OBJ_MOVE+OBJ_OFFSET;

n = ((prc->bottom-prc->top)-OBJ_SIZE)/OBJ_MOVE;
prc->bottom = prc->top + ((n*OBJ_MOVE)+OBJ_SIZE);

m_rcScr = *prc;

// Alloc obj arrays
m_pBDot = new CXonDotB[MAXBDOTS]; 
m_pWDot = new CXonDotW[MAXWDOTS]; 
m_pLine = new CXonLine[MAXLINES]; 

// Misc init
m_pXS = NULL; 
m_nBDots = m_nWDots = m_nLines = 0; 
m_nLives = m_nLevel = m_nScore = 0; 
m_iLevelTimeLimit = m_iTimeRemaining = 0; 
m_bBonusElligible = FALSE; 
}

//-----------------
CGame::~CGame()
{
delete m_pXS;
delete [] m_pLine; 
delete [] m_pWDot; 
delete [] m_pBDot; 
}

//-----------------
CDibSection* CGame::CreateDS(CDC* pdc, RGBQUAD* pColors, UINT nColors)
{

CSize size;
size = m_rcScr.Size();

m_pXS = new CXonScreen(pdc,m_rcScr.Size(),pColors,nColors);
m_pXS->SetAll(XBC_BLACK);
return (CDibSection*)(m_pXS);
}

//-----------------
void CGame::HandleKbd(UINT nChar)
{
switch (nChar)
   {
   // Movement keys
   case VK_LEFT:  m_Guy.dx = -OBJ_MOVE; m_Guy.dy = 0; break; 
   case VK_UP:    m_Guy.dx = 0; m_Guy.dy = -OBJ_MOVE; break; 
   case VK_RIGHT: m_Guy.dx =  OBJ_MOVE; m_Guy.dy = 0; break; 
   case VK_DOWN:  m_Guy.dx = 0; m_Guy.dy =  OBJ_MOVE; break; 
   case VK_SPACE: /* future: turbo */ break;
   } // end of switch-block
}

//-----------------
void CGame::PauseGame(BOOL bPause)
{
// do nothing
}

//-----------------
void CGame::InitSplash()
{
// Draw blue border
CRect rc; 
rc = m_rcScr; 
m_pXS->DrawRect(rc,XBC_BLUEGRN);
rc.DeflateRect(BRD_SIZE,BRD_SIZE); 
m_pXS->DrawRect(rc,XBC_BLACK); 

// Draw title bitmap
m_pXS->DrawBmpFromRes(m_rcScr.right/2,m_rcScr.bottom/2,IDB_SPLASH,TRUE,&rc);

// Create yellowlines for "X"
m_pLine[0].Randomize(m_rcScr,2,2); 
m_pLine[1].Randomize(m_rcScr,2,2); 

long x=rc.left - 10;
long y=((rc.top+rc.bottom)/2) - 5;
m_pLine[0].dot0.x = x-20; m_pLine[0].dot0.y = y-40; 
m_pLine[0].dot1.x = x+20; m_pLine[0].dot1.y = y+40; 
m_pLine[0].Draw(m_pXS); 
m_pLine[1].dot0.x = x-20; m_pLine[1].dot0.y = y+40; 
m_pLine[1].dot1.x = x+20; m_pLine[1].dot1.y = y-40; 
m_pLine[1].Draw(m_pXS); 
}

//-----------------
void CGame::Splash()
{
// nothing, for now
}

//-----------------
void CGame::InitDemo()
{
// nothing, for now
}

//-----------------
void CGame::Demo()
{
// Animate yellowlines
m_pLine[1].Erase(m_pXS); m_pLine[0].Erase(m_pXS); 
m_pLine[0].Move(m_pXS,m_rcScr); m_pLine[1].Move(m_pXS,m_rcScr); 
m_pLine[0].Draw(m_pXS); m_pLine[1].Draw(m_pXS); 
}

//-----------------
void CGame::InitGame(UINT nInitLevel)
{
// Reset all game-level vars
m_nLevel = nInitLevel; 
m_nScore = 0; 
m_nLives = 3; 
if (nInitLevel >= 10) m_nLives = 5; // a little help
}

//-----------------
void CGame::InitLevel(BOOL bClear)
{
int i; 
CRect rc; 

// Erase old objects if restarting after a death
if (!bClear)
   {
   EraseObjects();
   m_pXS->SetAll(XBC_BLUEGRN,MASK_AND);
   }

// Initialize the board, if necessary
if (bClear)
   {
   rc = m_rcScr; 
   m_pXS->DrawRect(rc,XBC_BLUEGRN);
   rc.DeflateRect(BRD_SIZE,BRD_SIZE); 
   m_pXS->DrawRect(rc,XBC_BLACK); 
   m_pXS->CountFilledPix(m_rcScr);
   m_pXS->SetFudgeFactor(m_pXS->GetFillFraction());
   }

// Grant/revoke bonus elligibility
m_bBonusElligible = bClear; 

// Calculate time limit based on level
m_iLevelTimeLimit = NOM_FPS*min(60*5,60*m_nLevel); 
m_iTimeRemaining = m_iLevelTimeLimit;

// Set starting position at top center of screen
m_Guy.x = m_iGuyStartX;
m_Guy.y = OBJ_OFFSET;
m_Guy.dx = m_Guy.dy = 0; 
m_Guy.Reset();

// Always randomize the bdots
m_nBDots = LEVEL2BDOTS(m_nLevel); 
rc.SetRect(20,m_rcScr.bottom-10,m_rcScr.right-20,m_rcScr.bottom-8); 
for(i=0; i < (int)m_nBDots; i++)
   m_pBDot[i].Randomize(rc,2,OBJ_MOVE-1); 

// Don't randomize wdots and ylines after a death
if (bClear)
   {
   m_nWDots = LEVEL2WDOTS(m_nLevel); 
   rc.SetRect(50,50,m_rcScr.right-50,m_rcScr.bottom-50); 
   for(i=0; i < (int)m_nWDots; i++)
      m_pWDot[i].Randomize(rc,1,OBJ_MOVE-1); 

   m_nLines = LEVEL2LINES(m_nLevel); 
   rc.SetRect(50,50,m_rcScr.right-50,m_rcScr.bottom-50); 
   for(i=0; i < (int)m_nLines; i++)
      m_pLine[i].Randomize(rc,1,OBJ_MOVE-2); 
   }

// Draw stuff
DrawObjects(); 
}

//-----------------
UINT CGame::RunGame()
{
int i;
BOOL bDead = FALSE;

// Erase
EraseObjects();

// Move guy
m_Guy.Move(m_pXS,m_rcScr); 

// Starting to draw?
if (!m_Guy.WasDrawing() && m_Guy.IsDrawing())
   {
   // Paint a little extra redness to ensure a good connection
   CRect rc(m_Guy.x-2,m_Guy.y-2,m_Guy.x+3,m_Guy.y+3); 
   rc.OffsetRect(-(m_Guy.dx/2),-(m_Guy.dy/2));
   m_pXS->DrawRect(rc,XBC_RED,MASK_OR); 
   }

// Finished drawing?
if (m_Guy.WasDrawing() && !m_Guy.IsDrawing())
   {
   // Paint a little extra redness to ensure a good connection
   CRect rc(m_Guy.x-2,m_Guy.y-2,m_Guy.x+3,m_Guy.y+3); 
   rc.OffsetRect(-(m_Guy.dx/2),-(m_Guy.dy/2));
   m_pXS->DrawRect(rc,XBC_RED,MASK_OR); 

   // Change water into wine
   m_pXS->WipeRedToBluegrn(m_rcScr);
   
   // Mark wdot- and yline-territory
   for(i=0; i < (int)m_nWDots; i++) 
      m_pXS->DrawFloodFill(m_pWDot[i].x,m_pWDot[i].y,XBC_MARK1,XBC_BLUEGRN,MASK_OR); 
   for(i=0; i < (int)m_nLines; i++) 
      {
      m_pXS->DrawFloodFill(m_pLine[i].dot0.x,m_pLine[i].dot0.y,XBC_MARK1,XBC_BLUEGRN,MASK_OR); 
      m_pXS->DrawFloodFill(m_pLine[i].dot1.x,m_pLine[i].dot1.y,XBC_MARK1,XBC_BLUEGRN,MASK_OR); 
      }

   // Any unmarked black becomes blue!
   m_pXS->FillUnmarkedArea(m_rcScr);

   // Stop the guy, and notify him of the state-change
   m_Guy.dx = m_Guy.dy = 0; 
   m_Guy.Reset();

   // Calculate our fill fraction
   m_pXS->CountFilledPix(m_rcScr);

   // Update status bar
   AfxGetMainWnd()->PostMessage(WM_TIMER,IDT_GAMECLK);
   } // endif (connection logic)

// Move other objects (includes bouncing and clipping logic)
for(i=0; i < (int)m_nBDots; i++) m_pBDot[i].Move(m_pXS,m_rcScr); 
for(i=0; i < (int)m_nWDots; i++) m_pWDot[i].Move(m_pXS,m_rcScr); 
for(i=0; i < (int)m_nLines; i++) m_pLine[i].Move(m_pXS,m_rcScr); 

// Collision detection: wdot/redline
for(i=0; i < (int)m_nWDots; i++) bDead |= m_pWDot[i].HitTest(m_pXS); 

// Proximity collision detection: guy/bdot or guy/wdot
if (m_Guy.IsDrawing())
   for(i=0; i < (int)m_nWDots; i++) bDead |= m_Guy.IsNearDot(&m_pWDot[i]); 
else
   for(i=0; i < (int)m_nBDots; i++) bDead |= m_Guy.IsNearDot(&m_pBDot[i]); 

// Update fill percentage
m_pXS->CountFilledPix(m_rcScr,20);

// Draw
DrawObjects(); 

// Check if we've won
if (m_pXS->GetFillFraction() >= 750)
   {
   m_nScore += m_nLevel*100;
   m_nScore += m_nLevel*(m_pXS->GetFillFraction()-750); //for overfilling
   m_nScore += GetBonus(); //for speed
   m_nLevel++; m_nLives++; 
   return RET_NEWLEVEL; 
   }
   
// Check timer
if (--m_iTimeRemaining <= 0)
   {
   m_nLives--;
   return RET_TIMEOUT; 
   }

// Check death flag
if (bDead)
   {
   m_nLives--;
   return RET_DEATH; 
   }

// Continue running
return RET_OKAY; 
}

//-----------------
void CGame::DrawObjects()
{
int i; 

// Redness
CRect rc(m_Guy.x-2,m_Guy.y-2,m_Guy.x+3,m_Guy.y+3); 
if (m_Guy.WasDrawing() || m_Guy.IsDrawing())
   m_pXS->DrawRect(rc,XBC_RED,MASK_OR); 

// Draw/erase must occur in opposite order!
for(i=0; i < (int)m_nLines; i++) m_pLine[i].Draw(m_pXS); 
for(i=0; i < (int)m_nWDots; i++) m_pWDot[i].Draw(m_pXS); 
for(i=0; i < (int)m_nBDots; i++) m_pBDot[i].Draw(m_pXS); 
m_Guy.Draw(m_pXS); 
}

//-----------------
void CGame::EraseObjects()
{
int i; 

// Draw/erase must occur in opposite order!
m_Guy.Erase(m_pXS); 
for(i=(int)m_nBDots-1; i >= 0; i--) m_pBDot[i].Erase(m_pXS); 
for(i=(int)m_nWDots-1; i >= 0; i--) m_pWDot[i].Erase(m_pXS); 
for(i=(int)m_nLines-1; i >= 0; i--) m_pLine[i].Erase(m_pXS); 
}

//-----------------
void CGame::GameOver()
{
if (m_pXS->GetFillFraction() >= 200)
   m_nScore += (m_nLevel*m_pXS->GetFillFraction())/10; 
}
