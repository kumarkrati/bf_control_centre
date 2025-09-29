import 'dart:math';

const _encodingMatrix = {
  "1": ["A", "h", "m", "鬱"],
  "2": ["P", "Q", "g", "薔"],
  "3": ["#", "H", "S", "薇"],
  "4": ["-", "Z", "+", "齉"],
  "5": ["%", "÷", "/", "挨"],
  "6": ["n", "x", "y", "拶"],
  "7": ["L", "a", "t", "醤"],
  "8": ["_", "U", "V", "油"],
  "9": ["E", "G", "T", "躊"],
  "0": ["W", "v", "Y", "躇"],
};

String encode(String digit) {
  final random = Random();
  final index = random.nextInt(_encodingMatrix[digit]!.length);
  return _encodingMatrix[digit]![index];
}

String? decode(String coded) {
  for (int i = 0; i < 10; i++) {
    final matrix = _encodingMatrix[i.toString()];
    if (matrix == null) {
      return null;
    }
    if (matrix.any((e) => e == coded)) {
      return i.toString();
    }
  }
  return null;
}
