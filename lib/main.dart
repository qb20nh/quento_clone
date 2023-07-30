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
  late final List<List<Challenge>> challengeSet;

  static const challengesPerDifficulty = 3;

  @override
  void initState() {
    super.initState();

    board = GridBoard.randomFromSize(size: _size);
    allPaths = generateAllPathsForGrid(board);
    challengeSet =
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
                    challenges: challengeSet[i],
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
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).colorScheme.onSurface,
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          board.tiles[i][j].toString(),
                          style: Theme.of(context).textTheme.headlineLarge,
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

class ChallengeProgressDisplay extends StatelessWidget {
  const ChallengeProgressDisplay({
    super.key,
    required this.challenges,
    this.completedChallenges = 0,
  });

  final List<Challenge> challenges;
  final int completedChallenges;

  @override
  Widget build(BuildContext context) {
    final pageController = PageController(initialPage: 1);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox.square(
          dimension: 50,
          child: PageView(
            children: [
              for (var i = 0; i < challenges.length; i++)
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
                        challenges[i].intendedDragSequence.value.toString(),
                        // style: Theme.of(context).textTheme.headlineLarge,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Text(
          '$completedChallenges/${challenges.length}',
        ),
      ],
    );
  }
}
