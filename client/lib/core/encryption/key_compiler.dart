import 'matrix.dart' as EncodingMatrix;

List<List<String>> _shuffle(String input) {
  var result = <List<String>>[];
  var original = input.split("");
  var spilled = [...original]..shuffle();
  for (int i = 0; i < original.length; i++) {
    var element = spilled[i];
    var indexInOriginal = original.indexOf(element);
    original[indexInOriginal] = "-";
    result.add([element, indexInOriginal.toString()]);
  }
  return result;
}

MapEntry<String, String> createKey() {
  // current timestamp
  int time = DateTime.now().microsecondsSinceEpoch;
  // shuffle
  List<List<String>> randomSeq = _shuffle(time.toString());
  String ore = "";
  for (final entry in randomSeq) {
    ore += "${entry[0]}(${entry[1]})";
  }
  // now let's use the ore to make the key
  String key = "";
  for (int i = 0; i < ore.length; i++) {
    final char = ore[i];
    if (char == '(' || char == ')') {
      key += char;
      continue;
    }
    key += EncodingMatrix.encode(ore[i]);
  }
  return MapEntry(time.toString(), key);
}
