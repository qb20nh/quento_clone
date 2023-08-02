import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:quento_clone/data.dart';
import 'package:quento_clone/util.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Quento Clone'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const _size = (3, 3);

  late final GridBoard board;
  late final Map<Difficulty, Map<int, Set<TileSequence>>> allPaths;
  late final List<ChallengeSet> challengeSets;

  static const challengesPerDifficulty = 3;

  final currentUserTileSequence = <int2>[];

  bool _isAdjacent(int2 lastTileTapped, int2 index) {
    final (x1, y1) = lastTileTapped;
    final (x2, y2) = index;
    return (x1 - x2).abs() + (y1 - y2).abs() == 1;
  }

  void onTileTapped(int2 index) {
    final lastTileTapped = currentUserTileSequence.lastOrNull;
    if (lastTileTapped == index) {
      currentUserTileSequence.removeLast();
      onUserTileChanged();
    } else if (currentUserTileSequence.contains(index)) {
      return;
    } else if (lastTileTapped == null || _isAdjacent(lastTileTapped, index)) {
      currentUserTileSequence.add(index);
      onUserTileChanged();
    } else {
      currentUserTileSequence.clear();
      onUserTileChanged();
    }
  }

  void onUserTileChanged() {
    final TileSequence userTileSequence = TileSequence.fromTiles(tiles: [
      for (final index in currentUserTileSequence)
        board.tiles[index.$1][index.$2]
    ]);
    for (final (i, challenge)
        in challengeSets.map((cs) => cs.firstUncompleted).indexed) {
      if (challenge == null) {
        // Challenge set completed.
        continue;
      }
      if (challenge.intendedDragSequence.length == userTileSequence.length &&
          challenge.intendedDragSequence.value == userTileSequence.value) {
        // Challenge completed.
        final challengeSetToAdvance = challengeSets[i];
        challengeSets[i] = ChallengeSet(
          challenges: challengeSetToAdvance.challenges,
          completedChallengeCount:
              challengeSetToAdvance.completedChallengeCount + 1,
        );
        currentUserTileSequence.clear();
      }
    }
    setState(() {
      // Rebuild the UI.
    });
  }

  @override
  void initState() {
    super.initState();

    board = GridBoard.randomFromSize(size: _size);
    allPaths = generateAllPathsForGrid(board);
    challengeSets =
        createChallengeSetFromPaths(allPaths, challengesPerDifficulty);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < allPaths.length; i++)
                  ChallengeProgressDisplay(
                    challengeSet: challengeSets[i],
                  ),
              ],
            ),
            const SizedBox.square(
              dimension: 100,
            ),
            GridView.count(
              crossAxisCount: _size.$2,
              shrinkWrap: true,
              children: [
                for (var i = 0; i < _size.$1; i++)
                  for (var j = 0; j < _size.$2; j++)
                    GestureDetector(
                      onTap: () => onTileTapped((i, j)),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).colorScheme.onSurface,
                            width: currentUserTileSequence.contains((i, j))
                                ? 3
                                : 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            board.tiles[i][j].toString(),
                            style: Theme.of(context).textTheme.headlineLarge,
                          ),
                        ),
                      ),
                    ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ChallengeProgressDisplay extends StatefulWidget {
  const ChallengeProgressDisplay({
    super.key,
    required this.challengeSet,
  });

  final ChallengeSet challengeSet;

  @override
  State<StatefulWidget> createState() => ChallengeProgressDisplayState();
}

class ChallengeProgressDisplayState extends State<ChallengeProgressDisplay> {
  final PageController pageController = PageController();
  late int lastCompletedChallengeCount =
      widget.challengeSet.completedChallengeCount;

  @override
  Widget build(BuildContext context) {
    final completedChallengeCount = widget.challengeSet.completedChallengeCount;
    if (completedChallengeCount > lastCompletedChallengeCount) {
      pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      lastCompletedChallengeCount = completedChallengeCount;
    }

    return GestureDetector(
      onTap: () {
        if (kDebugMode) {
          print(widget.challengeSet.firstUncompleted?.intendedDragSequence
                  .toString() ??
              'No more challenges');
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox.square(
            dimension: 50,
            child: PageView(
              physics: const NeverScrollableScrollPhysics(),
              controller: pageController,
              children: [
                for (var i = 0; i < widget.challengeSet.length; i++)
                  SizedBox.square(
                    dimension: 50,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).colorScheme.onSurface,
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          widget.challengeSet.challenges[i].intendedDragSequence
                              .value
                              .toString(),
                          // style: Theme.of(context).textTheme.headlineLarge,
                        ),
                      ),
                    ),
                  ),
                Icon(
                  Icons.thumb_up,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ],
            ),
          ),
          Text(
            '${widget.challengeSet.completedChallengeCount}/${widget.challengeSet.length}',
          ),
        ],
      ),
    );
  }
}
