import 'dart:io';

var error = stderr.writeln, parse = int.parse;
final int kMINE = 1 , kOPP = 0;

String read() {
  String? s = stdin.readLineSync();
  return s == null ? '' : s;
}

class Cell {

    late int index, richness;
    late List<int> neighboor;

    Cell( {required List<String> inputs} ) {
        this.index = parse(inputs[0]);
        this.richness = parse(inputs[1]);
        this.neighboor = List.generate( 6 , (i) => parse(inputs[i+2]) , growable : false );
    }

    @override
    String toString() {
        return "cell [${this.index}] ${this.richness} ${this.neighboor}";
    }

}

class Tree {

    late int index, size , isMine , isDormant;

    Tree( {required List<String> inputs } )
    {
        this.index = parse(inputs[0]);
        this.size = parse(inputs[1]);
        this.isMine = parse(inputs[2]);
        this.isDormant = parse(inputs[3]);
    }

    String seed( int index ) => "SEED ${this.index} $index";
    String grow( ) => "GROW ${this.index}";
    String complete( ) => "COMPLETE ${this.index}";

    @override
    String toString() {
        return "tree [${this.index}] ${this.size} ${this.isMine} ${this.isDormant}";
    }
}

class Agent {
    int sun , score , asleep;
    List<Tree> tree ;

    Agent( {required List<Tree> tree} ) :
    this.tree = tree , this.sun = 0 , this.score = 0 , this.asleep = 0;

    @override
    String toString() {
        return "agent ${this.sun}/${this.score} ${this.tree}";
    }

    void read( List<String> inputs )
    {
        this.sun = parse(inputs[0]);
        this.score = parse(inputs[1]);
        this.asleep = inputs.length == 2 ? 0 : parse(inputs[2]);
    }
}

void main() {

    List inputs;
    int n = 0;

    //  Obsolete
    int complete = 35 ;
    bool isComplete = false;

    List<Cell> cell = List.generate( 37 ,
    (i) => new Cell( inputs : ['0','0','0','0','0','0','0','0'] ) , growable : false);

    List<Agent> player = List.generate( 2 ,
    (i) => new Agent( tree : [] ) , growable : false );

    List<Tree> tree = [];

    n = parse(read()); // 37
    for (int i = 0; i < n; i++)
    {
        cell[i] = new Cell( inputs : read().split(' ') );
    }

    // game loop
    while (true)
    {
        int day = parse(read()); // the game lasts 24 days: 0-23
        int nutrients = parse(read()); // the base score you gain from the next COMPLETE action

        player[kMINE].read( read().split(' ') );
        player[kOPP].read( read().split(' ') );

        int n = parse(read());
        for (int i = 0; i < n ; i++) {
            tree.add( new Tree( inputs: read().split(' ') ) );
        }

        n = parse(read()); // all legal actions
        for (int i = 0; i < n ; i++) {
            List<String> possibleAction = read().split(' ');
            error(possibleAction);
            // try printing something from here to start with
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
