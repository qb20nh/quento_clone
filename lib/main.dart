import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

  final tapPositions = <int2>[];

  bool _isAdjacent(int2 lastTileTapped, int2 index) {
    final (x1, y1) = lastTileTapped;
    final (x2, y2) = index;
    return (x1 - x2).abs() + (y1 - y2).abs() == 1;
  }

  void onTileTapped(int2 index) {
    final lastTileTapped = tapPositions.lastOrNull;
    if (lastTileTapped == index) {
      tapPositions.removeLast();
      onUserTileChanged();
    } else if (tapPositions.contains(index)) {
      return;
    } else {
      tapPositions.add(index);
      // Validate inside this function
      onUserTileChanged();
    }
  }

  (bool, TileSequence) isPositionSequenceValid(
      List<int2> positions, bool Function(int2) checker) {
    final invalid = (false, TileSequence.empty);
    if (positions.length == 0) {
      return (true, TileSequence.empty);
    }
    if (positions.length == 1 && checker(positions.first)) {
      return invalid;
    }

    // Check adjacency for consecutive positions
    int2 pos = positions.first;
    for (final next in positions.skip(1)) {
      if (!_isAdjacent(pos, next)) {
        return invalid;
      }
      pos = next;
    }

    return (
      true,
      TileSequence.fromTiles(
        tiles: positions.map((index) => board.tiles[index.$1][index.$2]),
      ),
    );
  }

  void checkForChallengeCompletions(
    List<ChallengeSet> challengeSets,
    TileSequence userTileSequence,
  ) {
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
        print('Challenge completed. Clearing.');
        clearInputPositions();
        break;
      }
    }
  }

  var userInputPositions = <int2>[];
  List<int2> getUserInputPositions() {
    return userInputPositions;
  }

  bool isOperatorTile(int2 pos) {
    return board.tiles[pos.$1][pos.$2] is OperatorTile;
  }

  void onUserTileChanged() {
    final concat = tapPositions + dragPositions;
    final (isValid, userTileSequence) =
        isPositionSequenceValid(concat, isOperatorTile);
    if (isValid) {
      userInputPositions = concat;
      if (!_pointerDown) {
        checkForChallengeCompletions(challengeSets, userTileSequence);
      }
    } else {
      // Invalid sequence. Clear the sequence.
      print('Invalid sequence. Clearing.');
      clearInputPositions();
    }
    setState(() {
      // Rebuild the UI.
    });
  }

  bool _pointerDown = false;
  Offset _dragStart = Offset.infinite;
  Offset _currentDrag = Offset.infinite;

  bool _dragPositionsHadEffect = false;

  void _handleDownOrDrag(PointerEvent event) {
    if (event.down) {
      if (!_pointerDown) {
        _pointerDown = true;
        _dragStart = event.position;
      } else {
        _currentDrag = event.position;
      }
      if (_dragStart != Offset.infinite && _currentDrag != Offset.infinite) {
        // Calculate drag distance
        final dragDistance = (_currentDrag - _dragStart).distance;
        const dragDistanceThreshold = 10;
        if (dragDistance > dragDistanceThreshold) {
          _handleDrag(_currentDrag);
        }
      }
    }
  }

  final key = GlobalKey();
  final dragPositions = <int2>[];

  void _handleDrag(Offset currentDragPosition) {
    final RenderBox? box =
        key.currentContext?.findAncestorRenderObjectOfType<RenderBox>();
    if (box == null) {
      print('Correct type of render box not found, giving up');
      return;
    }
    final result = BoxHitTestResult();
    Offset local = box.globalToLocal(currentDragPosition);
    if (box.hitTest(result, position: local)) {
      for (final hit in result.path) {
        final target = hit.target;
        if (target is _DetectionLimitRenderObject &&
            !dragPositions.contains(target.pos)) {
          dragPositions.add(target.pos);
          onDragTilePositionUpdated();
        }
      }
    }
  }

  void _clearDrag(PointerEvent event) {
    _pointerDown = false;
    if (_dragPositionsHadEffect) {
      _dragPositionsHadEffect = false;
      print('Drag ended. Clearing.');
      onUserTileChanged();
      clearInputPositions();
    }
    _dragStart = Offset.infinite;
    _currentDrag = Offset.infinite;
  }

  void clearInputPositions() {
    tapPositions.clear();
    dragPositions.clear();
    userInputPositions.clear();
  }

  void onDragTilePositionUpdated() {
    print('Drag positions: $dragPositions');
    // If there are already user tapped tiles, append the dragged tiles
    if (dragPositions.isNotEmpty) {
      final concatenated = tapPositions + dragPositions;
      final (isValid, _) =
          isPositionSequenceValid(concatenated, isOperatorTile);
      if (isValid) {
        print('Drag sequcne valid. Updating.');
        _dragPositionsHadEffect = true;
        onUserTileChanged();
      } else {
        // Invalid sequence. Clear the sequence.
        print('Drag sequcne invalid. Clearing.');
        clearInputPositions();
      }
    }
  }

  @override
  void initState() {
    super.initState();

    board = GridBoard.randomFromSize(size: _size);
    allPaths = generateAllPathsForGrid(board);
    challengeSets =
        createChallengeSetFromPaths(allPaths, challengesPerDifficulty);
  }

  bool isSelected(int i, int j) {
    return getUserInputPositions().contains((i, j));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
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
                dimension: 16,
              ),
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Listener(
                      onPointerDown: _handleDownOrDrag,
                      onPointerMove: _handleDownOrDrag,
                      onPointerUp: _clearDrag,
                      child: GridView.count(
                        key: key,
                        crossAxisCount: _size.$2,
                        shrinkWrap: true,
                        children: [
                          for (var i = 0; i < _size.$1; i++)
                            for (var j = 0; j < _size.$2; j++)
                              DetectionLimit(
                                pos: (i, j),
                                child: GestureDetector(
                                  onTap: () => onTileTapped((i, j)),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                        width: isSelected(i, j) ? 3 : 1,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        board.tiles[i][j].toString(),
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineLarge,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DetectionLimit extends SingleChildRenderObjectWidget {
  const DetectionLimit({
    super.key,
    required this.pos,
    required super.child,
  });

  final int2 pos;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _DetectionLimitRenderObject(pos);
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant RenderObject renderObject) {
    (renderObject as _DetectionLimitRenderObject).pos = pos;
  }
}

class _DetectionLimitRenderObject extends RenderProxyBox {
  _DetectionLimitRenderObject(this.pos);

  int2 pos;
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
