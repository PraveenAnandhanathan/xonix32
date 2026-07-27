
//===========================
// HiScoreTbl.h
// by Shawn A. VanNess
// created 05 Jun 1997
// for the Win32 platform
//===========================
// CScoreList
// This class encapsulates a pair of arrays, which hold 
// the ten best names and scores.  It can save and load 
// itself to a datafile.
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

#ifndef __HISCORETBL_H__
#define __HISCORETBL_H__

//-----------------
class CScoreList // high-score table data
{
private:
   UINT m_nScoreArray[10];
   char m_szNameArray[10][16];

public:
   // CScoreList();
   // virtual ~CScoreList();

   UINT GetScore(UINT n)
      { return m_nScoreArray[n]; }
   char* GetName(UINT n)
      { return m_szNameArray[n]; }
   void SetName(UINT nSlot, char* pszName)
      { strcpy(m_szNameArray[nSlot],pszName); }

   void Insert(UINT nSlot, char* pszName, UINT nScore);
   BOOL Save();
   BOOL Load();
};


#endif // include-guard
