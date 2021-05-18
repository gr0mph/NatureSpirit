import 'dart:io';
import 'dart:math';

var error = stderr.writeln, parse = int.parse;
final int kMINE = 1 , kOPP = 0;
final List<int> kGROW = [0,1,3,7];
final List<List<int>> kSEED = [
    [0] , [1] , [2] , [3] , [4] , [5] ,
    [0,0] , [0,1] , [1,1] , [1,2] , [2,2] , [2,3] , [3,3] , [3,4] , [4,4] , [4,5] , [5,5] ,[5,0] ,
    [0,0,0] , [0,0,1] , [0,1,1] , [1,1,1] , [1,1,2] , [1,2,2] , [2,2,2] , [2,2,3] , [2,3,3] ,
    [3,3,3] , [3,3,4] , [3,4,4] , [4,4,4] , [4,4,5] , [4,5,5] , [5,5,5] , [5,5,0] , [5,0,0]
    ];
final List<List<int>> kSIMSUN =
[
    [ 25,26,27,28,29,30,31 ],   [ 28,29,30,31,32,33,34 ],   [ 31,32,33,34,35,36,19 ],
    [ 34,35,36,19,20,21,22 ],   [ 19,20,21,22,23,24,25 ],   [ 22,23,24,25,26,27,28 ],
];
final List<List<List<int>>> kFUZZY_NEIGH =
[
    [ [ 1, 7,19], [ 2, 9,22], [ 3,11,25], [ 4,13,28], [ 5,15,31], [ 6,17,34] ],

    [ [7,19],       [8,21],     [2,10,24],  [0,4,13],   [6,16,32],  [18,35] ],
    [ [8,20],       [9,22],     [10,24],    [3,12,27],  [0,5,15],   [1,18,35] ],
    [ [2,8,20],     [10,23],    [11,25],    [12,27],    [4,14,30],  [0,6,17] ],
    [ [0,1,7],      [3,10,23],  [12,26],    [13,28],    [14,30],    [5,16,33] ],
    [ [6,18,36],    [0,2,9],    [4,12,26],  [14,29],    [15,31],    [15,33] ],
    [ [18,36],      [1,8,21],   [0,3,11],   [5,14,29],  [16,32],    [17,34] ],

    [ [19],         [20],       [8,9,23],   [1,0,4],    [18,17,33], [36]        ],
    [ [20],         [21],       [9,23],     [2,3,12],   [1,6,16],   [7,36]      ],
    [ [21],         [22],       [23],       [10,11,26], [2,0,5],    [8,7,36]    ],
    [ [9,21],       [23],       [24],       [11,26],    [3,4,14],   [2,1,18]    ],
    [ [10,9,21],    [24],       [25],       [26],       [12,13,29], [3,0,6]     ],
    [ [3,2,8],      [11,24],    [26],       [27],       [13,29],    [4,5,16]    ],
    [ [4,0,1],      [12,11,24], [27],       [28],       [29],       [14,15,32]  ],
    [ [5,6,18],     [4,3,10],   [13,27],    [29],       [30],       [15,32]     ],
    [ [16,17,35],   [5,0,2],    [14,13,27], [30],       [31],       [32]        ],
    [ [17,35],      [6,1,8],    [5,4,12],   [15,30],    [32],       [33]        ],
    [ [35],         [18,7,20],  [6,0,3],    [16,15,30], [33],       [34]        ],
    [ [36],         [7,20],     [1,2,10],   [6,5,14],   [17,33],    [35]        ],

    [ [],           [],         [20,21,22], [7,1,0],    [36,35,34], []          ],
    [ [],           [],         [21,22],    [8,2,3],    [7,18,17],  [19]        ],
    [ [],           [],         [22],       [9,10,11],  [8,1,6],    [20,19]     ],
    [ [],           [],         [],         [23,24,25], [9,2,0],    [21,20,19]  ],
    [ [22],         [],         [],         [24,25],    [10,3,4],   [9,8,7]     ],
    [ [23,22],      [],         [],         [25],       [11,12,13], [10,2,1]    ],
    [ [24,23,22],   [],         [],         [],         [26,27,28], [11,3,0]    ],
    [ [11,10,9],    [25],       [],         [],         [27,28],    [12,4,5]    ],
    [ [12,3,2],     [26,25],    [],         [],         [28],       [13,14,15]  ],
    [ [13,4,0],     [27,26,25], [],         [],         [],         [29,30,31]  ],
    [ [14,5,6],     [13,12,11], [28],       [],         [],         [30,31]     ],
    [ [15,16,17],   [14,4,3],   [29,28],    [],         [],         [31]        ],
    [ [32,33,34],   [15,5,0],   [30,29,28], [],         [],         []          ],
    [ [33,34],      [16,6,1],   [15,14,13], [31],       [],         []          ],
    [ [34],         [17,18,7],  [16,5,4],   [32,31],    [],         []          ],
    [ [],           [35,36,19], [17,6,0],   [33,32,31], [],         []          ],
    [ [],           [36,19],    [18,1,2],   [17,16,15], [34],       []          ],
    [ [],           [19],       [7,8,9],    [18,6,5],   [35,34],    []          ],
];
final int STARTING = 0, FARMING = 1, NOISING = 2, SCORING = 3, ENDING = 4;

