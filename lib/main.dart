import 'package:flutter/material.dart';
import 'package:quento_clone/data.dart';

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

  final board = GridBoard.randomFromSize(size: _size);

  late final List<List<Challenge>> challengeSet;

  static const maxRounds = 4;
  static const challengesPerRound = 3;

  @override
  void initState() {
    super.initState();

    print(board.toString());

    challengeSet = _createChallengeSet(board, maxRounds, challengesPerRound);
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
                for (var i = 0; i < maxRounds; i++)
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

  static List<List<Challenge>> _createChallengeSet(
      GridBoard board, int rounds, int challengesPerRound) {
    final challengeSet = <List<Challenge>>[];
    for (var i = 0; i < rounds; i++) {
      final challenges = <Challenge>[];
      for (var j = 0; j < challengesPerRound; j++) {
        challenges.add(Challenge.randomFromBoard(board: board, difficulty: i));
      }
      challengeSet.add(challenges);
    }
    return challengeSet;
  }
}

class ChallengeProgressDisplay extends StatelessWidget {
  const ChallengeProgressDisplay({
    super.key,
    required this.challenges,
    this.completedChallenge = 0,
  });

  final List<Challenge> challenges;
  final int completedChallenge;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < challenges.length; i++)
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.onSurface,
                width: 1,
              ),
            ),
            child: Center(
              child: Badge(
                label:
                    Text(challenges[i].intendedDragSequence.value.toString()),
                child: Text(
                  challenges[i].intendedDragSequence.toString(),
                  // style: Theme.of(context).textTheme.headlineLarge,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
