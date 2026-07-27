
//===========================
// HiScoreTbl.cpp
// by Shawn A. VanNess
// created 05 Jun 1997
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
BOOL CScoreList::Save()
{
long i,j;
FILE* pf = fopen("HiScores.dat","wb");
if (!pf) return FALSE;

for(i=0; i < 10; i++) m_nScoreArray[i] ^= 0x55555555;
for(i=0; i < 10; i++) for(j=0; j < 16; j++) m_szNameArray[i][j] ^= 0x55;
fwrite(m_nScoreArray,sizeof(long),10,pf);
fwrite(m_szNameArray,16,10,pf);
for(i=0; i < 10; i++) m_nScoreArray[i] ^= 0x55555555;
for(i=0; i < 10; i++) for(j=0; j < 16; j++) m_szNameArray[i][j] ^= 0x55;

fclose(pf);
return TRUE;
}

//-----------------
BOOL CScoreList::Load()
{
long i,j;
FILE* pf = fopen("HiScores.dat","rb");
if (!pf)
   {
   for(i=0; i < 10; i++)
      {
      m_nScoreArray[i] = 0;
      strcpy(m_szNameArray[i],"...empty...");
      }
   return FALSE;
   }

fread(m_nScoreArray,sizeof(long),10,pf);
fread(m_szNameArray,16,10,pf);
for(i=0; i < 10; i++) m_nScoreArray[i] ^= 0x55555555;
for(i=0; i < 10; i++) for(j=0; j < 16; j++) m_szNameArray[i][j] ^= 0x55;

fclose(pf);
return TRUE;
}

//-----------------
void CScoreList::Insert(UINT nSlot, char* pszName, UINT nScore)
{
UINT n=0;

n = 9;
while(n > nSlot)
   {
   m_nScoreArray[n] = m_nScoreArray[n-1];
   strcpy(m_szNameArray[n],m_szNameArray[n-1]);
   n--;
   }
m_nScoreArray[n] = nScore;
strcpy(m_szNameArray[n],pszName);

return;
}

