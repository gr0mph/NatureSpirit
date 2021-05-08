import 'dart:io';

var error = stderr.writeln, parse = int.parse;
final int kMINE = 1 , kOPP = 0;
final List<int> kGROW = [0,1,3,7];
final List<List<int>> kSEED = [
    [0] , [1] , [2] , [3] , [4] , [5] ,
    [0,0] , [0,1] , [1,1] , [1,2] , [2,2] , [2,3] , [3,3] , [3,4] , [4,4] , [4,5] , [5,5] ,[5,0] ,
    [0,0,0] , [0,0,1] , [0,1,1] , [1,1,1] , [1,1,2] , [1,2,2] , [2,2,2] , [2,2,3] , [2,3,3] ,
    [3,3,3] , [3,3,4] , [3,4,4] , [4,4,4] , [4,4,5] , [4,5,5] , [5,5,5] , [5,5,0] , [5,0,0]
    ];

String read() {
  String? s = stdin.readLineSync();
  return s == null ? '' : s;
}

void simulate( List<Cell> cell , List<Agent> player , List<Tree> tree )
{
    int nComplete = 0;

    //  Reset
    for( final c in tree )
    {
        c.isDormant = 0;

        if( c.seed[kOPP] > 0 && c.seed[kMINE] > 0 )
        {
            player[kOPP].sun = player[kOPP].sun + c.seed[kOPP];
            player[kMINE].sun = player[kMINE].sun + c.seed[kMINE];
        }
        else
        if( c.seed[kOPP] > 0 )  c.isMine = kOPP;
        else
        if( c.seed[kMINE] > 0 ) c.isMine = kMINE;

        c.seed[kOPP] = 0;
        c.seed[kMINE] = 0;

        if( c.complete == true )
        {
            player[ c.isMine ].score = player[ c.isMine ].nutrients + cell[ c.index ].richness;
            nComplete++;
            c.complete = false;
        }
    }

    if( nComplete > 0 )
    {
        player[kOPP].nutrients = player[kOPP].nutrients - nComplete;
        player[kMINE].nutrients = player[kMINE].nutrients - nComplete;
    }

    ;

    //  Update sun
    //  int sun = (player[kMINE].day + 1) % 6;
}

List<Node> state( int isMine , List<Cell> cell , List<Agent> player , List<Tree> tree )
{
    List<Node> q = [];
    Node n;

    List<int> cost = [ 0 , 1 , 3 , 7 , 4 ];

    for( final c in tree )
    {
        if( c.isMine == isMine )
        {
            //  Update cost
            cost[ c.size ]++;

            //  Check Dormant
            if( c.isDormant == 1 )  continue;

            //  Check GROWS
            if( c.size != 3 )
            {
                n = new Node(f: grow , a: "GROW" , p: [ c.index ] );
                q.add( n );
            }

            //  Check SEED
            for( final s in kSEED )
            {
                int i = cell[ c.index ].index;
                if( c.size >= s.length )
                {
                    for( final d in s )
                    {
                        i = cell[i].neighboor[d];
                        if( i == -1 )   break;
                    }

                    if( i == -1 )               continue;
                    if( cell[i].richness == 0 ) continue;
                    if( tree[i].isMine == -1 )
                    {
                        n = new Node(f: seed, a:"SEED" , p: [ c.index , i] );
                        q.add( n );
                    }
                }
            }

            //  Check COMPLETE
            if( c.size == 3 )
            {
                n = new Node(f: complete, a:"COMPLETE" , p: [ c.index] )..cost = 4;
                q.add( n );
            }

        }
    }

    //  Add wait
    n = new Node(f: wait, a:"WAIT", p: [isMine] )..cost = 0;
    q.add( n );

    //  Update cost
    for( final _ in q )
    {
        if( _.cost == -1 )
        {
            int index = _.p.last;
            _.cost = cost[ tree[index].size ];
        }

    }

    //  Update queue
    q.removeWhere( (n) => n.cost > player[isMine].sun );

    return q;
}

//  Warning add one parameter in parameter to know MINE or OPP
void wait( List<int> p , List<Cell> cell , List<Agent> player , List<Tree> tree )
{
    player[ p[0] ].asleep = 1;

    if( player[kOPP].asleep == 1 && player[kMINE].asleep == 1 )
    {
        //  Update
        simulate( cell , player , tree );
    }
}

