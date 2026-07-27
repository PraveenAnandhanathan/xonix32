# Microsoft Developer Studio Project File - Name="Xonix32" - Package Owner=<4>
# Microsoft Developer Studio Generated Build File, Format Version 5.00
# ** DO NOT EDIT **

# TARGTYPE "Win32 (x86) Application" 0x0101

CFG=Xonix32 - Win32 Release
!MESSAGE This is not a valid makefile. To build this project using NMAKE,
!MESSAGE use the Export Makefile command and run
!MESSAGE 
!MESSAGE NMAKE /f "Xonix32.mak".
!MESSAGE 
!MESSAGE You can specify a configuration when running NMAKE
!MESSAGE by defining the macro CFG on the command line. For example:
!MESSAGE 
!MESSAGE NMAKE /f "Xonix32.mak" CFG="Xonix32 - Win32 Release"
!MESSAGE 
!MESSAGE Possible choices for configuration are:
!MESSAGE 
!MESSAGE "Xonix32 - Win32 Release" (based on "Win32 (x86) Application")
!MESSAGE "Xonix32 - Win32 Debug" (based on "Win32 (x86) Application")
!MESSAGE 

# Begin Project
# PROP Scc_ProjName ""
# PROP Scc_LocalPath ""
CPP=cl.exe
MTL=midl.exe
RSC=rc.exe

!IF  "$(CFG)" == "Xonix32 - Win32 Release"

# PROP BASE Use_MFC 5
# PROP BASE Use_Debug_Libraries 0
# PROP BASE Output_Dir ".\Release"
# PROP BASE Intermediate_Dir ".\Release"
# PROP BASE Target_Dir ""
# PROP Use_MFC 5
# PROP Use_Debug_Libraries 0
# PROP Output_Dir ".\Release"
# PROP Intermediate_Dir ".\Release"
# PROP Ignore_Export_Lib 0
# PROP Target_Dir ""
# ADD BASE CPP /nologo /MT /W3 /GX /O2 /D "WIN32" /D "NDEBUG" /D "_WINDOWS" /D "_MBCS" /Yu"stdafx.h" /c
# ADD CPP /nologo /MT /W3 /GR /O2 /D "NDEBUG" /D "WIN32" /D "_WINDOWS" /Yu"stdafx.h" /FD /c
# ADD BASE MTL /nologo /D "NDEBUG" /win32
# ADD MTL /nologo /D "NDEBUG" /mktyplib203 /win32
# ADD BASE RSC /l 0x409 /d "NDEBUG"
# ADD RSC /l 0x409 /d "NDEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LINK32=link.exe
# ADD BASE LINK32 /nologo /subsystem:windows /machine:I386
# ADD LINK32 /nologo /subsystem:windows /pdb:none /machine:I386

!ELSEIF  "$(CFG)" == "Xonix32 - Win32 Debug"

# PROP BASE Use_MFC 5
# PROP BASE Use_Debug_Libraries 1
# PROP BASE Output_Dir ".\Debug"
# PROP BASE Intermediate_Dir ".\Debug"
# PROP BASE Target_Dir ""
# PROP Use_MFC 5
# PROP Use_Debug_Libraries 1
# PROP Output_Dir ".\Debug"
# PROP Intermediate_Dir ".\Debug"
# PROP Ignore_Export_Lib 0
# PROP Target_Dir ""
# ADD BASE CPP /nologo /MTd /W3 /Gm /GX /Zi /Od /D "WIN32" /D "_DEBUG" /D "_WINDOWS" /D "_MBCS" /Yu"stdafx.h" /c
# ADD CPP /nologo /MTd /W3 /Gm /GR /Zi /Od /D "WIN32" /D "_DEBUG" /D "_WINDOWS" /Yu"stdafx.h" /FD /c
# ADD BASE MTL /nologo /D "_DEBUG" /win32
# ADD MTL /nologo /D "_DEBUG" /mktyplib203 /win32
# ADD BASE RSC /l 0x409 /d "_DEBUG"
# ADD RSC /l 0x409 /d "_DEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LINK32=link.exe
# ADD BASE LINK32 /nologo /subsystem:windows /debug /machine:I386
# ADD LINK32 /nologo /subsystem:windows /pdb:none /debug /machine:I386