int nbRoll = 0;
int nbMine = 0;
int nbOpp = 0;

//  Time
Stopwatch stopwatch = new Stopwatch();
int time = 700;
int maxDay = 0;

String read() {
  String? s = stdin.readLineSync();
  return s == null ? '' : s;
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
                n = new Node(f: grow , a: "GROW" , p: [ c.index ] )..heuristic = h_grow;
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
                        n = new Node(f: seed, a:"SEED" , p: [ c.index , i] )..heuristic = h_seed;
                        q.add( n );
                    }
                }
            }

            //  Check COMPLETE
            if( c.size == 3 )
            {
                n = new Node(f: complete, a:"COMPLETE" , p: [ c.index] )..cost = 4..heuristic = h_over;
                q.add( n );
            }

        }
    }

    //  Add wait
    n = new Node(f: wait, a:"WAIT", p: [isMine] )..cost = 0..heuristic = h_wait;
    q.add( n );

    //  Update cost
    for( final _ in q )
    {
        if( _.cost == -1 )
        {
            int index = _.p.last;

            if( tree[index].isMine == -1 )
                _.cost = cost[ tree[index].size ];
            else
                _.cost = cost[ tree[index].size + 1 ];
        }
    }

    //  Update queue
    q.removeWhere( (n) => n.cost > player[isMine].sun );

    return q;
}

void renting(List<Cell> cell, List<Agent> player, List<Tree> tree)
{
    player[kMINE].scoring = player[kMINE].score + player[kMINE].sun ~/3;
    player[kOPP].scoring = player[kOPP].score + player[kOPP].sun ~/3;

    int day = ( player[kMINE].day + 1 ) % 6;
    player[kMINE].renting = 0;
    player[kOPP].renting = 0;
    for( final start in kSIMSUN[day] )
    {
        int sizeShadow = 0 , shadow = 0;
        int hex = start;
        while( hex != -1 )
        {
            //  Size
            if( tree[hex].size > sizeShadow )
            {
                sizeShadow = tree[hex].size;
                shadow = tree[hex].size + 1;
                player[ tree[hex].isMine ].renting =
                    player[ tree[hex].isMine ].renting + sizeShadow;
            }

            //  Neighboor
            hex = cell[hex].neighboor[day];
            shadow--;
            if( shadow == 0 )   sizeShadow = 0;
        }
    }
}

List<int> h_seed(
    int p1 , int p2 , int id1 , List<int> id2 ,
    Node n , List<Cell> cell , List<Agent> player , List<Tree> tree )
{
    List<int> k = [ 0 , 0 ];

    //  if( id2.contains(id1) ) return k;
    //  Collision

    //  Check F.S.M
    if( player[p1].state == STARTING )
    {
        if( player[p1].day == 0 )   return k;
        if( player[p1].day == 1 )   return k;
    }

    if( n.cost != 0 )
        return k;

    k[p1] = k[p1] - n.cost;                  //  Update cost, sun is point , no sun no point
    k[p1] = k[p1] + 6 + cell[id1].richness;

    for( int d = 0 ; d < 6 ; d++ )
    {
        int i = 1;
        for( final int hex in kFUZZY_NEIGH[id1][d] )
        {
            if( tree[hex].isMine == p1 )    k[p1] = k[p1] - 2;
            if( tree[hex].isMine == p2 )
            {
                //  Depends of F.S.M.
                ;
            }
            if( id2.contains(hex) )
            {
                //  Depends of F.S.M.
                ;
            }
            //  One iteration only
            if( i == 2 )    break;
            i++;
        }
    }
    //error("[${id1}] >> seed k ${k} id2 ${id2}");
    return k;
}

