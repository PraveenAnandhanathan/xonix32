
//===========================
// Objects.cpp
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

#include "obj_data.h" // object representations and such

//===========================
// CXonObject

//-----------------
CXonObject::CXonObject()
{
// nada
}

//===========================
// CXonDot

//-----------------
CXonDot::CXonDot(BYTE* pImage/*=NULL*/)
{
m_cBkgSig = XBC_BLACK;

if (!pImage) m_bVisible = FALSE;
else m_bVisible = TRUE;

m_pImage = pImage;
m_pBkg = NULL;

if (m_bVisible) m_pBkg = new BYTE[64];

// Init vector
x=y=dx=dy=0; 
}

//-----------------
CXonDot::~CXonDot()
{
if (m_bVisible) delete [] m_pBkg;
}

//-----------------
void CXonDot::VFP_RANDOMIZE
{
x = (rand()%(rc.right-rc.left)) + rc.left;
y = (rand()%(rc.bottom-rc.top)) + rc.top;
dx = ((rand()%((nMaxD+1)-nMinD)) + nMinD); if (rand()%2) dx = -dx;
dy = ((rand()%((nMaxD+1)-nMinD)) + nMinD); if (rand()%2) dy = -dy;
}

//-----------------
void CXonDot::VFP_ERASE
{
if (!m_bVisible) return;

// Please replace divot
pds->DrawBlit(x-OBJ_OFFSET,y-OBJ_OFFSET,OBJ_SIZE,OBJ_SIZE,m_pBkg);
}

//-----------------
void CXonDot::VFP_MOVE
{
long xx,yy;
xx = x+dx;
yy = y+dy;

// If we clip out, bounce!
if (xx-OBJ_OFFSET < rc.left)
   {
   xx = rc.left+OBJ_OFFSET;
   dx = -dx;
   }
if (xx+OBJ_OFFSET >= rc.right)
   {
   xx = rc.right-1-OBJ_OFFSET;
   dx = -dx;
   }
if (yy-OBJ_OFFSET < rc.top)
   {
   yy = rc.top+OBJ_OFFSET;
   dy = -dy;
   }
if (yy+OBJ_OFFSET >= rc.bottom)
   {
   yy = rc.bottom-1-OBJ_OFFSET;
   dy = -dy;
   }

// Bounce off bluegrn/black surface
long xc,yc;
BYTE cx,cy;
xc = xx; yc = yy;
if (dx < 0) xc = xx-OBJ_OFFSET;
if (dx > 0) xc = xx+OBJ_OFFSET;
if (dy < 0) yc = yy-OBJ_OFFSET;
if (dy > 0) yc = yy+OBJ_OFFSET;

cx = pds->GetPel(xc,yy,XBC_BLUEGRN,MASK_AND);
cy = pds->GetPel(xx,yc,XBC_BLUEGRN,MASK_AND);

if (cx != m_cBkgSig) dx = -dx;
if (cy != m_cBkgSig) dy = -dy;

// Keep on truckin
x = xx; y = yy;
}

//-----------------
void CXonDot::VFP_DRAW
{
if (!m_bVisible) return;

// Take a snapshot of the bkgrnd before painting
pds->CopyBlit(x-OBJ_OFFSET,y-OBJ_OFFSET,OBJ_SIZE,OBJ_SIZE,m_pBkg);

// Transparent blit!
pds->DrawBlit(x-OBJ_OFFSET,y-OBJ_OFFSET,OBJ_SIZE,OBJ_SIZE,m_pImage);
}

//-----------------
BOOL CXonDot::VFP_HITTEST
{
return FALSE; //no testing, by default
}

//-----------------
BOOL CXonDot::IsNearDot(CXonDot* pdot)
{
if (!pdot) return FALSE;

long xx,yy;
xx = x - pdot->x; if (xx < 0) xx = -xx;
yy = y - pdot->y; if (yy < 0) yy = -yy;

if (xx+yy <= OBJ_SIZE) return TRUE;
else return FALSE;
}

//===========================
// CXonGuy

//-----------------
CXonGuy::CXonGuy() : 
   CXonDot(g_cGuy)
{
m_cBkgSig = XBC_BLUEGRN;
m_bDrawing = m_bDrawingPrev = FALSE;
}

//-----------------
void CXonGuy::VFP_MOVE
{
long xx,yy;
xx = x+dx;
yy = y+dy;

// If we clip out, stop!
if (xx-OBJ_OFFSET < rc.left)
   {
   xx = rc.left+OBJ_OFFSET;
   dx = 0;
   }
if (xx+OBJ_OFFSET >= rc.right)
   {
   xx = rc.right-1-OBJ_OFFSET;
   dx = 0;
   }
if (yy-OBJ_OFFSET < rc.top)
   {
   yy = rc.top+OBJ_OFFSET;
   dy = 0;
   }
if (yy+OBJ_OFFSET >= rc.bottom)
   {
   yy = rc.bottom-1-OBJ_OFFSET;
   dy = 0;
   }

// Update our drawing state
m_bDrawingPrev = m_bDrawing;
if (pds->GetPel(xx,yy,XBC_BLUEGRN,MASK_AND))
   m_bDrawing = FALSE;
else
   m_bDrawing = TRUE;

// Keep going
x = xx; y = yy;
}

//-----------------
BOOL CXonGuy::VFP_HITTEST
{
// Guy redline cld NOT enforced in version 2.0 and higher
return FALSE;
}

//===========================
// CXonDotB

//-----------------
CXonDotB::CXonDotB() : 
   CXonDot(g_cBDot)
{
m_cBkgSig = XBC_BLUEGRN;
}

//===========================
// CXonDotW

//-----------------
CXonDotW::CXonDotW() : 
   CXonDot(g_cWDot)
{
}

//-----------------
BOOL CXonDotW::VFP_HITTEST
{
long xc,yc;
xc = x; yc = y;
if (dx < 0) xc = x-OBJ_OFFSET;
if (dx > 0) xc = x+OBJ_OFFSET;
if (dy < 0) yc = y-OBJ_OFFSET;
if (dy > 0) yc = y+OBJ_OFFSET;

if (pds->GetPel(x,y,XBC_RED,MASK_AND)) return TRUE;
if (pds->GetPel(xc,y,XBC_RED,MASK_AND)) return TRUE;
if (pds->GetPel(x,yc,XBC_RED,MASK_AND)) return TRUE;
return FALSE;
}

//===========================
// CXonLine

//-----------------
CXonLine::CXonLine()
{
// nada
}

//-----------------
void CXonLine::VFP_RANDOMIZE
{
dot0.Randomize(rc,nMinD,nMaxD);
dot1.Randomize(rc,nMinD,nMaxD);
}

//-----------------
void CXonLine::VFP_ERASE
{
pds->DrawLine(dot0.x,dot0.y,dot1.x,dot1.y,3,(XBC_RED|XBC_BLUEGRN|XBC_YELLOW),MASK_NAND);
}

//-----------------
void CXonLine::VFP_MOVE
{
dot0.Move(pds,rc);
dot1.Move(pds,rc);
}

//-----------------
void CXonLine::VFP_DRAW
{
pds->DrawLine(dot0.x,dot0.y,dot1.x,dot1.y,3,(XBC_YELLOW),MASK_OR);
}

//-----------------
BOOL CXonLine::VFP_HITTEST
{
return FALSE;
}
