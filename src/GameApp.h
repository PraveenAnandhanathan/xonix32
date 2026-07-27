
//===========================
// GameApp.h
// by Shawn A. VanNess
// created 08 Mar 1997
// for the Win32 platform
//===========================
// This is the main include file.  Along with StdAfx.h, this file 
// should be included by all cpp files in the project.
// 
// CGameApp
// This class is derived from the MFC CWinApp class.  It provides 
// a hook into the idle-time loop, which is necessary to control 
// the game (timers do not run fast enough on Win95 machines).
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

#ifndef __GAMEAPP_H__
#define __GAMEAPP_H__

#ifndef __AFXWIN_H__
   #error include 'StdAfx.h' first
#endif

#include "resource.h"
#include "macros.h"

#include "DibSection.h"
#include "Screen.h"
#include "Objects.h"
#include "HiScoreTbl.h"
#include "GameDlg.h"
#include "Game.h"
#include "GameWnd.h"

// Misc extern declrations
extern char g_szBuffer[];

//-----------------
class CGameApp : public CWinApp
{
protected:
   BOOL m_bNT;

public:
   // virtual BOOL InitApplication();
   virtual BOOL InitInstance();
   virtual int ExitInstance();
   virtual BOOL OnIdle(long lCount);
   // virtual BOOL IsIdleMessage(MSG* pMsg);
};


#endif // include-guard
