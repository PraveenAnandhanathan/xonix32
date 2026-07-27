
//===========================
// DibSection.h
// by Shawn A. VanNess
// created 08 Mar 1997
// for the Win32 platform
//===========================
// CDibSection
// This class encapsulates an 8bpp DibSection object.  All drawing 
// functions support an optional masking feature, to allow easy 
// access to individual bit patterns.  The class also provides a 
// static member function useful for initializing CPalette objects 
// with RGBQUAD arrays.
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

#ifndef __DIBSECTION_H__
#define __DIBSECTION_H__

#define BITS2DWORDS(bits) (((DWORD)(bits)+31)/32)
#define XY2P(x,y) (m_pBits+((UINT)y*m_nScanSize)+x)

#define MASK_COPY ((DWORD)(0))
#define MASK_AND  ((DWORD)(1))
#define MASK_OR   ((DWORD)(2))
#define MASK_XOR  ((DWORD)(3))
#define MASK_NAND ((DWORD)(4))

//-----------------
BYTE Mask(BYTE op1, BYTE op2, DWORD mop);

//-----------------
class CDibSection
{
protected:
   CSize m_size;
   UINT m_nScanSize;
   HBITMAP m_hBmp,m_hBmpOld;
   CDC m_dcMem;
   BYTE* m_pBits;

public:
   CDibSection(CDC* pdc, CSize& size, RGBQUAD* pColors, UINT nColors=256);
   virtual ~CDibSection();

   static void ConstructPalette(CPalette& pal, RGBQUAD* pColors, UINT nColors=256);

   void PaintTo(CDC* pdc);
   BYTE GetPel(long x, long y, BYTE c=0, DWORD mop=0);
   void SetPel(long x, long y, BYTE c, DWORD mop=0);
   void SetAll(BYTE c, DWORD mop=0);
   void DrawHorzLine(long x0, long x1, long y, BYTE c, DWORD mop=0);
   void DrawLine(long x0, long y0, long x1, long y1, long w, BYTE c, DWORD mop=0);
   void DrawRect(CRect rc, BYTE c, DWORD mop=0);
   void DrawFloodFill(long x, long y, BYTE c, BYTE cc, DWORD mop=0);
   void CopyBlit(long x, long y, long w, long h, BYTE* pDst);
   void DrawBlit(long x, long y, long w, long h, BYTE* pSrc);
   void DrawBmpFromRes(long x, long y, UINT id, BOOL bCenter=FALSE, CRect* prc=NULL, DWORD mop=0);
};


#endif // include-guard
