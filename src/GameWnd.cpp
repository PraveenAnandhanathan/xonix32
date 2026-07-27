
//===========================
// GameWnd.cpp
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

#include "palette.h" // 256-color static RGBQUAD array

static UINT g_nSbIndicators[] = 
{ 
   ID_SEPARATOR,
   ID_SBI_LEVEL, 
   ID_SBI_LIVES, 
   ID_SBI_SCORE, 
   ID_SBI_TIMER, 
};

//===========================
// CGameWnd constr/destr

//-----------------
CGameWnd::CGameWnd()
{
// Init vars
m_pGame = NULL;
m_pdcCli = NULL;
m_pDS = NULL;

m_bPaused = FALSE;
m_bNewLevelClear = TRUE;
m_nMode = MODE_SPLASH; m_nModeTime = 0;
m_nInitLevel = 1;
m_bFlash = FALSE;

m_nGameSpdDelay = 1000/NOM_FPS;
m_nClockDelay = 1000; // 1 sec
m_dFreq = m_dPrevGameTime = 0.0;

// Load high score table data from disk
m_lstHighScores.Load();

// Seed the random number generator
#ifdef RELEASE
srand(time(NULL));
#endif // release
}

//-----------------
CGameWnd::~CGameWnd()
{
// Save high score table data to disk
m_lstHighScores.Save();
}

//===========================
// Primary game functions

//-----------------
BOOL CGameWnd::IsPaused()
{
return m_bPaused;
}

//-----------------
BOOL CGameWnd::IsGameActive()
{
if ((m_nMode&0xFFFF0000) == MODE_PLAY) return TRUE;
return FALSE;
}

//-----------------
UINT CGameWnd::MainLoop()
{
if (!m_pGame) return 100;

QueryPerformanceCounter(&m_liTemp); 
double dGameTime = LI2DOUBLE(&m_liTemp);

if ((UINT)((1000.0*(dGameTime-m_dPrevGameTime))/m_dFreq) >= m_nGameSpdDelay)
   {
   switch (m_nMode)
      {
      case MODE_SPLASH:
      DoSplash();
      break;

      case MODE_DEMO:
      DoDemo();
      break;

      case MODE_PLAY: // run a single game timeslice
      switch (m_pGame->RunGame())
         {
         case RET_OKAY:
         // do nothing
         break;

         case RET_NEWLEVEL:
         m_nMode = MODE_PLAY_SUCCESS;
         m_bNewLevelClear = TRUE;
         break;

         case RET_DEATH:
         m_nMode = MODE_PLAY_DEATH;
         m_bNewLevelClear = FALSE;
         break;

         case RET_TIMEOUT:
         m_nMode = MODE_PLAY_TIMEOUT;
         m_bNewLevelClear = FALSE;
         break;
         }
      m_nModeTime = 0;
      break;

      case MODE_PLAY_SUCCESS:
      DoSuccess();
      break;

      case MODE_PLAY_NEWLEVEL:
      DoNewLevel();
      break;

      case MODE_PLAY_DEATH:
      DoDeath();
      break;

      case MODE_PLAY_TIMEOUT:
      DoDeath();
      break;

      case MODE_PLAY_GAMEOVER:
      DoGameOver();
      break;
      }

   // Blit from shadow bmp to client area
   DoBitBlt(m_pdcCli);

#ifdef BENCHMARK
   // Display performance data on statusbar
   if (0) //rendering time (ms)
      {
      m_dPrevGameTime = dGameTime;
      QueryPerformanceCounter(&m_liTemp); 
      dGameTime = LI2DOUBLE(&m_liTemp);
      sprintf(g_szBuffer,"%7.3f ms",((1000.0*(dGameTime-m_dPrevGameTime))/m_dFreq));
      }
   else //frames per second (fps)
      {
      sprintf(g_szBuffer,"FPS: %4.1f",(m_dFreq/(dGameTime-m_dPrevGameTime)));
      }
   m_sbar.SetPaneText(0,g_szBuffer,TRUE);
#endif // benchmark

   // Reset timer gate
   m_dPrevGameTime = dGameTime;

   // Let app know we actually did work
   return 0;
   }

// No work done this time thru
return (m_nGameSpdDelay-(UINT)((1000.0*(dGameTime-m_dPrevGameTime))/m_dFreq));
}

