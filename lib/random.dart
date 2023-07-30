import 'dart:math';

final globalRandom = Random(DateTime.now().millisecondsSinceEpoch);

int randomFromRange(int min, int max) {
  return globalRandom.nextInt(max - min + 1) + min;
}

List<int> pickUniqueRandomNumbers(int count, int min, int max) {
  // Generate unique random numbers.
  // For every number picked, the range of the next number is reduced by 1.
  // When the new number is already picked, increase the number until there is
  // no collision.

  // First, check if the range is large enough.
  if (max - min + 1 < count) {
    throw ArgumentError(
        'The range [$min, $max] is too small to generate $count numbers.');
  }
  final numbers = <int>[];
  for (var i = 0; i < count; i++) {
    var number = randomFromRange(min, max - i);
    while (numbers.contains(number)) {
      number = number == max ? min : number + 1;
    }
    numbers.add(number);
  }
  return numbers;
}

List<int> generateDispersedRandomNumbers(int N) {
  final half = (N + 1) ~/ 2;
  final count = half * 4 ~/ 10;
  final odds = pickUniqueRandomNumbers(count, 1, half).map((n) => n * 2 - 1);
  final evens = pickUniqueRandomNumbers(count, 1, N ~/ 2).map((n) => n * 2);
  final oddsAndEvens = [...odds, ...evens];
  final restCount = half - count * 2;
  final rest = <int>[];
  for (var i = 0; i < restCount; i++) {
    var restNumber = randomFromRange(1, N);
    while (oddsAndEvens.contains(restNumber)) {
      restNumber = restNumber == N ? 1 : restNumber + 1;
    }
    rest.add(restNumber);
  }
  final allNumbers = [...oddsAndEvens, ...rest];
  int getCurrentDispersion() {
    return allNumbers.reduce(max) - allNumbers.reduce(min);
  }

  final targetDispersion = N * 2 ~/ 3;
  while (getCurrentDispersion() < targetDispersion) {
    // Expand the dispersion.
    // 1 <= min <= max <= N
    // we need to pick a number between min and max non-inclusive, and move it
    // to the left of min or right of max.

    final minimum = allNumbers.reduce(min);
    final maximum = allNumbers.reduce(max);

    // Pick a random number to move.
    final index = randomFromRange(1, allNumbers.length - 2);
    // Pick a random number to replace it with.
    // The range is given by [1, min - 1] or [max + 1, N].
    var newNumber = randomFromRange(1, minimum - 1 + N - maximum);
    if (newNumber < minimum) {
      // Move to the left of min.
      while (allNumbers.contains(newNumber)) {
        newNumber -= 1;
      }
      if (newNumber >= 1) {
        allNumbers[index] = newNumber;
      }
    } else {
      // Move to the right of max.
      while (allNumbers.contains(newNumber + maximum - minimum + 1)) {
        newNumber += 1;
      }
      if (newNumber + maximum - minimum + 1 <= N) {
        allNumbers[index] = newNumber + maximum - minimum + 1;
      }
    }
  }
  return allNumbers..shuffle(globalRandom);
}
