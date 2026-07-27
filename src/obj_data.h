
// This file is included only in Objects.cpp...  It is stored 
// separately because it is ugly.

// These are the 8bpp color values for the objects.
// The values are indices into the 256-color palette 
// defined in "palette.h". A value of "255" indicates 
// transparency.

BYTE g_cGuy[] = 
{
  8,  8,  8,255,  8,  8,  8,
  8,  8,  8,255,  8,  8,  8,
  8,  8,255,255,255,  8,  8,
255,255,255,255,255,255,255,
  8,  8,255,255,255,  8,  8,
  8,  8,  8,255,  8,  8,  8,
  8,  8,  8,255,  8,  8,  8,
};

BYTE g_cBDot[] = 
{
255,255,  2,  0,  2,255,255,
255,  2,  0,  0,  0,  2,255,
  2,  0,  0,  0,  0,  0,  2,
  0,  0,  0,  0,  0,  0,  0,
  2,  0,  0,  0,  0,  0,  2,
255,  2,  0,  0,  0,  2,255,
255,255,  2,  0,  2,255,255,
};

BYTE g_cWDot[] = 
{
255,255,255,  8,255,255,255,
255,255,  8,  8,  8,255,255,
255,  8,  8,  8,  8,  8,255,
  8,  8,  8,  8,  8,  8,  8,
255,  8,  8,  8,  8,  8,255,
255,255,  8,  8,  8,255,255,
255,255,255,  8,255,255,255,
};