//===========================
// Private methods

//-----------------
void CGameWnd::DoSplash()
{
if (m_nModeTime == 0) // new mode change
   {
   m_nModeTime = 5000/50;
   SetMessageText(AFX_IDS_IDLEMESSAGE);
   m_pGame->InitSplash();
   return;
   }
if (m_nModeTime == 1) // switch modes
   m_nMode = MODE_DEMO;

m_pGame->Splash();
Sleep(50);
m_nModeTime--;
}

//-----------------
void CGameWnd::DoDemo()
{
if (m_nModeTime == 0) // new mode change
   {
   m_nModeTime = 15000/50;
   m_pGame->InitDemo();
   return;
   }
if (m_nModeTime == 1) // switch modes
   m_nMode = MODE_SPLASH;

m_pGame->Demo();
Sleep(50);
m_nModeTime--;
}

//-----------------
void CGameWnd::DoGameOver()
{
if (m_nModeTime == 0) // new mode change
   {
   m_nModeTime = 4000/50;
   m_pGame->GameOver();
   return;
   }
if (m_nModeTime == 1) // switch modes
   m_nMode = MODE_SPLASH;

if (m_nModeTime == 2000/50)
   {
   // Scan high score data
   UINT nScore = m_pGame->GetScore();
   UINT nSlot = 0;
   while(m_lstHighScores.GetScore(nSlot) >= nScore && nSlot < 10) nSlot++;
   if (nSlot < 10) // then we have a new high score!
      {
      CNewHighScoreDialog dlgNewHighScore(IDD_NEWHIGHSCORE);
      strcpy(dlgNewHighScore.m_szName,m_lstHighScores.GetName(nSlot));
      dlgNewHighScore.DoModal();
      m_lstHighScores.Insert(nSlot,dlgNewHighScore.m_szName,nScore);
      OnViewScores(); // display new high score data
      }
   }

Sleep(50);
m_nModeTime--;
}

//-----------------
void CGameWnd::DoSuccess()
{
if (m_nModeTime == 0) // new mode change
   {
   m_nModeTime = 3000/50;

   // Update statusbar
   PostMessage(WM_TIMER,IDT_GAMECLK);
   }
if (m_nModeTime == 1) // switch modes
   m_nMode = MODE_PLAY_NEWLEVEL;

Sleep(50);
m_nModeTime--;
}

//-----------------
void CGameWnd::DoNewLevel()
{
if (m_nModeTime == 0) // new mode change
   {
   m_nModeTime = 2000/50;

   // Init the new level
   m_pGame->InitLevel(m_bNewLevelClear);

   // Update statusbar
   PostMessage(WM_TIMER,IDT_GAMECLK);
   }
if (m_nModeTime == 1) // switch modes
   m_nMode = MODE_PLAY;

Sleep(50);
m_nModeTime--;
}

//-----------------
void CGameWnd::DoDeath()
{
if (m_nModeTime == 0) // new mode change
   m_nModeTime = 2000/50;
if (m_nModeTime == 1) // switch modes
   {
   if (m_pGame->GetLives() > 0) 
      m_nMode = MODE_PLAY_NEWLEVEL;
   else
      m_nMode = MODE_PLAY_GAMEOVER;
   }

Sleep(50);
m_nModeTime--;
}

