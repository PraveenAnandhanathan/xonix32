
//===========================
// DibSection.cpp
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

//-----------------
BYTE Mask(BYTE op1, BYTE op2, DWORD mop)
{
switch(mop)
   {
   case MASK_AND: return (BYTE)(op1&op2);
   case MASK_OR: return (BYTE)(op1|op2);
   case MASK_XOR: return (BYTE)(op1^op2);
   case MASK_NAND: return (BYTE)(op1&(~op2));
   default: return (BYTE)(0);
   }
}

//===========================
// CDibSection

//-----------------
CDibSection::CDibSection(CDC* pdc, CSize& size, RGBQUAD* pColors, UINT nColors/*=256*/)
{
m_size = size;
m_nScanSize = 4*BITS2DWORDS(size.cx*8);
m_hBmp = m_hBmpOld = NULL;
m_pBits = NULL;

nColors = min(nColors,256);

// Create the dibsection!
BITMAPINFO* pbi = (BITMAPINFO*) new BYTE[sizeof(BITMAPINFOHEADER)+(nColors*sizeof(RGBQUAD))];
pbi->bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
pbi->bmiHeader.biWidth = size.cx;
pbi->bmiHeader.biHeight = -size.cy; // top-down!
pbi->bmiHeader.biPlanes = 1;
pbi->bmiHeader.biBitCount = 8;
pbi->bmiHeader.biCompression = BI_RGB;
pbi->bmiHeader.biSizeImage = 0; // autocalc
pbi->bmiHeader.biXPelsPerMeter = 0;
pbi->bmiHeader.biYPelsPerMeter = 0;
pbi->bmiHeader.biClrUsed = 0;
pbi->bmiHeader.biClrImportant = 0;
memcpy(pbi->bmiColors,pColors,nColors*sizeof(RGBQUAD));
m_hBmp = CreateDIBSection(pdc->m_hDC,pbi,DIB_RGB_COLORS,(void **)&m_pBits,NULL,0);
delete [] (BYTE*)pbi;

// Select our dibsection into our mem dc
m_dcMem.CreateCompatibleDC(pdc);
m_dcMem.SetBkColor(RGB_BLACK);
m_dcMem.SetBkMode(TRANSPARENT);
m_hBmpOld = (HBITMAP) SelectObject(m_dcMem.m_hDC,m_hBmp);

SetAll((BYTE)(0));
}

//-----------------
CDibSection::~CDibSection()
{
// Unselect and delete our dibsection
SelectObject(m_dcMem.m_hDC,m_hBmpOld);
DeleteObject(m_hBmp);
}

//-----------------
void CDibSection::ConstructPalette(CPalette& pal, RGBQUAD* pColors, UINT nColors/*=256*/)
{
if (pal.m_hObject) pal.DeleteObject();
nColors = min(nColors,256);

// Setup logical palette
LOGPALETTE* pLogPal;
pLogPal = (LOGPALETTE*) new BYTE[sizeof(LOGPALETTE)+(nColors*sizeof(PALETTEENTRY))];
pLogPal->palVersion = 0x0300;
pLogPal->palNumEntries = nColors;

for(UINT i=0; i < nColors; i++)
   {
   pLogPal->palPalEntry[i].peRed = pColors[i].rgbRed;
   pLogPal->palPalEntry[i].peGreen = pColors[i].rgbGreen;
   pLogPal->palPalEntry[i].peBlue = pColors[i].rgbBlue;
   pLogPal->palPalEntry[i].peFlags = PC_NOCOLLAPSE;
   }

// Create log palette
pal.CreatePalette(pLogPal);
delete [] (BYTE*)pLogPal;
}

//-----------------
void CDibSection::PaintTo(CDC* pdc)
{
pdc->BitBlt(0,0,m_size.cx,m_size.cy,&m_dcMem,0,0,SRCCOPY);
GdiFlush();
}

//-----------------
BYTE CDibSection::GetPel(long x, long y, BYTE c, DWORD mop/*=0*/)
{
BOUND(x,0,m_size.cx-1);
BOUND(y,0,m_size.cy-1);

BYTE* p = XY2P(x,y);
if (!mop) return (*p);
else return (Mask(*p,c,mop));
}

//-----------------
void CDibSection::SetPel(long x, long y, BYTE c, DWORD mop/*=0*/)
{
BOUND(x,0,m_size.cx-1);
BOUND(y,0,m_size.cy-1);

BYTE* p = XY2P(x,y);
if (!mop) *p = c;
else *p = Mask(*p,c,mop);
}

//-----------------
void CDibSection::SetAll(BYTE c, DWORD mop/*=0*/)
{
BYTE* p = XY2P(0,0);
for(UINT i=0; i < m_nScanSize*m_size.cy; i++, p++)
   {
   if (!mop) *p = c;
   else *p = Mask(*p,c,mop);
   }
}

//-----------------
void CDibSection::DrawHorzLine(long x0, long x1, long y, BYTE c, DWORD mop/*=0*/)
{ // (x1,y) not included
BOUND(x0,0,m_size.cx);
BOUND(x1,0,m_size.cx);
BOUND(y,0,m_size.cy-1);

if (x1 < x0) { x0 ^= x1; x1 ^= x0; x0 ^= x1; }

BYTE* p = XY2P(x0,y);
while(x0 < x1)
   {
   if (!mop) *p = c;
   else *p = Mask(*p,c,mop);
   x0++;
   p++;
   }
}

