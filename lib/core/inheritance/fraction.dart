/// An exact, always-reduced fraction with a positive denominator.
class Fraction implements Comparable<Fraction> {
  final int num;
  final int den;

  const Fraction._(this.num, this.den);

  factory Fraction(int num, [int den = 1]) {
    if (den == 0) throw ArgumentError('zero denominator');
    if (den < 0) {
      num = -num;
      den = -den;
    }
    final g = _gcd(num.abs(), den);
    return Fraction._(num ~/ g, den ~/ g);
  }

  static const zero = Fraction._(0, 1);
  static const one = Fraction._(1, 1);

  static int _gcd(int a, int b) {
    while (b != 0) {
      final t = a % b;
      a = b;
      b = t;
    }
    return a == 0 ? 1 : a;
  }

  static int lcm(int a, int b) => a ~/ _gcd(a, b) * b;

  Fraction operator +(Fraction o) =>
      Fraction(num * o.den + o.num * den, den * o.den);
  Fraction operator -(Fraction o) =>
      Fraction(num * o.den - o.num * den, den * o.den);
  Fraction operator *(Fraction o) => Fraction(num * o.num, den * o.den);
  Fraction operator /(Fraction o) => Fraction(num * o.den, den * o.num);
  Fraction times(int n) => Fraction(num * n, den);
  Fraction over(int n) => Fraction(num, den * n);

  bool get isZero => num == 0;
  bool get isPositive => num > 0;
  double get value => num / den;

  @override
  int compareTo(Fraction other) => (num * other.den).compareTo(other.num * den);
  bool operator >(Fraction o) => compareTo(o) > 0;
  bool operator <(Fraction o) => compareTo(o) < 0;

  @override
  bool operator ==(Object other) =>
      other is Fraction && other.num == num && other.den == den;

  @override
  int get hashCode => Object.hash(num, den);

  @override
  String toString() => den == 1 ? '$num' : '$num/$den';
}