//-----------------
void CGameWnd::DoBitBlt(CDC* pdc/*=NULL*/)
{
if (!m_pGame) return;
if (!pdc) pdc = m_pdcCli;

// Determine appropriate message
UINT idMsg = 0;
switch (m_nMode)
   {
   case MODE_PLAY_NEWLEVEL:
   idMsg = IDB_MSG_READY;
   break;

   case MODE_PLAY:
   if (m_bFlash && m_pGame->GetTimer() < 31) idMsg = IDB_MSG_LOW_TIME;
   break;

   case MODE_PLAY_SUCCESS:
   idMsg = IDB_MSG_LEVEL_COMPLETE;
   break;

   case MODE_PLAY_DEATH:
   idMsg = IDB_MSG_CRASH;
   break;

   case MODE_PLAY_TIMEOUT:
   idMsg = IDB_MSG_OUT_OF_TIME;
   break;

   case MODE_PLAY_GAMEOVER:
   idMsg = IDB_MSG_GAME_OVER;
   break;
   }

// Do we have anything to say?
CRect rc;
if (idMsg)
   m_pDS->DrawBmpFromRes((m_rcCli.right/2),(m_rcCli.bottom/2),idMsg,TRUE,&rc,MASK_OR);

// Paint
m_pDS->PaintTo(pdc);

// Cleanup
if (idMsg)
   m_pDS->DrawRect(rc,XBC_YTEXT,MASK_NAND);
}

//===========================
// Overrides

//-----------------
BOOL CGameWnd::PreCreateWindow(CREATESTRUCT& cs)
{
if (!CFrameWnd::PreCreateWindow(cs)) return FALSE;

// Create WND_SIZEX*WND_SIZEY window in center of screen...
// the exact window size and position will change later
cs.x = ::GetSystemMetrics(SM_CXSCREEN)/2-WND_SIZEX/2;
cs.y = ::GetSystemMetrics(SM_CYSCREEN)/2-WND_SIZEY/2;
cs.cx = WND_SIZEX;
cs.cy = WND_SIZEY;

return TRUE;
}

//===========================
// CGameWnd system handlers

//-----------------
int CGameWnd::OnCreate(LPCREATESTRUCT lpcs)
{
if (CFrameWnd::OnCreate(lpcs) == -1) return -1; //fail

// Init common controls
InitCommonControls();

// Create GDI objs
m_gFontFSys.CreateStockObject(SYSTEM_FIXED_FONT);

// Create the statusbar inside the client area
m_sbar.Create(this);
m_sbar.SetIndicators(g_nSbIndicators,sizeof(g_nSbIndicators)/sizeof(UINT));
m_sbar.SetPaneInfo(0,g_nSbIndicators[0],(SBPS_NOBORDERS|SBPS_STRETCH),0);
RecalcLayout();

// Setup the hires timer stuff
if (!QueryPerformanceFrequency(&m_liTemp))
   {
   MessageBox("High resolution\nTiming support is required\nEre this game you play","Haiku!",MB_OK|MB_ICONSTOP);
   return -1;
   }
m_dFreq = LI2DOUBLE(&m_liTemp);
QueryPerformanceCounter(&m_liTemp); 
m_dPrevGameTime = LI2DOUBLE(&m_liTemp);

// Create client-area dc
m_pdcCli = new CClientDC(this);
if (!m_pdcCli) return -1;
m_pdcCli->SetBkColor(RGB_BLACK);
m_pdcCli->SetBkMode(TRANSPARENT);

// Create and realize logical palette
CDibSection::ConstructPalette(m_gPal,g_rgbPalette,256);

CPalette* pPalOld = m_pdcCli->SelectPalette(&m_gPal,FALSE);
 m_pdcCli->RealizePalette();
m_pdcCli->SelectPalette(pPalOld, TRUE);

// Construct the game object; negotiate client size
CRect rcOld,rcNew,rcSb;
GetClientRect(&rcOld); // zero-based... really just a size
m_sbar.GetWindowRect(&rcSb);

rcNew = rcOld;
rcNew.bottom -= (rcSb.bottom-rcSb.top);
m_pGame = new CGame(&rcNew);
if (!m_pGame) return -1;
rcNew.bottom += (rcSb.bottom-rcSb.top);

CRect rc;
GetWindowRect(&rc);
rc.right += (rcNew.right-rcOld.right);
rc.bottom += (rcNew.bottom-rcOld.bottom);
MoveWindow(&rc);
GetClientRect(&m_rcCli);

// Create game-specific DibSection object 
m_pDS = m_pGame->CreateDS(m_pdcCli,g_rgbPalette,256);
if (!m_pDS) return -1;

// Start the timer
SetTimer(IDT_GAMECLK,m_nClockDelay,NULL);

return 0; //okay
}

