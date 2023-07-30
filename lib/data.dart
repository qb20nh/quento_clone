// ignore: camel_case_types
import 'package:meta/meta.dart';
import 'package:quento_clone/random.dart';

typedef int2 = (int, int);

abstract class Board<T> {
  const Board({required this.size});

  final int2 size;

  T tileAt(int2 pos);

  @override
  String toString() {
    final buffer = StringBuffer();
    for (var row = 0; row < size.$1; row++) {
      for (var col = 0; col < size.$2; col++) {
        buffer.write(tileAt((row, col)).toString());
        buffer.write(' ');
      }
      buffer.write('\n');
    }
    return buffer.toString();
  }
}

class GridBoard extends Board<Tile> {
  const GridBoard({
    required super.size,
    required this.tiles,
  });

  final List<List<Tile>> tiles;

  factory GridBoard.randomFromSize({required int2 size}) {
    final numberTileValues = generateDispersedRandomNumbers(size.$1 * size.$2);
    // Generate the tiles array, filling in the number tiles where the sum of x
    // and y is even, and the operator tiles otherwise.
    // The operator tiles' operations is decided with x coordinate modulo 2.
    final tiles = List.generate(
      size.$1,
      (row) => List.generate(
        size.$2,
        (col) => (row + col) % 2 == 0
            ? NumberTile(
                value: numberTileValues.removeLast(),
                pos: (row, col),
              )
            : OperatorTile(
                operator:
                    row % 2 == 0 ? Operator.addition : Operator.subtraction,
                pos: (row, col),
              ),
      ),
    );
    return GridBoard(
      size: size,
      tiles: tiles,
    );
  }

  @override
  Tile tileAt(int2 pos) {
    return tiles[pos.$1][pos.$2];
  }
}

abstract class Tile {
  const Tile({required TileType type, required this.pos});

  final int2 pos;

  @override
  @mustBeOverridden
  String toString();
}

enum TileType {
  number,
  operator,
}

class NumberTile extends Tile {
  const NumberTile({required this.value, required super.pos})
      : super(type: TileType.number);

  final int value;

  @override
  String toString() {
    return value.toString();
  }
}

class OperatorTile extends Tile {
  const OperatorTile({required this.operator, required super.pos})
      : super(type: TileType.operator);

  final Operator operator;

  @override
  String toString() {
    return operator.symbol;
  }
}

class Operator {
  const Operator({
    required this.symbol,
    required this.operation,
  });

  final String symbol;
  final int Function(int, int) operation;

  static int _add(int a, int b) => a + b;
  static int _subtract(int a, int b) => a - b;

  static const addition = Operator(
    symbol: '+',
    operation: _add,
  );
  static const subtraction = Operator(
    symbol: '-',
    operation: _subtract,
  );
}

abstract class Cloneable<T extends Cloneable<T>> {
  T copy();
}

class TileSequence extends Iterable<Tile> implements Cloneable<TileSequence> {
  const TileSequence.unmodifiable({this.tiles = const []});
  TileSequence() : tiles = [];
  TileSequence.fromTiles({required this.tiles});

  final List<Tile> tiles;

  int get value {
    int acc = 0;
    Operator lastOperator = Operator.addition;
    for (var i = 0; i < tiles.length; i++) {
      final tile = tiles[i];
      if (tile is NumberTile) {
        acc = lastOperator.operation(acc, tile.value);
      } else if (tile is OperatorTile) {
        lastOperator = tile.operator;
      }
    }
    return acc;
  }

  void add(Tile newTile) {
    Tile? lastTile = tiles.lastOrNull;
    if ((newTile is NumberTile && (lastTile is OperatorTile?)) ||
        (newTile is OperatorTile && lastTile is NumberTile?)) {
      tiles.add(newTile);
    } else {
      throw UnsupportedError(
          'The type of the new tile is either unsupported or unexpected.');
    }
  }

  void removeLast() {
    tiles.removeLast();
  }

  @override
  String toString() {
    return tiles.map((tile) => tile.toString()).join('');
  }

  @override
  Iterator<Tile> get iterator {
    return tiles.iterator;
  }

  @override
  TileSequence copy() {
    return TileSequence.fromTiles(tiles: [...tiles]);
  }
}

class Challenge {
  const Challenge({
    required this.difficulty,
    required this.intendedDragSequence,
  }) : assert(difficulty >= 0);

  factory Challenge.randomFromBoard({
    required GridBoard board,
    required int difficulty,
  }) {
    final targetSequenceLength = 2 * difficulty + 3;

    // Pick a random number tile to start the sequence.
    final firstTile = board.tiles
        .expand((row) => row)
        .whereType<NumberTile>()
        .elementAt(globalRandom.nextInt(board.tiles.length));

    bool isInsideBoard(int2 pos, TileSequence currentSequence) {
      return pos.$1 >= 0 &&
          pos.$1 < board.size.$1 &&
          pos.$2 >= 0 &&
          pos.$2 < board.size.$2;
    }

    bool isNotInSequence(int2 pos, TileSequence currentSequence) {
      return !currentSequence.tiles.contains(board.tiles[pos.$1][pos.$2]);
    }

    TileSequence? findRandomPath(
      TileSequence currentSequence,
      int targetLength,
      List<bool Function(int2 nextPos, TileSequence currentSequence)> criteria,
    ) {
      if (currentSequence.tiles.length == targetLength) {
        return currentSequence;
      }

      final directions = [
        (0, 1),
        (0, -1),
        (1, 0),
        (-1, 0),
      ]..shuffle(globalRandom);

      for (final dir in directions) {
        final nextPos = (
          currentSequence.tiles.last.pos.$1 + dir.$1,
          currentSequence.tiles.last.pos.$2 + dir.$2,
        );

        if (criteria.any((criterion) => !criterion(nextPos, currentSequence))) {
          continue;
        }

        final nextSequence = TileSequence.fromTiles(
          tiles: [...currentSequence, board.tiles[nextPos.$1][nextPos.$2]],
        );

        final result = findRandomPath(nextSequence, targetLength, criteria);

        if (result != null) {
          return result;
        }
      }

      return null;
    }

    TileSequence? found = findRandomPath(
      TileSequence.fromTiles(tiles: [firstTile]),
      targetSequenceLength,
      [
        isInsideBoard,
        isNotInSequence,
      ],
    );
    if (found == null) {
      throw StateError(
          'No valid tile sequence has been found for length $targetSequenceLength');
    }

    if (found.value <= 0) {
      // Reverse the tile sequence to make the value positive.
      found = TileSequence.fromTiles(
        tiles: found.tiles.reversed.toList(),
      );
    }

    return Challenge(
      difficulty: difficulty,
      intendedDragSequence: found,
    );
  }

  final int difficulty;
  final TileSequence intendedDragSequence;
  int get value => intendedDragSequence.value;
}
