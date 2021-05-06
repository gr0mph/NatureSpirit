import 'dart:io';
import 'dart:math';

String readLineSync() {
  String? s = stdin.readLineSync();
  return s == null ? '' : s;
}

/**
 * Auto-generated code below aims at helping you parse
 * the standard input according to the problem statement.
 **/
void main() {
    List inputs;
    int numberOfCells = int.parse(readLineSync()); // 37
    for (int i = 0; i < numberOfCells; i++) {
        inputs = readLineSync().split(' ');
        int index = int.parse(inputs[0]); // 0 is the center cell, the next cells spiral outwards
        int richness = int.parse(inputs[1]); // 0 if the cell is unusable, 1-3 for usable cells
        int neigh0 = int.parse(inputs[2]); // the index of the neighbouring cell for each direction
        int neigh1 = int.parse(inputs[3]);
        int neigh2 = int.parse(inputs[4]);
        int neigh3 = int.parse(inputs[5]);
        int neigh4 = int.parse(inputs[6]);
        int neigh5 = int.parse(inputs[7]);
    }

    // game loop
    while (true) {
        int day = int.parse(readLineSync()); // the game lasts 24 days: 0-23
        int nutrients = int.parse(readLineSync()); // the base score you gain from the next COMPLETE action
        inputs = readLineSync().split(' ');
        int sun = int.parse(inputs[0]); // your sun points
        int score = int.parse(inputs[1]); // your current score
        inputs = readLineSync().split(' ');
        int oppSun = int.parse(inputs[0]); // opponent's sun points
        int oppScore = int.parse(inputs[1]); // opponent's score
        int oppIsWaiting = int.parse(inputs[2]); // whether your opponent is asleep until the next day
        int numberOfTrees = int.parse(readLineSync()); // the current amount of trees
        for (int i = 0; i < numberOfTrees; i++) {
            inputs = readLineSync().split(' ');
            int cellIndex = int.parse(inputs[0]); // location of this tree
            int size = int.parse(inputs[1]); // size of this tree: 0-3
            int isMine = int.parse(inputs[2]); // 1 if this is your tree
            int isDormant = int.parse(inputs[3]); // 1 if this tree is dormant
        }
        int numberOfPossibleActions = int.parse(readLineSync()); // all legal actions
        for (int i = 0; i < numberOfPossibleActions; i++) {
            String possibleAction = readLineSync(); // try printing something from here to start with
        }

        // Write an action using print()
        // To debug: stderr.writeln('Debug messages...');


        // GROW cellIdx | SEED sourceIdx targetIdx | COMPLETE cellIdx | WAIT <message>
        print('WAIT');
    }
}
