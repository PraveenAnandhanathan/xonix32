// The original calls the MSVC CRT rand(), so we reproduce that exact
// generator (seed*214013+2531011, top 15 bits) to keep object placement
// deterministic and faithful to the Win32 build.

class CRand {
  int _seed;

  CRand([int seed = 1]) : _seed = seed & 0xFFFFFFFF;

  set seed(int s) => _seed = s & 0xFFFFFFFF;

  /// rand(): returns 0..32767.
  int next() {
    _seed = (_seed * 214013 + 2531011) & 0xFFFFFFFF;
    return (_seed >> 16) & 0x7FFF;
  }
}