void grow( List<int> p , List<Cell> cell , List<Agent> player , List<Tree> tree )
{
    int i = p[0];
    int own = tree[i].isMine;
    int nextSize = tree[i].size + 1;

    int cost = kGROW[nextSize];
    for( final c in tree )
        if( c.isMine == own && c.size == nextSize ) cost++;

    //  Update
    player[own].sun = player[own].sun - cost;
    tree[i].size = nextSize;
    tree[i].isDormant = 1;
}

void seed( List<int> p , List<Cell> cell , List<Agent> player , List<Tree> tree )
{
    int i = p[1];
    int own = tree[ p[0] ].isMine;
    int cost = kGROW[0];

    for( final c in tree )
        if( c.isMine == own && c.size == 0 )    cost++;

    //  Update
    player[own].sun = player[own].sun - cost;
    tree[i].seed[own] = cost;
}

void complete( List<int> p , List<Cell> cell , List<Agent> player , List<Tree> tree )
{
    int i = p[0];

    tree[i].complete = true;
}

class Node {

    //  Update
    late Function f;
    late String action;
    late List<int> p;

    //  Gain vs Cost
    late int cost;


    Node( {required Function f , required String a , required List<int> p }) {
        this.f = f; this.action = a ; this.p = p;
        this.cost = -1;
    }

    void update( List<Cell> cell , List<Agent> player , List<Tree> tree )
    {
        this.f( this.p , cell , player , tree );
    }

    @override
    String toString() {
        if( p.length == 0 ) return "${this.action}";
        if( p.length == 1 ) return "${this.action} ${this.p[0]}";
        if( p.length == 2 ) return "${this.action} ${this.p[0]} ${this.p[1]}";
        return "";
    }
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
    List<int> seed = [ 0 , 0 ];
    bool complete = false;

    Tree( {required List<String> inputs } )
    {
        this.index = parse(inputs[0]);
        this.size = parse(inputs[1]);
        this.isMine = parse(inputs[2]);
        this.isDormant = parse(inputs[3]);
    }

    @override
    String toString() {
        return "tree [${this.index}] ${this.size} ${this.isMine} ${this.isDormant}";
    }
}

class Agent {
    int day = 0, nutrients = 0;
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

    List<Cell> cell = List.generate( 37 ,
    (i) => new Cell( inputs : ['0','0','0','0','0','0','0','0'] ) , growable : false);

    List<Agent> player = List.generate( 2 ,
    (i) => new Agent( tree : [] ) , growable : false );

    List<Tree> tree = List.generate( 37 ,
    (i) => new Tree( inputs: [ "$i" , '0' , '-1' , '0' ]) , growable : false );

    n = parse(read()); // 37
    for (int i = 0; i < n; i++)
    {
        cell[i] = new Cell( inputs : read().split(' ') );
    }

    // game loop
    while (true)
    {
        //  Update
        player[kMINE].day = parse(read()); // the game lasts 24 days: 0-23
        player[kMINE].nutrients = parse(read()); // the base score you gain from the next COMPLETE action

        player[kOPP].day = player[kMINE].day;
        player[kOPP].nutrients = player[kMINE].nutrients;

        player[kMINE].read( read().split(' ') );
        player[kOPP].read( read().split(' ') );

        int n = parse(read());
        for (int i = 0; i < n ; i++) {
            inputs = read().split(' ');
            tree[ parse(inputs[0]) ].size = parse(inputs[1]);
            tree[ parse(inputs[0]) ].isMine = parse(inputs[2]);
            tree[ parse(inputs[0]) ].isDormant = parse(inputs[3]);
        }

        n = parse(read()); // all legal actions
        for (int i = 0; i < n ; i++) {
            List<String> possibleAction = read().split(' ');
            error(possibleAction);
            // try printing something from here to start with
        }

        //  State
        List<Node> q = state( kMINE , cell , player , tree );
        List<Node> o = state( kOPP , cell , player , tree );

        for( final _ in q )
        {
            error("DEBUG >> ${player[kMINE].sun} ${_.cost} $_");
        }

        //  Out
        //...

        // GROW cellIdx | SEED sourceIdx targetIdx | COMPLETE cellIdx | WAIT <message>
        print('WAIT');
    }
}
