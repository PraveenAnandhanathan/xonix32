
//===========================
// GameApp.cpp
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

char g_szBuffer[256];

CGameApp theApp;

//===========================
// CGameApp

//-----------------
BOOL CGameApp::InitInstance()
{
#ifdef _AFXDLL
Enable3dControls(); // when using mfc in a shared dll
#else
Enable3dControlsStatic(); // when linking to mfc statically
#endif

// Determine version/platform info
OSVERSIONINFO osvi;
osvi.dwOSVersionInfoSize = sizeof(OSVERSIONINFO);
::GetVersionEx(&osvi);
if (osvi.dwPlatformId == VER_PLATFORM_WIN32_NT) m_bNT = TRUE;
else m_bNT = FALSE;

// Render the main window
CGameWnd* pWnd = new CGameWnd;
if (!pWnd->LoadFrame(IDR_MAINFRAME,(WS_OVERLAPPED|WS_CAPTION|WS_SYSMENU|WS_MINIMIZEBOX)))
   return FALSE;
m_pMainWnd = pWnd;

m_pMainWnd->ShowWindow(m_nCmdShow); // draw NC area and frame border
m_pMainWnd->UpdateWindow(); // send paint msg

return TRUE;
}

//-----------------
int CGameApp::ExitInstance()
{
return 0;
}

//-----------------
BOOL CGameApp::OnIdle(long lCount)
{
// Allow system processing
BOOL bMore = CWinApp::OnIdle(lCount);

// Check for NULL frame window ptr
CGameWnd* pWnd = dynamic_cast<CGameWnd*>(m_pMainWnd);
if (!pWnd) return bMore;

// If game is paused, no need to continue idle-time processing
if (pWnd->IsPaused()) return bMore;

// Render a frame
UINT nTime = pWnd->MainLoop();

if (m_bNT && nTime >= 15) // if we're running NT then we can sleep
   Sleep(10);

return TRUE; // request more idle-time processing
}
