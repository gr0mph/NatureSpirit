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
final List<List<List<Function>>> kHEURISTIC =
[
    [   [h_seed,h_seed] , [h_seed,h_grow] , [h_seed,h_over], [h_seed,h_wait]    ],
    [   [h_grow,h_seed] , [h_grow,h_grow] , [h_grow,h_over], [h_grow,h_wait]    ],
    [   [h_over,h_seed] , [h_over,h_grow] , [h_over,h_over], [h_over,h_wait]    ],
    [   [h_wait,h_seed] , [h_wait,h_grow] , [h_wait,h_over], [h_wait,h_wait]    ],
];
final List<List<int>> kSIMSUN =
[
    [ 25,26,27,28,29,30,31 ],   [ 28,29,30,31,32,33,34 ],   [ 31,32,33,34,35,36,19 ],
    [ 34,35,36,19,20,21,22 ],   [ 19,20,21,22,23,24,25 ],   [ 22,23,24,25,26,27,28 ],
];
final List<int> kFUZZY_SHADOW =
[   18,
    15, 15, 15, 15, 15, 15,
    9, 10, 9, 10, 9, 10, 9, 10, 9, 10, 9, 10,
    3, 4, 4, 3, 4, 4, 3, 4, 4, 3, 4, 4, 3, 4, 4, 3, 4, 4,
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

    [ [19],     [20],       [8,9],      [1,0],      [18,17],    [36]    ],
    [ [20],     [21],       [9,23],     [2,3],      [1,6],      [7,36]  ],
    [ [21],     [22],       [23],       [10,11],    [2,0],      [8,7]   ],
    [ [9,21],   [23],       [24],       [11,26],    [3,4],      [2,1]   ],
    [ [10,9],   [24],       [25],       [26],       [12,13],    [3,0]   ],
    [ [3,2],    [11,24],    [27],       [27],       [13,29],    [4,5]   ],
    [ [4,0],    [12,11],    [27],       [28],       [29],       [14,15] ],
    [ [5,6],    [4,3],      [13,27],    [29],       [30],       [15,32] ],
    [ [16,17],  [5,0],      [14,13],    [30],       [31],       [32]    ],
    [ [17,35],  [6,1],      [5,4],      [15,30],    [32],       [33]    ],
    [ [35],     [18,7],     [6,0],      [16,15],    [33],       [34]    ],
    [ [36],     [7,20],     [1,2],      [6,5],      [17,33],    [35]    ],

    [ [],       [],         [20],       [7],        [36],       []      ],
    [ [],       [],         [21],       [8],        [7],        [19]    ],
    [ [],       [],         [22],       [9],        [8],        [20]    ],
    [ [],       [],         [],         [23],       [9],        [21]    ],
    [ [22],     [],         [],         [24],       [10],       [9]     ],
    [ [23],     [],         [],         [25],       [11],       [10]    ],
    [ [24],     [],         [],         [],         [26],       [11]    ],
    [ [11],     [25],       [],         [],         [27],       [12]    ],
    [ [12],     [26],       [],         [],         [28],       [13]    ],
    [ [13],     [27],       [],         [],         [],         [29]    ],
    [ [14],     [13],       [28],       [],         [],         [30]    ],
    [ [15],     [14],       [29],       [],         [],         [31]    ],
    [ [32],     [15],       [30],       [],         [],         []      ],
    [ [33],     [16],       [15],       [31],       [],         []      ],
    [ [34],     [17],       [16],       [32],       [],         []      ],
    [ [],       [35],       [17],       [33],       [],         []      ],
    [ [],       [36],       [18],       [17],       [34],       []      ],
    [ [],       [19],       [7],        [18],       [35],       []      ],
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

List<int> h_seed(
    int p1 , int p2 , int id1 , List<int> id2 ,
    Node n , List<Cell> cell , List<Agent> player , List<Tree> tree )
{
    List<int> k = [ 0 , 0 ];

    //  if( id2.contains(id1) ) return k;
    //  Collision

    if( n.cost != 0 )
        return k;

    k[p1] = k[p1] - n.cost;                  //  Update cost, sun is point , no sun no point
    k[p1] = k[p1] + kFUZZY_SHADOW[ id1 ] + 6;

    for( int d = 0 ; d < 6 ; d++ )
    {
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
            break;
        }
    }
    error("[${id1}] >> seed k ${k} id2 ${id2}");
    return k;
}

List<int> h_grow(
    int p1 , int p2 , int id1 , List<int> id2 ,
    Node n , List<Cell> cell , List<Agent> player , List<Tree> tree )
{
    List<int> k = [ 0 , 0 ];

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
                ;
            }
            if( id2.contains(hex) )
            {
                //  Depends of the F.S.M.
                ;
            }

            if( p == kFUZZY_NEIGH[id1][d].length )
                break;
            p++;
        }
        k[p1] = k[p1] + g * p;
    }
    error("[${id1}] >> grow k ${k} id2 ${id2}");
    return k;
}

