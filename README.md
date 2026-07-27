# Xonix32

Xonix32 v2.51 — an adaptation of the classic X-Windows game "Xonix" for the
Win32 platform, written by **Shawn A. VanNess** (circa 1997–98) and released
as freeware under the GNU General Public License.

The game was never published on GitHub by its author. This repository is an
import of the original distribution as preserved on the Internet Archive:
<https://archive.org/details/xonix-32>

## Contents

| Path | Description |
| --- | --- |
| `src/` | Original C++/MFC source code (extracted from the bundled `source.zip`) |
| `Xonix32.dsw`, `Xonix32.dsp` | Visual C++ 6.0 workspace and project files |
| `Xonix32.exe` | Original prebuilt Win32 binary from the release |
| `readme.html` | Original game manual (controls, tactics, design notes) |
| `screenshot.html`, `screenshot.gif` | Original screenshot page |
| `HiScores.dat` | Sample high-score table shipped with the release |
| `gnu_license.txt` | GNU General Public License (the game's license) |

## Building

The source targets MFC 5.0 / Visual C++ 6.0 on Windows 95/NT 4.0, but per the
author's notes it should work with MFC 4.0 and higher. Open `Xonix32.dsw` in
Visual C++ 6.0 (or import it into a newer Visual Studio) and build.

## License

GNU General Public License — see [`gnu_license.txt`](gnu_license.txt).
All credit for the game and its source belongs to Shawn A. VanNess.