//-----------------
void CGameWnd::OnDestroy()
{
CFrameWnd::OnDestroy();

// Stop the timer
KillTimer(IDT_GAMECLK);

// Free resources
delete m_pGame;
delete m_pdcCli;
}

//-----------------
void CGameWnd::OnActivateApp(BOOL bActive, HTASK hTask)
{
if (bActive)
   {
   // Restore title
   SetWindowText(GAME_TITLE);
   if (m_bPaused) SetWindowText(GAME_TITLE" - Paused");
   }
else
   {
   // Auto-pause!
   if (!m_bPaused) OnGamePause();
   }
}

//-----------------
BOOL CGameWnd::OnEraseBkgnd(CDC *pDC)
{
// Avoid unnecessary flicker
return TRUE;
}

//-----------------
void CGameWnd::OnPaint()
{
CPaintDC dc(this);
dc.SetBkColor(RGB_BLACK);
dc.SetBkMode(TRANSPARENT);

// The actual drawing
DoBitBlt(&dc);
}

//-----------------
void CGameWnd::OnPaletteChanged(CWnd* pFocusWnd) 
{
if (pFocusWnd == this || IsChild(pFocusWnd)) 
   return; // avoid infinite loop
else 
   OnQueryNewPalette(); // realize as background
}

//-----------------
BOOL CGameWnd::OnQueryNewPalette() 
{
// Realize our palette (as bkgrnd if called from OnPaletteChanged)
CPalette* pPalOld = m_pdcCli->SelectPalette(&m_gPal,(GetCurrentMessage()->message == WM_PALETTECHANGED));
 UINT nChanged = m_pdcCli->RealizePalette();
m_pdcCli->SelectPalette(pPalOld,TRUE);
Invalidate(TRUE);

// Did our palette mapping change?
if (nChanged == 0) return FALSE; // no
else return TRUE; // yes
}

//-----------------
void CGameWnd::OnTimer(UINT nIDEvent)
{
// This timer msg will reset the OnIdle loop and 
// thereby update all statusbar indicators indirectly, 
// except for pane zero.  D'oh!

// Toggle our flashing switch
m_bFlash = !m_bFlash;
}

//===========================
// CGameWnd UI handlers

//-----------------
void CGameWnd::OnKeyDown(UINT nChar, UINT nRepCnt, UINT nFlags)
{
if (!m_pGame) return;

// Ignore repeated keystrokes
if (nFlags&0x4000) return;

switch (nChar)
   {
   case VK_ESCAPE: // the "boss" key
   ShowWindow(SW_MINIMIZE);
   SetWindowText("Microsoft Excel");
   break;

   // Menu hotkey map
   case VK_F1: OnHelpAbout(); break;
   case VK_F2: OnGameNew(); break;
   case VK_F3: OnGamePause(); break;
   case VK_PAUSE: OnGamePause(); break;
   case VK_F4: OnGameEnd(); break;
   case VK_F5: OnOptionsSpeed(); break;
   case VK_F6: OnOptionsLevel(); break;
   case VK_F7: OnViewScores(); break;

   default: // call game-specific handler
   m_pGame->HandleKbd(nChar);
   break;
   } // end of switch block
}


//===========================
// CGameWnd menu handlers

//-----------------
void CGameWnd::OnGameNew()
{
if (IsGameActive())
   if (MessageBox("Start a new game?","Confirmation...",MB_OKCANCEL|MB_ICONQUESTION) != IDOK)
      return;

// Initialize new game
m_pGame->InitGame(m_nInitLevel);
if (m_bPaused) OnGamePause();
m_nMode = MODE_PLAY_NEWLEVEL; m_nModeTime = 0;
m_bNewLevelClear = TRUE;
}