List<int> h_grow(
    int p1 , int p2 , int id1 , List<int> id2 ,
    Node n , List<Cell> cell , List<Agent> player , List<Tree> tree )
{
    List<int> k = [ 0 , 0 ];

    //  Check F.S.M
    if( player[p1].state == ENDING )
    {
        if( tree[id1].size == 2 && player[p1].day < 23 )
        {
            //k[p1] = 100;
            k[p1] = k[p1] - n.cost - 4 + (player[p1].nutrients + cell[id1].richness) * 3;
        }
        return k;
    }

    int nDay = (24 - player[p1].day) ~/ 6 + 1;
    k[p1] = k[p1] - n.cost;

    if( tree[id1].size == 0 )
    {
        //  ...
        k[p1] = k[p1] + n.cost;
    }

    for( int d = 0 ; d < 6 ; d++ )
    {
        int p = 0;
        int g = nDay;
        for( final int hex in kFUZZY_NEIGH[id1][d] )
        {
            if( tree[hex].isMine == p1 )
            {
                break;
            }
            if( tree[hex].isMine == p2 )
            {
                //  Depends of the F.S.M.
                if( tree[hex].size > (tree[id1].size + 1) )     break;
                p++;
                ;
            }
            if( id2.contains(hex) )
            {
                //  Depends of the F.S.M.
                ;
            }

            if( p == kFUZZY_NEIGH[id1][d].length )
            {
                p = 3;
                break;
            }
            p++;
        }
        k[p1] = k[p1] + g * p;
    }
    //error("[${id1}] >> grow k ${k} id2 ${id2}");
    return k;
}

List<int> h_wait(
    int p1 , int p2 , int id1 , List<int> id2 ,
    Node n , List<Cell> cell , List<Agent> player , List<Tree> tree )
{
    List<int> k = [ 0 , 0 ];
    //k[p1] = player[p1].sun;
    //error("[${id1}] >> wait k ${k}");
    return k;
}

List<int> h_over(
    int p1 , int p2 , int id1 , List<int> id2 ,
    Node n , List<Cell> cell , List<Agent> player , List<Tree> tree )
{
    List<int> k = [ 0 , 0 ];

    if( player[p1].state == ENDING )
    {
        int n = 0;
        for( final _ in tree )
            if( _.isMine == p1 && _.size == 3 )    n++;

        if( n >= (24 - player[p1].day) )
        {
            k[p1] = k[p1] + (player[p1].nutrients + cell[id1].richness) * 3;
        }
    }
    else
    if( player[p1].state == SCORING )
    {
        int nDay = (24 - player[p1].day) ~/ 6 + 1;

        k[p1] = k[p1] - n.cost;
        k[p1] = k[p1] + (player[p1].nutrients + cell[id1].richness) * 3;

        for( int d = 0 ; d < 6 ; d++ )
        {
            int g1 = 0 , g2 = 0;
            int g = nDay;
            for( final int hex in kFUZZY_NEIGH[id1][d] )
            {
                if( tree[hex].isMine == p1 && g != 0 )
                {
                    g1 = 0;
                    g = 0;
                }
                if( tree[hex].isMine == p2 && g != 0)
                {
                    //  Depends of the F.S.M.
                    g2 = g;
                    g = 0;
                }
                if( id2.contains(hex) )
                {
                    //  Depends of the F.S.M.
                    ;
                }

                if( p1 == kFUZZY_NEIGH[id1][d].length && g != 0 )
                {
                    g1 = g;
                    g = 0;
                }
            }
            g1 = g;
            k[p1] = k[p1] - 3 * g1;
            k[p2] = k[p2] + 3 * g2;
        }
    }

    //error("[${id1}] >> over k ${k} id2 ${id2}");
    return k;
}

void bug(Node n , List<Cell> cell , List<Agent> player , List<Tree> tree )
{
    error("BUG SIMULATE TURN");
    for( final _ in n.p )
    {
        error("$_ tree [${tree[_]}]");
    }
    error(player);
    error("node ${n} cost ${n.cost}");
    print("BUG SIMULATE TURN");
}

//  Warning add one parameter in parameter to know MINE or OPP
void wait( Node n , List<int> p , List<Cell> cell , List<Agent> player , List<Tree> tree )
{
    //  Update
    player[ p[0] ].asleep = 1;
}

