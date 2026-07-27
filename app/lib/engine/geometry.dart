// Minimal integer rectangle mirroring the CRect semantics the original
// code relies on (left/top inclusive, right/bottom exclusive).

class IntRect {
  int left, top, right, bottom;

  IntRect(this.left, this.top, this.right, this.bottom);

  IntRect.copy(IntRect o) : this(o.left, o.top, o.right, o.bottom);

  int get width => right - left;
  int get height => bottom - top;

  void setRect(int l, int t, int r, int b) {
    left = l;
    top = t;
    right = r;
    bottom = b;
  }

  void deflate(int dx, int dy) {
    left += dx;
    top += dy;
    right -= dx;
    bottom -= dy;
  }

  void offset(int dx, int dy) {
    left += dx;
    right += dx;
    top += dy;
    bottom += dy;
  }

  void normalize() {
    if (right < left) {
      final t = left;
      left = right;
      right = t;
    }
    if (bottom < top) {
      final t = top;
      top = bottom;
      bottom = t;
    }
  }

  @override
  String toString() => 'IntRect($left,$top,$right,$bottom)';
}
