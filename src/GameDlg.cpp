
//===========================
// GameDlg.cpp
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
// CSpeedDialog

//-----------------
CSpeedDialog::CSpeedDialog(UINT id) : CDialog(id)
{
m_pslide = NULL;
m_nSpeed = MIN_FPS;
}

//-----------------
BOOL CSpeedDialog::OnInitDialog()
{
// Call base implementation
CDialog::OnInitDialog();

m_pslide = (CSliderCtrl *)GetDlgItem(IDC_SLIDER_SPEED);
m_pslide->SetRange(MIN_FPS,MAX_FPS);
m_pslide->SetTicFreq(5);
m_pslide->SetPos(m_nSpeed);

return TRUE;
}

//-----------------
BEGIN_MESSAGE_MAP(CSpeedDialog, CDialog)
   ON_WM_HSCROLL()
END_MESSAGE_MAP()

//-----------------
afx_msg void CSpeedDialog::OnHScroll(UINT iSBCode, UINT iPos, CScrollBar *pSB)
{
// pSB must point to our slider ctrl
if (pSB != (CScrollBar *)m_pslide) return;
m_nSpeed = m_pslide->GetPos();
}


//===========================
// CLevelDialog

//-----------------
CLevelDialog::CLevelDialog(UINT id) : CDialog(id)
{
m_pspin = NULL;
m_nLevel = 1;
}

//-----------------
BOOL CLevelDialog::OnInitDialog()
{
// Call base implementation
CDialog::OnInitDialog();

m_pspin = (CSpinButtonCtrl *)GetDlgItem(IDC_SPIN_LEVEL);
m_pspin->SetBuddy(GetDlgItem(IDC_EDIT1));
m_pspin->SetRange(1,20);
m_pspin->SetPos(m_nLevel);

return TRUE;
}

//-----------------
void CLevelDialog::OnOK()
{
m_nLevel = min(max(m_pspin->GetPos(),1),20);
EndDialog(IDOK);
// Call base implementation
/*CDialog::OnOK();*/
}

//-----------------
BEGIN_MESSAGE_MAP(CLevelDialog, CDialog)
END_MESSAGE_MAP()


//===========================
// CHighScoreDialog

//-----------------
CHighScoreDialog::CHighScoreDialog(UINT id) : CDialog(id)
{
m_plstScoreData = NULL;
m_plbRank = m_plbName = m_plbScore = NULL;
}

//-----------------
BOOL CHighScoreDialog::OnInitDialog()
{
// Call base implementation
CDialog::OnInitDialog();

m_plbRank = (CListBox*)GetDlgItem(IDC_LIST_RANK);
m_plbName = (CListBox*)GetDlgItem(IDC_LIST_NAME);
m_plbScore = (CListBox*)GetDlgItem(IDC_LIST_SCORE);
for(long i=0; i < 10; i++)
   {
   sprintf(g_szBuffer,"%2d:",i+1);
   m_plbRank->AddString(g_szBuffer);
   m_plbName->AddString(m_plstScoreData->GetName(i));
   sprintf(g_szBuffer,"%5d",m_plstScoreData->GetScore(i));
   m_plbScore->AddString(g_szBuffer);
   }
return TRUE;
}

//-----------------
BEGIN_MESSAGE_MAP(CHighScoreDialog, CDialog)
END_MESSAGE_MAP()


//===========================
// CNewHighScoreDialog

//-----------------
CNewHighScoreDialog::CNewHighScoreDialog(UINT id) : CDialog(id)
{
m_pec = NULL;
}

//-----------------
BOOL CNewHighScoreDialog::OnInitDialog()
{
// Call base implementation
CDialog::OnInitDialog();

m_pec = (CEdit*)GetDlgItem(IDC_EDIT_NAME);
m_pec->SetWindowText(m_szName);

return TRUE;
}

//-----------------
void CNewHighScoreDialog::OnOK()
{
m_pec->GetWindowText(m_szName,15);
EndDialog(IDOK);
// Call base implementation
/*CDialog::OnOK();*/
}

//-----------------
BEGIN_MESSAGE_MAP(CNewHighScoreDialog, CDialog)
END_MESSAGE_MAP()

//===========================
// CAboutBoxDialog

//-----------------
CAboutBoxDialog::CAboutBoxDialog(UINT id) : CDialog(id)
{
m_pTxtVersion = NULL;
}

//-----------------
BOOL CAboutBoxDialog::OnInitDialog()
{
// Call base implementation
CDialog::OnInitDialog();

m_pTxtVersion = (CStatic*)GetDlgItem(IDC_TEXT_VERSION);
m_pTxtVersion->SetWindowText(RELEASE);

return TRUE;
}