void grow( Node n , List<int> p , List<Cell> cell , List<Agent> player , List<Tree> tree )
{
    int id1 = p[0], p1 = tree[ id1 ].isMine ;

    //  Update tree
    tree[ id1 ].size++;
    tree[ id1 ].isDormant = 1;

    //  Update player
    player[ p1 ].sun = player[ p1 ].sun - n.cost;
}

void seed( Node n , List<int> p , List<Cell> cell , List<Agent> player , List<Tree> tree )
{
    int id1 = p[0], id2 = p[1] , p1 = tree[ id1 ].isMine ;

    //  Update tree
    tree[ id1 ].isDormant = 1;
    tree[ id2 ].isDormant = 1;
    tree[ id2 ].isMine = tree[ id1 ].isMine;

    //  Update player
    player[ p1 ].sun = player[ p1 ].sun - n.cost;

}

void complete( Node n , List<int> p , List<Cell> cell , List<Agent> player , List<Tree> tree )
{
    int id1 = p[0], p1 = tree[ id1 ].isMine ;

    //  Update tree
    tree[id1].size = 0;
    tree[id1].isMine = -1;
    tree[id1].isDormant = 0;

    //  Update player
    player[p1].score = player[p1].score + player[p1].nutrients + cell[id1].richness;
    player[p1].sun = player[p1].sun - 4;

}

class Node {

    //  Update
    late Function turn;
    late Function heuristic;
    late String action;
    late List<int> p;

    //  Gain vs Cost
    late int cost;

    //  K
    int k = 0;

    Node( {required Function f , required String a , required List<int> p }) {
        this.turn = f; this.action = a ; this.p = p;
        this.cost = -1;
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

    Cell.fromCell(Cell _) :
    this.index = _.index , this.richness = _.richness , this.neighboor = _.neighboor;

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
    Tree.fromTree( Tree _ ) :
    this.index = _.index , this.size = _.size ,
    this.isMine = _.isMine, this.isDormant = _.isDormant;

    @override
    String toString() {
        return "tree [${this.index}] ${this.size} ${this.isMine} ${this.isDormant}";
    }
}

class Agent {

    int day = 0, nutrients = 0;
    int sun , score , asleep;
    late int state = STARTING;

    //  Add Finite State Machine of agent
    int p = -1, renting = 2, scoring = 0;

    //  Add Node of agent
    List<Node> node = [];
    List<int> heuristic = [];

    Agent() :
    this.sun = 0 , this.score = 0 , this.asleep = 0;

    Agent.fromAgent( Agent _ ) :
    this.sun = _.sun , this.score = _.score , this.asleep = _.asleep ,
    this.day = _.day , this.nutrients = _.nutrients ,
    this.p = _.p , this.renting = _.renting , this.scoring = _.scoring ;

    @override
    String toString() {
        return "(${this.day},${this.nutrients},${this.score},${this.sun})";
        //return "(${this.score},${this.sun})";
    }

    void read( List<String> inputs )
    {
        this.sun = parse(inputs[0]);
        this.score = parse(inputs[1]);
        this.asleep = inputs.length == 2 ? 0 : parse(inputs[2]);
    }

    void update_fsm( List<Cell> cell , Agent opp , List<Tree> tree )
    {
        int n = 0;
        for( final _ in tree )
            if( _.isMine == kMINE && _.size == 3 )    n++;

        //...
        if( this.day < 4 )
            this.state = STARTING;   //  WAIT, GROW, WAIT, SEED, GROW, WAIT
        else
        if( this.day > (23 - n) || this.state == ENDING )
            this.state = ENDING;     //  COMPLETE, WAIT, COMPLETE, WAIT
        else
        if( this.scoring >= opp.scoring )
            this.state = FARMING;    //  GROW, SEED

        else
        if( this.renting >= opp.renting )
            this.state = SCORING;    //  COMPLETE, WAIT
        else
            this.state = NOISING;

        //error("STATE ${this.state}");
    }

}

void simulateTurn( Node n1 , Node n2 , List<Cell> cell , List<Agent> player , List<Tree> tree )
{
    if( n1.turn == seed && n2.turn == seed && n1.p.last == n2.p.last )
    {
        //  Update tree
        tree[ n1.p[0] ].isDormant = 1;
        tree[ n1.p[0] ].isDormant = 1;

        //  Update player
        player[kMINE].sun = player[kMINE].sun + n1.cost;
        player[kOPP].sun = player[kOPP].sun + n2.cost;
    }
    else
    {
        n1.turn( n1 , n1.p , cell , player , tree );

        n2.turn( n2 , n2.p , cell , player , tree );
    }

    int _ = player[kMINE].nutrients;
    if( n1.turn == complete )  _--;
    if( n2.turn == complete )  _--;

    player[kMINE].nutrients = max( _ , 0 );
    player[kOPP].nutrients = max( _ , 0 );
}

void simulateDay( List<Cell> cell , List<Agent> player , List<Tree> tree )
{
    //  Reset
    for( final c in tree )
    {
        c.isDormant = 0;
    }

    //  Reset
    for( final p in player )
    {
        p.asleep = 0;
    }

    //  Update sun
    renting( cell , player , tree );

    player[kMINE].day++;
    player[kOPP].day++;

    player[kMINE].sun = player[kMINE].sun + player[kMINE].renting;
    player[kOPP].sun = player[kOPP].sun + player[kOPP].renting;
}

class NatureSpirit {