//-----------------
void CGameWnd::OnGamePause()
{
if (m_bPaused) // then resume
   {
   m_bPaused = FALSE;

   // Restore title bar
   SetWindowText(GAME_TITLE);
   
   // Notify game logic
   m_pGame->PauseGame(FALSE);

   // Clear pause display
   Invalidate();
   }
else // (!m_bPaused) then pause
   {
   m_bPaused = TRUE;

   // Update title bar
   SetWindowText(GAME_TITLE" - Paused");

   // Notify game logic
   m_pGame->PauseGame(TRUE);

   // Set pause display
   Invalidate();
   }
}

//-----------------
void CGameWnd::OnGamePauseUpdate(CCmdUI *pCmdUI)
{
pCmdUI->SetText((m_bPaused)?"&Resume\tF3":"&Pause\tF3");
}

//-----------------
void CGameWnd::OnGameEnd()
{
if (!IsGameActive()) return;
if (MessageBox("Abort current game?","Confirmation...",MB_OKCANCEL|MB_ICONQUESTION) != IDOK)
   return;

m_nMode = MODE_PLAY_GAMEOVER; m_nModeTime = 0;
}

//-----------------
void CGameWnd::OnGameEndUpdate(CCmdUI *pCmdUI)
{
pCmdUI->Enable((IsGameActive())?TRUE:FALSE);
}

//-----------------
void CGameWnd::OnOptionsSpeed()
{
if (IsGameActive()) return;

CSpeedDialog dlgSpeed(IDD_OPT_SPEED);
dlgSpeed.m_nSpeed = min(MAX_FPS,max(MIN_FPS,(1000/m_nGameSpdDelay)));
if (dlgSpeed.DoModal() == IDOK)
   {
   m_nGameSpdDelay = 1000/dlgSpeed.m_nSpeed;
   m_nClockDelay = 1000*NOM_FPS/dlgSpeed.m_nSpeed;
   }
}

//-----------------
void CGameWnd::OnOptionsSpeedUpdate(CCmdUI *pCmdUI)
{
pCmdUI->Enable((IsGameActive())?FALSE:TRUE);
}

//-----------------
void CGameWnd::OnOptionsLevel()
{
if (IsGameActive()) return;

CLevelDialog dlgLevel(IDD_OPT_LEVEL);
dlgLevel.m_nLevel = m_nInitLevel;
if (dlgLevel.DoModal() == IDOK)
   m_nInitLevel = dlgLevel.m_nLevel;
}

//-----------------
void CGameWnd::OnOptionsLevelUpdate(CCmdUI *pCmdUI)
{
pCmdUI->Enable((IsGameActive())?FALSE:TRUE);
}

//-----------------
void CGameWnd::OnViewScores()
{
// if (IsGameActive()) return;

CHighScoreDialog dlgScores(IDD_HIGH_SCORES);
dlgScores.m_plstScoreData = &m_lstHighScores;
dlgScores.DoModal();
}

//-----------------
void CGameWnd::OnViewScoresUpdate(CCmdUI *pCmdUI)
{
// pCmdUI->Enable((IsGameActive())?FALSE:TRUE);
}

//-----------------
void CGameWnd::OnHelpReadme()
{
DWORD dw = (DWORD)ShellExecute(NULL, //GetSafeHwnd(), //m_hWnd, // handle to parent wnd
                               NULL, // operation (open by default)
                               "readme.html", // exe or doc file
                               NULL, // parameters
                               NULL, // default directory
                               SW_SHOW); // show cmd flags (for exe only)
if (dw <= 32)
   MessageBox("Could not open file","Error!",MB_OK|MB_ICONSTOP);
}

//-----------------
void CGameWnd::OnHelpLicense()
{
DWORD dw = (DWORD)ShellExecute(NULL, //GetSafeHwnd(), //m_hWnd, // handle to parent wnd
                               NULL, // operation (open by default)
                               "gnu_license.txt", // exe or doc file
                               NULL, // parameters
                               NULL, // default directory
                               SW_SHOW); // show cmd flags (for exe only)
if (dw <= 32)
   MessageBox("Could not open file","Error!",MB_OK|MB_ICONSTOP);
}

