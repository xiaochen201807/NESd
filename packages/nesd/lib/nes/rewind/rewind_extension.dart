import 'dart:math';

extension IntListRewindExtension on List<int> {
  List<int> compress() => this;

  List<int> decompress() => this;

  @pragma('vm:prefer-inline')
  List<int> diff(List<int> other) {
    final diffLength = min(length, other.length);

    for (var i = 0; i < diffLength; i++) {
      this[i] ^= other[i];
    }

    return this;
  }
}
