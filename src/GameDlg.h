
//===========================
// GameDlg.h
// by Shawn A. VanNess
// created 08 Mar 1997
// for the Win32 platform
//===========================
// CDialog-derived
// These classes represent the various dialog boxes in the game.
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

#ifndef __GAMEDLG_H__
#define __GAMEDLG_H__

//-----------------
class CSpeedDialog : public CDialog
{
private:
   CSliderCtrl *m_pslide;

public:
   UINT m_nSpeed; // game speed (fps)
   
   CSpeedDialog(UINT id);
   BOOL OnInitDialog();

   afx_msg void OnHScroll(UINT iSBCode, UINT iPos, CScrollBar *pSB);
   DECLARE_MESSAGE_MAP();
};

//-----------------
class CLevelDialog : public CDialog
{
private:
   CSpinButtonCtrl *m_pspin;

public:
   UINT m_nLevel; // starting level

   CLevelDialog(UINT id);
   BOOL OnInitDialog();
   void OnOK();

   DECLARE_MESSAGE_MAP();
};

//-----------------
class CHighScoreDialog : public CDialog
{
private:
   CListBox* m_plbRank;
   CListBox* m_plbName;
   CListBox* m_plbScore;

public:
   CScoreList* m_plstScoreData; // high score table data

   CHighScoreDialog(UINT id);
   BOOL OnInitDialog();

   DECLARE_MESSAGE_MAP();
};

//-----------------
class CNewHighScoreDialog : public CDialog
{
private:
   CEdit* m_pec;

public:
   char m_szName[16]; // name of player

   CNewHighScoreDialog(UINT id);
   BOOL OnInitDialog();
   void OnOK();

   DECLARE_MESSAGE_MAP();
};

//-----------------
class CAboutBoxDialog : public CDialog
{
private:
   CStatic* m_pTxtVersion;

public:
   CAboutBoxDialog(UINT id);
   BOOL OnInitDialog();
};


#endif // include-guard
