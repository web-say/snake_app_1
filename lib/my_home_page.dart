import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'blank_pixel.dart';
import 'food_pixel.dart';
import 'snake_pixel.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

enum snakeDirection { UP, DOWN, LEFT, RIGHT }

class _MyHomePageState extends State<MyHomePage> {
  // Grid
  int rowCount = 10;
  int totalNumberOfSquares = 100;

  // Stareted Game
  bool gameHasStarted = false;

  // User score
  int currentScore = 0;

  // Save
  late SharedPreferences _prefs;
  int records = 0;
  static const kRecordsKey = 'records';

  @override
  void initState() {
    super.initState();
    _initialDatabase();
  }

  void _initialDatabase() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      records = _prefs.getInt(kRecordsKey) ?? 0;
    });
  }

  // Snake
  List<int> snakePos = [0, 1, 2];

  // Snake direction
  var currentDirection = snakeDirection.RIGHT;

  // Food
  int foodPos = 55;

  //Start Game
  void startGame() {
    gameHasStarted = true;
    Timer.periodic(const Duration(milliseconds: 200), (timer) {
      setState(() {
        // move Snake
        moveSnake();

        if (gameOver()) {
          timer.cancel();
          // Dialog
          showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) {
                return AlertDialog(
                  title: const Text('Game over'),
                  content: Column(
                    children: [
                      Text('Your score is: ${currentScore.toString()}'),
                      const TextField(
                        decoration: InputDecoration(hintText: 'Enter name'),
                      ),
                    ],
                  ),
                  actions: [
                    MaterialButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await submitScore();
                        newGame();
                      },
                      child: Text('Submit'),
                      color: Colors.red,
                    ),
                  ],
                );
              });
        }
      });
    });
  }

  // Save score
  submitScore() async {
    if (records < currentScore) {
      setState(() {
        records = currentScore;
      });

      await _prefs.setInt(kRecordsKey, currentScore);
    }
  }

  // Save score
  void newGame() {
    setState(() {
      snakePos = [0, 1, 2];
      foodPos = 55;
      currentDirection = snakeDirection.RIGHT;
      gameHasStarted = false;
      currentScore = 0;
    });
  }

  void eatFoot() {
    currentScore++;
    // Next Food
    while (snakePos.contains(foodPos)) {
      foodPos = Random().nextInt(totalNumberOfSquares);
    }
  }

  // Game Over
  bool gameOver() {
    // Body snake no head
    List<int> bodySnake = snakePos.sublist(0, snakePos.length - 1);
    if (bodySnake.contains(snakePos.last)) {
      return true;
    }
    return false;
  }

  void moveSnake() {
    switch (currentDirection) {
      case snakeDirection.RIGHT:
        {
          // add new head
          if (snakePos.last % rowCount == 9) {
            snakePos.add(snakePos.last + 1 - rowCount);
          } else {
            snakePos.add(snakePos.last + 1);
          }
        }
        break;
      case snakeDirection.LEFT:
        {
          // add new head
          if (snakePos.last % rowCount == 0) {
            snakePos.add(snakePos.last - 1 + rowCount);
          } else {
            snakePos.add(snakePos.last - 1);
          }
        }
        break;
      case snakeDirection.UP:
        {
          // add new head
          if (snakePos.last < rowCount) {
            snakePos.add(snakePos.last - rowCount + totalNumberOfSquares);
          } else {
            snakePos.add(snakePos.last - rowCount);
          }
        }
        break;
      case snakeDirection.DOWN:
        {
          // add new head
          if (snakePos.last + rowCount > totalNumberOfSquares) {
            snakePos.add(snakePos.last + rowCount - totalNumberOfSquares);
          } else {
            snakePos.add(snakePos.last + rowCount);
          }
        }
        break;
    }

    if (snakePos.last == foodPos) {
      eatFoot();
    } else {
      // remove the tail
      snakePos.removeAt(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: RawKeyboardListener(
          focusNode: FocusNode(),
          autofocus: true,
          onKey: (event) {
            if (event.isKeyPressed(LogicalKeyboardKey.arrowDown)) {
              currentDirection = snakeDirection.DOWN;
            } else if (event.isKeyPressed(LogicalKeyboardKey.arrowUp)) {
              currentDirection = snakeDirection.UP;
            } else if (event.isKeyPressed(LogicalKeyboardKey.arrowLeft)) {
              currentDirection = snakeDirection.LEFT;
            } else if (event.isKeyPressed(LogicalKeyboardKey.arrowRight)) {
              currentDirection = snakeDirection.RIGHT;
            }
          },
          child: SizedBox(
            width: screenWidth > 428 ? 428 : screenWidth,
            child: Column(
              children: [
                Expanded(
                    flex: 1,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('CURRENT SCORE'),
                            Text(
                              currentScore.toString(),
                              style: const TextStyle(fontSize: 28),
                            )
                          ],
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('MAXIMUM SCORE'),
                            SizedBox(
                              child: Center(
                                child: Text(
                                  records.toString(),
                                  style: const TextStyle(fontSize: 40),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    )),
                Expanded(
                    flex: 4,
                    child: GestureDetector(
                      onVerticalDragUpdate: (details) {
                        if (details.delta.dy > 0 &&
                            currentDirection != snakeDirection.UP) {
                          currentDirection = snakeDirection.DOWN;
                        } else if (details.delta.dy < 0 &&
                            currentDirection != snakeDirection.DOWN) {
                          currentDirection = snakeDirection.UP;
                        }
                      },
                      onHorizontalDragUpdate: (details) {
                        if (details.delta.dx > 0 &&
                            currentDirection != snakeDirection.LEFT) {
                          currentDirection = snakeDirection.RIGHT;
                        } else if (details.delta.dx < 0 &&
                            currentDirection != snakeDirection.RIGHT) {
                          currentDirection = snakeDirection.LEFT;
                        }
                      },
                      child: GridView.builder(
                        itemCount: totalNumberOfSquares,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: rowCount),
                        itemBuilder: (context, index) {
                          if (snakePos.contains(index)) {
                            return const SnakePixel();
                          } else if (foodPos == index) {
                            return const FoodPixel();
                          } else {
                            return const BlankPixel();
                          }
                        },
                      ),
                    )),
                Expanded(
                    flex: 1,
                    child: Container(
                      child: Center(
                        child: MaterialButton(
                          child: Text('Play'),
                          color: gameHasStarted ? Colors.grey : Colors.red,
                          onPressed: gameHasStarted ? () {} : startGame,
                        ),
                      ),
                    )),
              ],
            ),
          ),
        ),
      ),
      // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