    List<Cell> _cell = [];
    List<Agent> _player = [];
    List<Tree> _tree = [];

    List<Cell> get cell => _cell;
    List<Agent> get player => _player;
    List<Tree> get tree => _tree;

    List<Node> q1_play = [] , o2_play = [];

    //List<Node> q1_rest = [] , o2_rest = [];

    Node? done;

    void set player( List<Agent> p )
    {
        this._player = List.generate( p.length ,
        (i) => new Agent.fromAgent( p[i] ) , growable : false );
    }

    void set tree( List<Tree> t )
    {
        this._tree = List.generate( t.length ,
        (i) => new Tree.fromTree( t[i] ) , growable : false );
    }

    void set cell( List<Cell> c )
    {
        this._cell = c;
        //this._cell = List.generate( c.length ,
        //(i) => new Cell.fromCell( c[i] ) , growable : false );
    }

    List<Node> natureTurn( Node n1 , Node n2 )
    {
        int  best1 = -1 , best2 = -1 ;
        List<int> k = [-1,-1];

        simulateTurn( n1 , n2 , this.cell , this.player , this.tree );

        //  Add F.S.M. to still work in MCTS
        renting( cell , player , tree );
        player[kMINE].update_fsm( cell , player[kOPP] , tree );

        //  Obsolete
        final List<int> id2 = [];

        if( n1.turn != wait )
        {
            List<Node> q =
            state( kMINE , this.cell , this.player , this.tree );

            best1 = -1;
            for( final _ in q )
            {
                k = _.heuristic( kMINE , kOPP , _.p.last , id2 , _ ,
                this.cell , this.player , this.tree );
                if( (k[kMINE] - k[kOPP]) > best1 )
                {
                    best1 = (k[kMINE] - k[kOPP]);
                    n1 = _;
                }
            }
        }

        if( n2.turn != wait )
        {
            List<Node> o =
            state( kOPP , this.cell , this.player , this.tree );

            best2 = -1;
            for( final _ in o )
            {
                k = _.heuristic( kOPP , kMINE , _.p.last , id2 , _ ,
                this.cell , this.player , this.tree );
                if( (k[kMINE] - k[kOPP]) > best2 )
                {
                    best2 = (k[kMINE] - k[kOPP]);
                    n2 = _;
                }
            }
        }

        return [ n2 , n1 ];
    }
}

class MonteCarloTreeSearch {

    final int W = 0 , N = 1;
    int id = -1;
    int i1 = 0, i2 = 0;
    int day = 0;

    MonteCarloTreeSearch?        p;
    List<List<MonteCarloTreeSearch?>>  child = [];

    List<int> result = [ 0 , 0 ];

    List<int> w1 = [], w2 = [];
    List<int> n1 = [], n2 = [];

    List<List<int>> _w = [];
    List<List<int>> _n = [];

    List<Node> q1_start = [], o2_start = [];
    //List<Node> q_rest = [], o_rest = [];

    NatureSpirit info = new NatureSpirit();

    @override
    String toString() {
        return "($i1,$i2,${p?._w[i1][i2]},${p?._n[i1][i2]})";
    }

    int get n {
        int n = 0;
        for( final _ in n1 )    n = n + _;
        return n;
    }
    int get w {
        int n = 0;
        for( final _ in w1 )    n = n +_;
        return n;
    }

