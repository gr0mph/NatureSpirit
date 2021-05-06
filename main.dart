import 'dart:io';

var error = stderr.writeln, parse = int.parse;

String read() {
  String? s = stdin.readLineSync();
  return s == null ? '' : s;
}

void main() {

    int complete = 35;
    bool isComplete = false;

    List inputs;
    int numberOfCells = parse(read()); // 37
    for (int i = 0; i < numberOfCells; i++) {
        inputs = read().split(' ');
        int index = parse(inputs[0]); // 0 is the center cell, the next cells spiral outwards
        int richness = parse(inputs[1]); // 0 if the cell is unusable, 1-3 for usable cells
        int neigh0 = parse(inputs[2]); // the index of the neighbouring cell for each direction
        int neigh1 = parse(inputs[3]);
        int neigh2 = parse(inputs[4]);
        int neigh3 = parse(inputs[5]);
        int neigh4 = parse(inputs[6]);
        int neigh5 = parse(inputs[7]);
    }

    // game loop
    while (true)
    {
        int day = parse(read()); // the game lasts 24 days: 0-23
        int nutrients = parse(read()); // the base score you gain from the next COMPLETE action
        inputs = read().split(' ');
        int mySun = parse(inputs[0]); // your sun points
        int myScore = parse(inputs[1]); // your current score
        inputs = read().split(' ');
        int oppSun = parse(inputs[0]); // opponent's sun points
        int oppScore = parse(inputs[1]); // opponent's score
        int oppIsWaiting = parse(inputs[2]); // whether your opponent is asleep until the next day
        int numberOfTrees = parse(read()); // the current amount of trees
        for (int i = 0; i < numberOfTrees; i++) {
            inputs = read().split(' ');
            error(inputs);
            int cellIndex = parse(inputs[0]); // location of this tree
            int size = parse(inputs[1]); // size of this tree: 0-3
            int isMine = parse(inputs[2]); // 1 if this is your tree

            if( isMine == 1 && mySun >= 4 )
            {
                isComplete = true;
                complete = cellIndex < complete ? cellIndex : complete ;
            }

            int isDormant = parse(inputs[3]); // 1 if this tree is dormant
        }
        int numberOfPossibleActions = parse(read()); // all legal actions
        for (int i = 0; i < numberOfPossibleActions; i++) {
            String possibleAction = read(); // try printing something from here to start with
        }

        // GROW cellIdx | SEED sourceIdx targetIdx | COMPLETE cellIdx | WAIT <message>
        //print('WAIT');

        //  Out
        if( isComplete == true )
        {
            print("COMPLETE ${complete}");
        }
        else
        {
            print("WAIT");
        }

        //  Reset
        isComplete = false;
        complete = 35;
    }
}
