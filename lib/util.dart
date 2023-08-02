import 'dart:collection';

import 'package:quento_clone/data.dart';
import 'package:quento_clone/random.dart';

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

List<ChallengeSet> createChallengeSetFromPaths(
    Map<Difficulty, Map<int, Set<TileSequence>>> allPaths,
    int challengesPerDifficulty) {
  final challengeSet = <ChallengeSet>[];
  for (final MapEntry(key: difficulty, value: pathsByValue)
      in allPaths.entries) {
    final challenges = <Challenge>[];
    final valueIndex = pickUniqueRandomNumbers(
        challengesPerDifficulty, 0, pathsByValue.length - 1);
    valueIndex.map((index) {
      final paths = pathsByValue.values.elementAt(index);
      final pathIndex = randomFromRange(0, paths.length - 1);
      final path = paths.elementAt(pathIndex);
      return Challenge(difficulty: difficulty, intendedDragSequence: path);
    }).forEach((challenge) {
      challenges.add(challenge);
    });
    challengeSet.add(ChallengeSet(challenges: challenges));
  }
  return challengeSet;
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
      // TODO: Make this function return just lists of int2.
      // and then call it multiple times with different starting position
      // depending on the board state
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

Map<Difficulty, Map<int, Set<TileSequence>>> generateAllPathsForGrid(
    GridBoard board) {
  final pathsByDifficulty = <Difficulty, Map<int, Set<TileSequence>>>{};
  for (final difficulty in Difficulty.values) {
    final paths =
        generateAllPathShapes(board.size, difficulty.targetSequenceLength);
    final tileSequencesByValue = SplayTreeMap<int, Set<TileSequence>>();
    for (final p in paths) {
      final ts = pathShapeToTileSequence(board, p);
      if (ts.value < 0) {
        continue;
      }
      tileSequencesByValue
          .putIfAbsent(ts.value, () => <TileSequence>{})
          .add(ts);
    }
    pathsByDifficulty[difficulty] = tileSequencesByValue;
  }
  return pathsByDifficulty;
}