    void mctsInitState( )
    {
        //this.q1_start = state( kMINE , this.info.cell , this.info.player , this.info.tree );
        //this.o2_start = state( kOPP , this.info.cell , this.info.player , this.info.tree );

        //  Reduce number of case / delete SEED because it is take after
        List<Node> q1 = state( kMINE , this.info.cell , this.info.player , this.info.tree );
        List<Node> o2 = state( kOPP , this.info.cell , this.info.player , this.info.tree );

        for ( final _ in q1 )
        {
            if( _.turn != seed )  this.q1_start.add(_);
        }
        for ( final _ in o2 )
        {
            if( _.turn != seed )  this.o2_start.add(_);
        }
        if( this.q1_start.length > 1 )  this.q1_start.removeLast();
        if( this.o2_start.length > 1 )  this.o2_start.removeLast();

        //  Depends of F.S.M.
        //  ...

        this.w1 = List.generate( this.q1_start.length , (i) => 0 , growable : false );
        this.n1 = List.generate( this.q1_start.length , (i) => 0 , growable : false );

        this.w2 = List.generate( this.o2_start.length , (i) => 0 , growable : false );
        this.n2 = List.generate( this.o2_start.length , (i) => 0 , growable : false );

        //  Debug
        this._w = List.generate( this.q1_start.length ,
        (i) => List.generate( this.o2_start.length , (i) => 0 , growable : false ) , growable: false );

        this._n = List.generate( this.q1_start.length ,
        (i) => List.generate( this.o2_start.length , (i) => 0 , growable : false ) , growable: false );

        this.child = List.generate( this.q1_start.length ,
        (i) => List.generate( this.o2_start.length , (i) => null , growable : false ) , growable : false );
    }

    MonteCarloTreeSearch nature( int i1 , int i2 )
    {
        MonteCarloTreeSearch _  = new MonteCarloTreeSearch()..p = this..i1 = i1..i2 = i2
        ..day = this.day + 1;

        _.info = new NatureSpirit()
        ..cell = this.info.cell ..player = this.info.player ..tree = this.info.tree;

        //  First node played
        _.info.q1_play.add( this.q1_start[i1] );
        _.info.o2_play.add( this.o2_start[i2] );

        this.child[i1][i2] = _;
        return _;
    }

    //  Select best child for mine and for opp
    MonteCarloTreeSearch selection(double c )
    {
        MonteCarloTreeSearch _ = this;

        if( this.day == 24 )
        {
            return this;
        }

        while( _.n1.length > 0 )
        {
            if( _.day == 24 )
                return _;

            for( int i1 = 0 ; i1 < _.n1.length ; i1++ )
            {
                if( _.n1[i1] == 0 ) {
                    int i2 = Random().nextInt( _.w2.length );
                    _ = _.nature( i1 , i2 );
                    return _;
                    //return _.nature( i1 , Random().nextInt( _.w2.length ) );
                }
            }

            List<double> weight = List.generate( _.n1.length ,
            (i1) => _.w1[i1] / _.n1[i1] + c * sqrt ( 2 * _.n / _.n1[i1] ) );

            double wMax = -0.1;
            int iMax = -1;

            for( int i = 0 ; i < weight.length ; i++ )
            {
                if( wMax < weight[i] ) {
                    iMax = i;
                    wMax = weight[i];
                }
            }

            int i2 = Random().nextInt( _.w2.length );
            if( _.child[iMax][i2] == null )
            {
                _ = _.nature( iMax , i2 );
                return _;
            }
            _ = _.child[iMax][i2] ?? _ ;

        }

        //  Dead-code
        return _;
    }

    MonteCarloTreeSearch expansion()
    {
        if( this.day == 24 )
        {
            return this;
        }

        //  Expand day
        Node n1 = this.info.q1_play.last , n2 = this.info.o2_play.last;

        while( n1.turn != wait || n2.turn != wait )
        {
            List<Node> r = this.info.natureTurn( n1 , n2 );
            n1 = r[kMINE];
            n2 = r[kOPP];
            this.info.q1_play.add( n1 );
            this.info.o2_play.add( n2 );
        }

        simulateDay( this.info.cell , this.info.player , this.info.tree );

        this.mctsInitState();

        if( maxDay < this.day )
        {
            maxDay = this.day;
        }

        return this;
    }