!ENDIF 

# Begin Target

# Name "Xonix32 - Win32 Release"
# Name "Xonix32 - Win32 Debug"
# Begin Group "Source Files"

# PROP Default_Filter "cpp;c;cxx;rc;def;r;odl;hpj;bat;for;f90"
# Begin Source File

SOURCE=.\src\DibSection.cpp
# End Source File
# Begin Source File

SOURCE=.\src\Game.cpp
# End Source File
# Begin Source File

SOURCE=.\src\GameApp.cpp
# End Source File
# Begin Source File

SOURCE=.\src\GameDlg.cpp
# End Source File
# Begin Source File

SOURCE=.\src\GameRes.rc

!IF  "$(CFG)" == "Xonix32 - Win32 Release"

# ADD BASE RSC /l 0x409 /i "src"
# ADD RSC /l 0x409 /i "src" /i ".\src"

!ELSEIF  "$(CFG)" == "Xonix32 - Win32 Debug"

# ADD BASE RSC /l 0x409 /i "src"
# ADD RSC /l 0x409 /i "src" /i ".\src"

!ENDIF 

# End Source File
# Begin Source File

SOURCE=.\src\GameWnd.cpp
# End Source File
# Begin Source File

SOURCE=.\src\HiScoreTbl.cpp
# End Source File
# Begin Source File

SOURCE=.\src\Objects.cpp
# End Source File
# Begin Source File

SOURCE=.\src\Screen.cpp
# End Source File
# Begin Source File

SOURCE=.\src\StdAfx.cpp
# ADD CPP /Yc"stdafx.h"
# End Source File
# End Group
# Begin Group "Header Files"

# PROP Default_Filter "h;hpp;hxx;hm;inl;fi;fd"
# Begin Source File

SOURCE=.\src\DibSection.h
# End Source File
# Begin Source File

SOURCE=.\src\Game.h
# End Source File
# Begin Source File

SOURCE=.\src\GameApp.h
# End Source File
# Begin Source File

SOURCE=.\src\GameDlg.h
# End Source File
# Begin Source File

SOURCE=.\src\GameWnd.h
# End Source File
# Begin Source File

SOURCE=.\src\HiScoreTbl.h
# End Source File
# Begin Source File

SOURCE=.\src\macros.h
# End Source File
# Begin Source File

SOURCE=.\src\obj_data.h
# End Source File
# Begin Source File

SOURCE=.\src\Objects.h
# End Source File
# Begin Source File

SOURCE=.\src\palette.h
# End Source File
# Begin Source File

SOURCE=.\src\resource.h
# End Source File
# Begin Source File

SOURCE=.\src\Screen.h
# End Source File
# Begin Source File

SOURCE=.\src\StdAfx.h
# End Source File
# End Group
# Begin Group "Resource Files"

# PROP Default_Filter "ico;cur;bmp;dlg;rc2;rct;bin;cnt;rtf;gif;jpg;jpeg;jpe"
# Begin Source File

SOURCE=.\src\res\GameRes.rc2
# End Source File
# Begin Source File

SOURCE=.\src\res\MainFrame.ico
# End Source File
# Begin Source File

SOURCE=.\src\res\msg_crash.bmp
# End Source File
# Begin Source File

SOURCE=.\src\res\msg_game_over.bmp
# End Source File
# Begin Source File

SOURCE=.\src\res\msg_level_complete.bmp
# End Source File
# Begin Source File

SOURCE=.\src\res\msg_low_time.bmp
# End Source File
# Begin Source File

SOURCE=.\src\res\msg_out_of_time.bmp
# End Source File
# Begin Source File

SOURCE=.\src\res\msg_ready.bmp
# End Source File
# Begin Source File

SOURCE=.\src\res\splash.bmp
# End Source File
# End Group
# Begin Group "Misc Files"

# PROP Default_Filter "txt;cmd;html"
# Begin Source File

SOURCE=.\src\res\colors.pal
# End Source File
# Begin Source File

SOURCE=.\doc\readme.html
# End Source File
# Begin Source File

SOURCE=.\release.cmd
# End Source File
# Begin Source File

SOURCE=.\Xonix32.txt
# End Source File
# End Group
# End Target
# End Project