//-----------------
void CDibSection::DrawLine(long x0, long y0, long x1, long y1, long w, BYTE c, DWORD mop/*=0*/)
{ // (x1,y1) not included
BOUND(x0,0,m_size.cx);
BOUND(y0,0,m_size.cy);
BOUND(x1,0,m_size.cx);
BOUND(y1,0,m_size.cy);
BOUND(w,1,5);

long dx,dy,dt;
dx = (x1-x0); dy = (y1-y0);
dt = max(ABS(dx),ABS(dy));

CRect rc;
long xx,yy,tt;
for(tt=0; tt < dt; tt++)
   {
   xx = x0+(tt*dx)/dt;
   yy = y0+(tt*dy)/dt;
   if (w == 1)
      SetPel(xx,yy,c,mop);
   else
      {
      rc.left = xx-(w/2);
      rc.top = yy-(w/2);
      rc.right = rc.left+w;
      rc.bottom = rc.top+w;
      DrawRect(rc,c,mop);
      }
   }
}

//-----------------
void CDibSection::DrawRect(CRect rc, BYTE c, DWORD mop/*=0*/)
{ // left&top included, right*bottom not included
BOUND(rc.left,0,m_size.cx);
BOUND(rc.top,0,m_size.cy);
BOUND(rc.right,0,m_size.cx);
BOUND(rc.bottom,0,m_size.cy);

rc.NormalizeRect();

BYTE* p;
long x,y;
for(y=rc.top; y < rc.bottom; y++)
   {
   p = XY2P(rc.left,y);
   for(x=rc.left; x < rc.right; x++)
      {
      if (!mop) *p = c;
      else *p = Mask(*p,c,mop);
      p++;
      }
   }
}

//-----------------
void CDibSection::DrawFloodFill(long x, long y, BYTE c, BYTE cc, DWORD mop/*=0*/)
{
BOUND(x,0,m_size.cx-1);
BOUND(y,0,m_size.cy-1);

if (GetPel(x,y,(c|cc),MASK_AND)) return;

long xx, xl, xr;
xl = xr = x;

while(!GetPel(xl,y,(c|cc),MASK_AND)) xl--;
while(!GetPel(xr,y,(c|cc),MASK_AND)) xr++;

if (xl < x) xl++;
DrawHorzLine(xl,xr,y,c,mop);

for(xx = xl; xx < xr; xx++)
   {
   DrawFloodFill(xx,y-1,c,cc,mop);
   DrawFloodFill(xx,y+1,c,cc,mop);
   }
}

//-----------------
void CDibSection::CopyBlit(long x, long y, long w, long h, BYTE* pDst)
{
BOUND(x,0,m_size.cx-1);
BOUND(y,0,m_size.cy-1);
BOUND(w,0,m_size.cx-x);
BOUND(h,0,m_size.cy-y);
if (!pDst) return;

BYTE* p;
long xx,yy;
for(yy=y; yy < y+h; yy++)
   {
   p = XY2P(x,yy);
   for(xx=x; xx < x+w; xx++)
      {
      *pDst = *p;
      pDst++; p++;
      }
   }
}

//-----------------
void CDibSection::DrawBlit(long x, long y, long w, long h, BYTE* pSrc)
{
BOUND(x,0,m_size.cx-1);
BOUND(y,0,m_size.cy-1);
BOUND(w,0,m_size.cx-x);
BOUND(h,0,m_size.cy-y);
if (!pSrc) return;

BYTE* p;
long xx,yy;
for(yy=y; yy < y+h; yy++)
   {
   p = XY2P(x,yy);
   for(xx=x; xx < x+w; xx++)
      {
      if (*pSrc != (BYTE)255) // transparent color-key
         *p = *pSrc;
      pSrc++; p++;
      }
   }
}

//-----------------
void CDibSection::DrawBmpFromRes(long x, long y, UINT id, BOOL bCenter/*=FALSE*/, CRect* prc/*=NULL*/, DWORD mop/*=0*/)
{
// assumptions:
//    8bpp
//    256-entry color table, identical to our ds palette
//    bottom-up (positive height)
//    0x0028 byte header before color table

if (!id) return;

HRSRC hRes = FindResource(NULL,(LPCTSTR)id,RT_BITMAP);
if (!hRes) return;

HGLOBAL hGlob = LoadResource(NULL,hRes);
if (!hGlob) return;

DWORD* pBitmap = (DWORD*)LockResource(hGlob);
if (!pBitmap) return;

BYTE* pSrc = ((BYTE*)pBitmap)+(0x428); //0x0028+0x04*0x0100
long w,h;
w = (long)pBitmap[1];
h = (long)pBitmap[2];
if (bCenter)
   {
   x -= (w/2);
   y -= (h/2);
   }
BOUND(x,0,m_size.cx-1);
BOUND(y,0,m_size.cy-1);
BOUND(w,0,m_size.cx-x);
BOUND(h,0,m_size.cy-y);

if (prc)
   {
   prc->left = x;
   prc->top = y;
   prc->right = x+w;
   prc->bottom = y+h;
   }

BYTE* p;
long xx,yy;
for(yy=y+h-1; yy >= y; yy--) // bottom-up
   {
   p = XY2P(x,yy);
   for(xx=x; xx < x+w; xx++)
      {
      if (!mop) *p = *pSrc;
      else *p = Mask(*p,*pSrc,mop);
      pSrc++; p++;
      }
   while((pSrc-(BYTE*)pBitmap)&0x03) pSrc++; // dword-alignment
   }
}