    int simulation( )
    {
        if( this.day == 24 )
        {
            return this.info.player[kMINE].score - this.info.player[kOPP].score;
        }

        nbRoll++;

        NatureSpirit roll = new NatureSpirit()
        ..cell = this.info.cell ..player = this.info.player ..tree = this.info.tree ;

        int count = 0;

        while( roll.player[kMINE].day < 24 )
        {
            //  Random for first turn of each day
            List<Node> q =
            state( kMINE , roll.cell , roll.player , roll.tree );

            //  Finite State Machine
            //  ...

            Node n1 = q[ Random().nextInt( q.length ) ];

            //  Random for first turn of each day
            List<Node> o =
            state( kOPP , roll.cell , roll.player , roll.tree );

            //  Finite State Machine
            //  ...

            Node n2 = o[ Random().nextInt( o.length ) ];

            while( n1.turn != wait || n2.turn != wait )
            {
                List<Node> r = roll.natureTurn( n1 , n2 );
                n1 = r[kMINE];
                n2 = r[kOPP];
            }

            simulateDay( roll.cell , roll.player , roll.tree );
        }

        return roll.player[kMINE].score >= roll.player[kOPP].score ? 1 : 0;
    }

    void backpropagation( int result )
    {
        MonteCarloTreeSearch child = this;
        MonteCarloTreeSearch? _ = this.p;

        while( _ != null )
        {

            if( result > 0 ){
                _.w1[ child.i1 ]++;
                _._w[ child.i1 ][ child.i2 ]++;
            }
            else
                _.w2[ child.i2 ]++;

            _.n1[ child.i1 ]++;
            _.n2[ child.i2 ]++;
            _._n[ child.i1 ][ child.i2 ]++;

            child = _;
            _ = _.p;
        }
    }

}

void main() {

    List inputs;
    Node? best;
    int n = 0;
    int maxCounter = 500;

    MonteCarloTreeSearch __mcts__ = new MonteCarloTreeSearch();

    List<Cell> cell = List.generate( 37 ,
    (i) => new Cell( inputs : ['0','0','0','0','0','0','0','0'] ) , growable : false);

    List<Agent> player = List.generate( 2 ,
    (i) => new Agent()..p = i , growable : false );

    List<Tree> tree = List.generate( 37 ,
    (i) => new Tree( inputs: [ "$i" , '0' , '-1' , '0' ]) , growable : false );

    String debug = "";

    //debug = read(); error(debug);
    n = parse(read()); // 37
    //n = parse(debug);

    //  Time
    stopwatch.start();
    time = 800;
    maxCounter = 5000;

    for (int i = 0; i < n; i++)
    {
        //debug = read(); error(debug);
        cell[i] = new Cell( inputs : read().split(' ') );
        //cell[i] = new Cell( inputs : debug.split(' ') );
    }

    bool chooseMcts = true;

    // game loop
    while (true)
    {
        //  Update
        //debug = read(); error(debug);

        player[kMINE].day = parse(read());
        //player[kMINE].day = parse(debug);

        if( time < 100 )
        {
            //  Reset Timer
            stopwatch.reset();
        }

        //debug = read(); error(debug);
        player[kMINE].nutrients = parse(read());
        //player[kMINE].nutrients = parse(debug);

        player[kOPP].day = player[kMINE].day;
        player[kOPP].nutrients = player[kMINE].nutrients;

        //debug = read(); error(debug);
        player[kMINE].read( read().split(' ') );
        //player[kMINE].read( debug.split(' ') );

        //debug = read(); error(debug);
        player[kOPP].read( read().split(' ') );
        //player[kOPP].read( debug.split(' ') );

        //debug = read(); error(debug);
        int n = parse(read());
        //int n = parse(debug);

        for (int i = 0; i < n ; i++) {
            //debug = read(); error(debug);
            inputs = read().split(' ');
            //inputs = debug.split(' ');

            tree[ parse(inputs[0]) ].size = parse(inputs[1]);
            tree[ parse(inputs[0]) ].isMine = parse(inputs[2]);
            tree[ parse(inputs[0]) ].isDormant = parse(inputs[3]);
        }

        //  Warning
        if( best != null && best.turn == complete )
        {
            tree[ best.p.last ] = new Tree(inputs: ['${best.p.last}','0','-1','0'] );
        }

        renting( cell , player , tree );
        player[kMINE].update_fsm( cell , player[kOPP] , tree );

        //debug = read(); error(debug);
        n = parse(read()); // all legal actions
        //n = parse(debug); // all legal actions

        for (int i = 0; i < n ; i++) {
            //debug = read(); error(debug);
            List<String> _ = read().split(' ');
            //List<String> _ = debug.split(' ');
        }

        //  State
        List<Node> q = state( kMINE , cell , player , tree );
        List<Node> o = state( kOPP , cell , player , tree );

        for( final _ in q )
        {
            ;
        }

        //  Delete wait
        o.removeLast();
        List<int> id2 = [];
        for( final _ in o )
        {
            ;
        }

        List<int> m = [];

        best = q.last;    //  Choose wait
        int best_score = 0;

        //String text = "[${player[kMINE].scoring},${player[kMINE].renting},${player[kOPP].scoring},${player[kOPP].renting}]";

        for( final _ in q )
        {
            List<int> kc =
            _.heuristic( kMINE , kOPP , _.p.last , id2 , _ , cell , player , tree );

            if( _.turn == wait )
                _.p.removeLast();

            if( (kc[kMINE] - kc[kOPP]) > best_score )
            {
                best = _;
                best_score = (kc[kMINE] - kc[kOPP]);
            }
            m.add( (kc[kMINE] - kc[kOPP]) );
        }

        //error(m);


        //  MonteCarloTreeSearch init or update
        if( __mcts__.info.cell.length == 0 )
        {
            __mcts__.info.cell = cell;
            __mcts__.info.player = player;
            __mcts__.info.tree = tree;

            //  Create state and child
            __mcts__.mctsInitState( );

            //error("MINE ${__mcts__.q1_start.length} node ${__mcts__.q1_start}");
            //error("_OPP ${__mcts__.o2_start.length} node ${__mcts__.o2_start}");

        }
        else
        if( __mcts__.day != player[kMINE].day )
        {
            //  Search the MCTS that is most near of evalutaion
            //error("search mcts");
            __mcts__ = new MonteCarloTreeSearch()..day = player[kMINE].day;

            __mcts__.info.cell = cell;
            __mcts__.info.player = player;
            __mcts__.info.tree = tree;

            //  Create state and child
            __mcts__.mctsInitState( );

            //error("MINE ${__mcts__.q1_start.length} node ${__mcts__.q1_start}");
            //error("_OPP ${__mcts__.o2_start.length} node ${__mcts__.o2_start}");

            //  Choose MCTS
            chooseMcts = true;

            //  Update
            ;
        }

        //  MonteCarlo TreeSearch
        //  Update state
        //__mine__mcts__._state = ...;


        //  MonteCarloTreeSearch
        int counter = 0;
        while( stopwatch.elapsedMilliseconds < time )
        {
            break;

            //  Best child
            MonteCarloTreeSearch _ = __mcts__.selection( 1.41 );

            if( stopwatch.elapsedMilliseconds >= time )
            {
                break;
            }

            //  Expand turn
            _ = _.expansion();

            if( stopwatch.elapsedMilliseconds >= time )
            {
                break;
            }

            //  Random sequence
            int k = _.simulation();
            //int k = 0;

            if( stopwatch.elapsedMilliseconds >= time )
            {
                break;
            }

            //  Back propagate
            _.backpropagation( k );

            if( stopwatch.elapsedMilliseconds >= time )
            {
                break;
            }

            if( counter >= maxCounter )  break;
            counter++;
        }

        for( int i = 0 ; i < __mcts__.w1.length ; i++ )
            error("[${__mcts__.w1[i]},${__mcts__.n1[i]}] ${__mcts__.q1_start[i]} ${__mcts__.child[i]}");


        String textTime = "${stopwatch.elapsed.inMilliseconds}";

        //  Select first best child w/n near 1

        //  Out
        //print(best);
        nbMine = __mcts__.n1.length;
        nbOpp = __mcts__.n2.length;

        chooseMcts = false;

        if( chooseMcts == false )
        {
            print("$best [$textTime,$nbRoll,$nbMine,$nbOpp]");
        }
        else
        {
            double ratioMax = -1, current = -1;
            Node best2 = best ?? q.last;  //  Choose wait
            for( int i = 0 ; i < __mcts__.w1.length ; i++ )
            {
                current = __mcts__.w1[i] / __mcts__.n1[i];
                if( current > ratioMax )
                {
                    ratioMax = current;
                    best2 = __mcts__.q1_start[i];
                }
            }
            error("$best [$textTime,$nbRoll,$nbMine,$nbOpp]");
            print("$best2 [$textTime,$nbRoll,$nbMine,$nbOpp] mcts");
            chooseMcts = false;
        }

        time = 70;
        maxCounter = 1000;

        // GROW cellIdx | SEED sourceIdx targetIdx | COMPLETE cellIdx | WAIT <message>
        //print('WAIT');
    }
}