//-----------------
void CGameWnd::OnHelpAbout()
{
CAboutBoxDialog dlg(IDD_HELP_ABOUT);
dlg.DoModal();
}

//===========================
// CGameWnd Statusbar update

//-----------------
void CGameWnd::OnSbLevelUpdate(CCmdUI *pCmdUI)
{
// Also do the msg pane here, because we can't use 
// an update-handler for a pane with 0 for an ID.
#ifndef BENCHMARK
if (IsGameActive()) 
   {
   sprintf(g_szBuffer,"Percent Filled: %4.1f",(float)(m_pGame->GetFillFrac())/10.0);
   SetMessageText(g_szBuffer);
   }
#endif // !benchmark

sprintf(g_szBuffer,"Level: %d",m_pGame->GetLevel());
pCmdUI->SetText(g_szBuffer);
}

//-----------------
void CGameWnd::OnSbLivesUpdate(CCmdUI *pCmdUI)
{
sprintf(g_szBuffer,"Lives: %d",m_pGame->GetLives());
pCmdUI->SetText(g_szBuffer);
}

//-----------------
void CGameWnd::OnSbScoreUpdate(CCmdUI *pCmdUI)
{
sprintf(g_szBuffer,"Score: %d",m_pGame->GetScore());
pCmdUI->SetText(g_szBuffer);
}

//-----------------
void CGameWnd::OnSbTimerUpdate(CCmdUI *pCmdUI)
{
sprintf(g_szBuffer,"Time: %d",m_pGame->GetTimer());
pCmdUI->SetText(g_szBuffer);
}

//===========================
// CGameWnd message map

//-----------------
BEGIN_MESSAGE_MAP(CGameWnd, CFrameWnd)
   ON_WM_CREATE()
   ON_WM_DESTROY()
   ON_WM_ACTIVATEAPP()
   ON_WM_ERASEBKGND()
   ON_WM_PAINT()
   ON_WM_PALETTECHANGED()
   ON_WM_QUERYNEWPALETTE()
   ON_WM_TIMER()

   ON_WM_KEYDOWN()

   ON_COMMAND(ID_GAME_NEW,OnGameNew)
   ON_COMMAND(ID_GAME_PAUSE,OnGamePause)
   ON_UPDATE_COMMAND_UI(ID_GAME_PAUSE,OnGamePauseUpdate)
   ON_COMMAND(ID_GAME_END,OnGameEnd)
   ON_UPDATE_COMMAND_UI(ID_GAME_END,OnGameEndUpdate)
   ON_COMMAND(ID_OPTIONS_SPEED,OnOptionsSpeed)
   ON_UPDATE_COMMAND_UI(ID_OPTIONS_SPEED,OnOptionsSpeedUpdate)
   ON_COMMAND(ID_OPTIONS_LEVEL,OnOptionsLevel)
   ON_UPDATE_COMMAND_UI(ID_OPTIONS_LEVEL,OnOptionsLevelUpdate)
   ON_COMMAND(ID_VIEW_SCORES,OnViewScores)
   ON_UPDATE_COMMAND_UI(ID_VIEW_SCORES,OnViewScoresUpdate)
   ON_COMMAND(ID_HELP_README,OnHelpReadme)
   ON_COMMAND(ID_HELP_LICENSE,OnHelpLicense)
   ON_COMMAND(ID_HELP_ABOUT,OnHelpAbout)

   ON_UPDATE_COMMAND_UI(ID_SBI_LEVEL,OnSbLevelUpdate)
   ON_UPDATE_COMMAND_UI(ID_SBI_LIVES,OnSbLivesUpdate)
   ON_UPDATE_COMMAND_UI(ID_SBI_SCORE,OnSbScoreUpdate)
   ON_UPDATE_COMMAND_UI(ID_SBI_TIMER,OnSbTimerUpdate)
END_MESSAGE_MAP()
