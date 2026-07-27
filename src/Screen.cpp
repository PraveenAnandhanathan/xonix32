
//===========================
// Screen.cpp
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
// CXonScreen

//-----------------
CXonScreen::CXonScreen(CDC* pdc, CSize& size, RGBQUAD* pColors, UINT nColors/*=256*/) 
   : CDibSection(pdc,size,pColors,nColors)
{
m_iFillFraction1k = m_iFudgeFactor1k = m_iFilledPix = m_iScanLine = 0;
}

//-----------------
void CXonScreen::WipeRedToBluegrn(CRect& rc)
{
BYTE* p;
long xx,yy;
for(yy=rc.top; yy < rc.bottom; yy++)
   {
   p = XY2P(rc.left,yy);
   for(xx=rc.left; xx < rc.right; xx++)
      {
      if ((*p)&XBC_RED)
         {
         *p &= (~XBC_RED);
         *p |= XBC_BLUEGRN;
         }
      p++;
      }
   }
}

//-----------------
void CXonScreen::FillUnmarkedArea(CRect& rc)
{
BYTE* p;
long xx,yy;
for(yy=rc.top; yy < rc.bottom; yy++)
   {
   p = XY2P(rc.left,yy);
   for(xx=rc.left; xx < rc.right; xx++)
      {
      if ((*p)&XBC_MARK1)
         *p &= (~XBC_MARK1);
      else
         *p |= XBC_BLUEGRN;
      p++;
      }
   }
}

//-----------------
void CXonScreen::CountFilledPix(CRect& rc, long nScanLines/*=0*/)
{
long nEndLine;
if (nScanLines == 0)
   {
   nScanLines = rc.Height();
   m_iFilledPix = 0;
   m_iScanLine = rc.top;
   }
nEndLine = min(rc.bottom,(m_iScanLine+nScanLines));
long xx,yy;
for(yy=m_iScanLine; yy < nEndLine; yy++)
for(xx=rc.left; xx < rc.right; xx++)
   if (GetPel(xx,yy,XBC_BLUEGRN,MASK_AND)) 
      m_iFilledPix++;

m_iScanLine = nEndLine;
if (nEndLine >= rc.bottom) 
   {
   m_iFillFraction1k = (1000*m_iFilledPix)/(rc.Width()*rc.Height());
   m_iFilledPix = 0;
   m_iScanLine = 0;
   }
}
