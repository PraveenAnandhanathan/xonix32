
//===========================
// Screen.h
// by Shawn A. VanNess
// created 08 Mar 1997
// for the Win32 platform
//===========================
// CXonScreen
// This class adds Xonix-specific functionality to 
// the CDibSection class.
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

#ifndef __SCREEN_H__
#define __SCREEN_H__

//-----------------
class CXonScreen : public CDibSection
{
protected:
   long m_iFillFraction1k; // fraction of game surface filled (1000:100%)
   long m_iFudgeFactor1k; // subtracted from the fillfraction for aesthetics
   long m_iFilledPix; // temp accumulator for number of bluegrn pix
   long m_iScanLine; // accumulator raster-marker

public:
   CXonScreen(CDC* pdc, CSize& size, RGBQUAD* pColors, UINT nColors=256);
   // virtual ~CXonScreen();

   void SetFudgeFactor(long i) { if (m_iFudgeFactor1k == 0) m_iFudgeFactor1k = i-150; } // 15% base value
   long GetFillFraction() { return m_iFillFraction1k-m_iFudgeFactor1k; }

   void WipeRedToBluegrn(CRect& rc);
   void FillUnmarkedArea(CRect& rc);
   void CountFilledPix(CRect& rc, long nScanLines=0);
};


#endif // include-guard