List<int> h_wait(
    int p1 , int p2 , int id1 , List<int> id2 ,
    Node n , List<Cell> cell , List<Agent> player , List<Tree> tree )
{
    List<int> k = [ 0 , 0 ];
    //k[p1] = player[p1].sun;
    error("[${id1}] >> wait k ${k} id2 ${id2}");
    return k;
}

List<int> h_over(
    int p1 , int p2 , int id1 , List<int> id2 ,
    Node n , List<Cell> cell , List<Agent> player , List<Tree> tree )
{
    List<int> k = [ 0 , 0 ];

    int nDay = (24 - player[p1].day) ~/ 6 + 1;

    k[p1] = k[p1] - n.cost;
    k[p1] = k[p1] + (player[p1].nutrients + cell[id1].richness) * 3;

    //error("h_over $id1");
    //error("h_over ${n.cost} ${player[p1].nutrients} ${cell[id1].richness}");

    for( int d = 0 ; d < 6 ; d++ )
    {
        int p = 0;
        int g1 = nDay , g2 = 0;
        for( final int hex in kFUZZY_NEIGH[id1][d] )
        {
            if( tree[hex].isMine == p1 )
            {
                p++;
                break;
            }
            if( tree[hex].isMine == p2 )
            {
                //  Depends of the F.S.M.
                g2 = g2 + nDay;
                ;
            }
            if( id2.contains(hex) )
            {
                //  Depends of the F.S.M.
                ;
            }

            if( p == kFUZZY_NEIGH[id1][d].length )
                break;
            p++;
        }
        //error("day $d hex ${kFUZZY_NEIGH[id1][d]} gain $g1 $g2 p $p");
        k[p1] = k[p1] - 3 * g1 * p;
        k[p2] = k[p2] + g2 ;
    }
    error("[${id1}] >> over k ${k} id2 ${id2}");
    return k;
}

int heuristic2(
    Function f , List<int> id2 ,
    Node n , List<Cell> cell , List<Agent> player , List<Tree> tree )
{
    List<int> k =
    f( kMINE , kOPP , n.p.last , id2 , n , cell , player , tree );

    return k[kMINE] - k[kOPP];
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

    Agent() :
    this.sun = 0 , this.score = 0 , this.asleep = 0;

    @override
    String toString() {
        return "agent ${this.sun}/${this.score}";
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
    Node? best;
    int n = 0;

    List<Cell> cell = List.generate( 37 ,
    (i) => new Cell( inputs : ['0','0','0','0','0','0','0','0'] ) , growable : false);

    List<Agent> player = List.generate( 2 ,
    (i) => new Agent() , growable : false );

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
        player[kMINE].day = parse(read());
        // the game lasts 24 days: 0-23
        player[kMINE].nutrients = parse(read());
        // the base score you gain from the next COMPLETE action

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

        //  Warning
        if( best != null && best.f == complete )
        {
            tree[ best.p.last ] = new Tree(inputs: ['${best.p.last}','0','-1','0'] );
        }

        n = parse(read()); // all legal actions
        for (int i = 0; i < n ; i++) {
            List<String> _ = read().split(' ');
            //error(_);
        }

        //  State
        List<Node> q = state( kMINE , cell , player , tree );
        List<Node> o = state( kOPP , cell , player , tree );

        for( final _ in q )
        {
            //error("DEBUG >> MINE ${player[kMINE].sun} ${_.cost} $_");
            ;
        }

        //  Delete wait
        o.removeLast();
        List<int> id2 = [];
        for( final _ in o )
        {
            //error("DEBUG >> OPP ${player[kOPP].sun} ${_.cost} $_");
            id2.add( _.p.last );
            ;
        }

        List<int> m = [];

        best = q.last;    //  Choose wait
        int best_score = 0;

        //q.last.p.removeLast();

        error("DAY ${player[kMINE].day} SUN ${player[kMINE].sun} SCORE ${player[kMINE].score}");

        for( final _ in q )
        {
            int k = 0;
            if( _.f == seed )
            {
                k = heuristic2( h_seed , id2 , _ , cell , player , tree );
            }
            if( _.f == grow )
            {
                k = heuristic2( h_grow , id2 , _ , cell , player , tree );
            }
            if( _.f == complete )
            {
                k = heuristic2( h_over , id2 , _ , cell , player , tree );
            }
            if( _.f == wait )
            {
                k = heuristic2( h_wait , id2 , _ , cell , player , tree );
                _.p.removeLast();
            }
            if( k > best_score )
            {
                best = _;
                best_score = k;
            }
            m.add( k );
        }

        error(m);
        print(best);

        //  Out
        //...

        // GROW cellIdx | SEED sourceIdx targetIdx | COMPLETE cellIdx | WAIT <message>
        //print('WAIT');
    }
}
