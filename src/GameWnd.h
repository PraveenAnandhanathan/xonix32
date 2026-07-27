
//===========================
// GameWnd.h
// by Shawn A. VanNess
// created 08 Mar 1997
// for the Win32 platform
//===========================
// CGameWnd
// This class is derived from the MFC CFrameWnd class.  This is 
// where most of the generic game-framework resides.
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

#ifndef __GAMEWND_H__
#define __GAMEWND_H__

//-----------------
class CGameWnd : public CFrameWnd
{
private:
   CGame *m_pGame; // game object

   UINT m_nMode, m_nModeTime; // mode stuff
   BOOL m_bNewLevelClear; // flag for CGame::InitLevel()
   BOOL m_bPaused; // pause control flag
   UINT m_nInitLevel; // starting level
   BOOL m_bFlash; // for flashing

   LARGE_INTEGER m_liTemp; // temp quadword timer value
   double m_dFreq; // hires timer frequency
   double m_dGameTime,m_dPrevGameTime; // hires OnIdle() loop timing
   UINT m_nGameSpdDelay, m_nClockDelay; // timer intervals (milliseconds)

   CRect m_rcCli; // client-area rectangle
   CClientDC* m_pdcCli; // dc for client-area
   CPalette m_gPal; // log palette
   CDibSection* m_pDS; // the dibsection

   CFont m_gFontFSys; // fixedsys font for the PAUSED display
   CStatusBar m_sbar; // the status bar
   CScoreList m_lstHighScores; // high score table data

public:
   CGameWnd();
   ~CGameWnd();

   BOOL IsPaused();
   BOOL IsGameActive();
   UINT MainLoop();

private:
   void DoSplash();
   void DoDemo();
   void DoSuccess();
   void DoNewLevel();
   void DoDeath();
   void DoGameOver();
   void DoBitBlt(CDC* pdc=NULL);

public:
   // Overrides
   virtual BOOL PreCreateWindow(CREATESTRUCT& cs);

   // System event handlers for CGameWnd
   afx_msg int  OnCreate(LPCREATESTRUCT lpCreateStruct);
   afx_msg void OnDestroy();
   afx_msg void OnActivateApp(BOOL bActive, HTASK hTask);
   afx_msg BOOL OnEraseBkgnd(CDC *pDC);
   afx_msg void OnPaint();
   afx_msg void OnPaletteChanged(CWnd* pFocusWnd);
   afx_msg BOOL OnQueryNewPalette();
   afx_msg void OnTimer(UINT nIDEvent);

   // UI event handlers
   afx_msg void OnKeyDown(UINT nChar, UINT nRepCnt, UINT nFlags);

   // Menu event handlers
   afx_msg void OnGameNew();
   afx_msg void OnGamePause();
   afx_msg void OnGamePauseUpdate(CCmdUI *pCmdUI);
   afx_msg void OnGameEnd();
   afx_msg void OnGameEndUpdate(CCmdUI *pCmdUI);
   afx_msg void OnOptionsSpeed();
   afx_msg void OnOptionsSpeedUpdate(CCmdUI *pCmdUI);
   afx_msg void OnOptionsLevel();
   afx_msg void OnOptionsLevelUpdate(CCmdUI *pCmdUI);
   afx_msg void OnViewScores();
   afx_msg void OnViewScoresUpdate(CCmdUI *pCmdUI);
   afx_msg void OnHelpReadme();
   afx_msg void OnHelpLicense();
   afx_msg void OnHelpAbout();

   // Statusbar update handlers
   afx_msg void OnSbLevelUpdate(CCmdUI *pCmdUI);
   afx_msg void OnSbLivesUpdate(CCmdUI *pCmdUI);
   afx_msg void OnSbScoreUpdate(CCmdUI *pCmdUI);
   afx_msg void OnSbTimerUpdate(CCmdUI *pCmdUI);

   DECLARE_MESSAGE_MAP()
};


#endif // include-guard
