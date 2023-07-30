import 'dart:collection';

import 'package:quento_clone/data.dart';

T tryCatch<R, E extends Error, T>(
  R Function() unsafeAction,
  T Function(R result) whenComplete,
  T Function(E error) whenError,
) {
  try {
    R result = unsafeAction();
    return whenComplete(result);
  } on E catch (e) {
    return whenError(e);
  }
}

// Generate all paths shapes for a given size limit and length.
// The size limit is the entire width and height of the space this path spans.
// The length is the number of cells this path consists of.
// The path must be connected, and must not intersect itself.
List<List<int2>> generateAllPathShapes(int2 maxSize, int length) {
  List<List<int2>> foundPaths = [];

  void search(List<int2> currentPath) {
    if (currentPath.length == length) {
      foundPaths.add(currentPath.toList());
      return;
    }

    const directions = [
      (0, 1),
      (0, -1),
      (1, 0),
      (-1, 0),
    ];

    final current = currentPath.last;

    // Try all directions.
    for (final direction in directions) {
      final next = (current.$1 + direction.$1, current.$2 + direction.$2);
      if (next.$1 < 0 ||
          next.$1 >= maxSize.$1 ||
          next.$2 < 0 ||
          next.$2 >= maxSize.$2) {
        continue;
      }
      if (currentPath.contains(next)) {
        continue;
      }
      search([...currentPath, next]);
    }
  }

  for (var i = 0; i < maxSize.$1; i++) {
    for (var j = 0; j < maxSize.$2; j++) {
      if ((i + j).isEven) {
        search([(i, j)]);
      }
    }
  }

  return foundPaths;
}

TileSequence pathShapeToTileSequence(GridBoard board, List<int2> pathShape) {
  final tiles = pathShape.map((p) => board.tileAt(p)).toList();
  return TileSequence.fromTiles(tiles: tiles);
}

void main() {
  final board = GridBoard.randomFromSize(size: (3, 3));
  print(board);
  final paths = generateAllPathShapes(board.size, 5);
  print(paths.length);
  final tileSequences = Map.fromEntries(paths.map((p) {
    final ts = pathShapeToTileSequence(board, p);
    return MapEntry(ts.value, ts);
  }));

  SplayTreeMap tileSequencesByValue = SplayTreeMap<int, List<TileSequence>>();
  for (final ts in tileSequences.values) {
    tileSequencesByValue.putIfAbsent(ts.value, () => <TileSequence>[]).add(ts);
  }

  print(tileSequencesByValue);
}
