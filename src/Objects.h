
//===========================
// Objects.h
// by Shawn A. VanNess
// created 08 Mar 1997
// for the Win32 platform
//===========================
// CXonObject
// Base class for all Xonix game objects.
// 
//    CXonDot
//    Base class for all point-based objects.
// 
//       CXonGuy
//       Our main character.
// 
//       CXonDotB
//       The black balls.
// 
//       CXonDotW
//       The white balls.
// 
//    CXonLine
//    The yellow lines.
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

#ifndef __OBJECTS_H__
#define __OBJECTS_H__

// Class hierarchy
// class CXonObject;
//    class CXonDot;
//       class CXonGuy;
//       class CXonDotB;
//       class CXonDotW;
//    class CXonLine;

//-----------------
class CXonObject
{
protected:

public:
   CXonObject();
   //virtual ~CXonObject();

#define VFP_RANDOMIZE   Randomize(const CRect& rc, UINT nMinD, UINT nMaxD)
#define VFP_ERASE       Erase(CDibSection* pds) 
#define VFP_MOVE        Move(CDibSection* pds, const CRect& rc) 
#define VFP_DRAW        Draw(CDibSection* pds) 
#define VFP_HITTEST     HitTest(CDibSection* pds) 

   virtual void VFP_RANDOMIZE = 0;
   virtual void VFP_ERASE = 0;
   virtual void VFP_MOVE = 0;
   virtual void VFP_DRAW = 0;
   virtual BOOL VFP_HITTEST = 0;
};

//-----------------
class CXonDot : public CXonObject
{
protected:
   BYTE m_cBkgSig;
   BOOL m_bVisible;
   BYTE* m_pImage;
   BYTE* m_pBkg;

public:
   long x,y;
   long dx,dy;

public:
   CXonDot(BYTE* pImage=NULL);
   virtual ~CXonDot();

   virtual void VFP_RANDOMIZE;
   virtual void VFP_ERASE;
   virtual void VFP_MOVE;
   virtual void VFP_DRAW;
   virtual BOOL VFP_HITTEST;

   BOOL IsNearDot(CXonDot* pdot);
};

//-----------------
class CXonGuy : public CXonDot
{
protected:
   BOOL m_bDrawing, m_bDrawingPrev;

public:
   CXonGuy();
   //virtual ~CXonGuy();

   //virtual void VFP_RANDOMIZE;
   //virtual void VFP_ERASE;
   virtual void VFP_MOVE;
   //virtual void VFP_DRAW;
   virtual BOOL VFP_HITTEST;
   
   BOOL IsDrawing() { return m_bDrawing; }
   BOOL WasDrawing() { return m_bDrawingPrev; }
   void Reset() { m_bDrawing = m_bDrawingPrev = FALSE; }
};

//-----------------
class CXonDotB : public CXonDot
{
protected:

public:
   CXonDotB();
   //virtual ~CXonDotB();

   //virtual void VFP_RANDOMIZE;
   //virtual void VFP_ERASE;
   //virtual void VFP_MOVE;
   //virtual void VFP_DRAW;
   //virtual BOOL VFP_HITTEST;
};

//-----------------
class CXonDotW : public CXonDot
{
protected:

public:
   CXonDotW();
   //virtual ~CXonDotW();

   //virtual void VFP_RANDOMIZE;
   //virtual void VFP_ERASE;
   //virtual void VFP_MOVE;
   //virtual void VFP_DRAW;
   virtual BOOL VFP_HITTEST;
};

//-----------------
class CXonLine : public CXonObject
{
public:
   CXonDot dot0, dot1;

public:
   CXonLine();
   //virtual ~CXonLine();

   virtual void VFP_RANDOMIZE;
   virtual void VFP_ERASE;
   virtual void VFP_MOVE;
   virtual void VFP_DRAW;
   virtual BOOL VFP_HITTEST;
};


#endif // include-guard
