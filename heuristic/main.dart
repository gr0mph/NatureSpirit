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
final List<String> kSTRSTATE = ["STARTING","FARMING","NOISING","SCORING","ENDING"];

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
                n = new Node(f: complete, a:"COMPLETE" , p: [ c.index] )..cost = 4..heuristic = h_complete;
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

List<int> renting2(Node ? n, int day , List<Cell> cell, List<Agent> player, List<Tree> tree)
{
    List<int> r = [ 0 , 0 ];
    int node_hex = -1, node_isMine = -1, node_size = 0, node_gain = 0;
    int tree_isMine = -1 , tree_size = 0, tree_gain = 0;
    int debug = 0;

    if( n != null )
    {
        node_hex = n.p.last;
        node_isMine = tree [ n.p.first ].isMine;
        node_size = tree [ n.p.last ].size + 1;
        if( n.turn == seed )    node_gain = 1;        //  Counter balance a simple GROW.
        else                    node_gain = node_size;

        if( n.turn == complete )
        {
            node_isMine = -1;
            node_size = 0;
        }

        //if( n.turn == seed )
        //{
        //error("node hex $node_hex isMine $node_isMine size $node_size $n");
        //    debug = 1;
        //}
    }

    for( final start in kSIMSUN[day] )
    {
        List<int> shadow = [ 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 ];
        int hex = start;
        int i1 = 0;
        while( hex != -1 )
        {
            if( node_hex == hex )
            {
                tree_isMine = node_isMine;
                tree_size = node_size;
                tree_gain = node_gain;
                //if( debug == 1 )
                //error("tree isMine $tree_isMine size $tree_size");
            }
            else
            {
                tree_isMine = tree[hex].isMine;
                tree_size = tree[hex].size;
                tree_gain = tree[hex].size;
            }

            //  Income
            if( tree_size > shadow[i1] )
                r[ tree_isMine ] = r[ tree_isMine ] + tree_gain;

            //  Update shadow
            if( tree_size > 0 )
                for( int i2 = 1 ; i2 < 1 + tree_size ; i2++ )
                    shadow[ i1 + i2 ] = max( shadow[i1 + i2] , tree_size );

            //  Neighboor
            hex = cell[hex].neighboor[day];
            i1++;
        }
    }
    //if( debug == 1 )
    //    error(r);

    return r;
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

    //  Check F.S.M
    if( player[p1].state == STARTING )
    {
        if( player[p1].day == 0 )   return k;
        if( player[p1].day == 1 )   return k;   //  à corriger
    }

    if( player[p1].state == ENDING )
    {
        //if( n.cost == 0 && cell[id1].richness == 3 && player[p1].day < 20 )
    //    if( cell[id1].richness == 3 && player[p1].day < 20 )
    //    {
    //        k[p1] = k[p1] + 3 * (player[p1].nutrients + 2 * cell[id1].richness);
    //    }
        return k;
    }

    if( player[p1].day > 20 )
        return k;

    if( n.cost != 0 )
        return k;

    int nbTreeIsMine = 0;
    for( final _ in tree )
        if( _.isMine == kMINE )
            nbTreeIsMine++;

    //  Update cost, sun is point , no sun no point
    if( player[p1].state == NOISING || player[p1].state == STARTING )
    {
        //k[p1] = k[p1] - cell[id1].richness;
        ;
    }
    else
    {
        k[p1] = k[p1] + ( cell[id1].richness - 1 ) * 2 * 3;
    }

    for( int d = 0 ; d < 6 ; d++ )
    {
        int hex = cell[n.p.last].neighboor[d];
        if( hex == -1 ) continue;
        if( tree[ hex ].isMine == kMINE )
            k[p1] = k[p1] - 10;
        hex = cell[hex].neighboor[d];
        if( hex == -1 ) continue;
        if( tree[ hex ].isMine == kMINE )
            k[p1] = k[p1] - 7;
        hex = cell[hex].neighboor[d];
        if( hex == -1 ) continue;
        if( tree[ hex ].isMine == kMINE )
            k[p1] = k[p1] - 3;
    }

    int delay_day = player[p1].day + 1;
    int nWeek = delay_day ~/ 6;
    int nDay = (23 - delay_day) ~/6;
    List<int> week = [ nDay , nDay , nDay , nDay , nDay , nDay ];
    List<int> rent = [0,0];

    for( int nRest = delay_day - nWeek * 6 + 1 ; nRest < 6 ; nRest++ )
    {
        week[nRest]++;
    }

    List<int> income = renting2( null , (delay_day % 6) , cell , player , tree );
    rent[kOPP] = rent[kOPP] + income[kOPP];
    rent[kMINE] = rent[kMINE] + income[kMINE];

    for( int day = 0 ; day < 6 ; day++ )
    {
        income = renting2( n , day , cell , player , tree );

        rent[kOPP] = rent[kOPP] + income[kOPP] * week[day];
        rent[kMINE] = rent[kMINE] + income[kMINE] * week[day];
    }

    error("");
    error("h_seed k $k rent $rent");
    error("kOPP rent ${player[kOPP].renting}");
    error("kMINE rent ${player[kMINE].renting}");

    k[kMINE] = k[kMINE] + rent[kMINE] - player[kMINE].renting;
    k[kOPP] = k[kOPP] + rent[kOPP] - player[kOPP].renting;

    //if( k[kMINE] - k[kOPP] <= 5 )
    //    k = [ 0 , 0 ];

    //error("[${id1}] >> grow k ${k} id2 ${id2}");
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
        if( tree[id1].size == 0 && player[p1].day < 21 )
        {
            k[p1] = k[p1] + 3 * (player[p1].nutrients + 2 * (cell[id1].richness - 1) );
        }
        else
        if( tree[id1].size == 1 && player[p1].day < 22 )
        {
            k[p1] = k[p1] + 3 * (player[p1].nutrients + 2 * (cell[id1].richness - 1) );
        }
        else
        if( tree[id1].size == 2 && player[p1].day < 23 )
        {
            k[p1] = k[p1] + 3 * (player[p1].nutrients + 2 * (cell[id1].richness - 1) );
        }
        return k;
    }

    k[p1] = k[p1] - n.cost + kGROW[ tree[ n.p.last ].size + 1 ];

    int nWeek = player[p1].day ~/ 6;
    int nDay = (23 - player[p1].day) ~/6;
    List<int> week = [ nDay , nDay , nDay , nDay , nDay , nDay ];
    List<int> rent = [0,0];

    for( int nRest = player[p1].day - nWeek * 6 + 1 ; nRest < 6 ; nRest++ )
    {
        week[nRest]++;
    }

    for( int day = 0 ; day < 6 ; day++ )
    {
        List<int> income = renting2( n , day , cell , player , tree );
        rent[kOPP] = rent[kOPP] + income[kOPP] * week[day];
        rent[kMINE] = rent[kMINE] + income[kMINE] * week[day];
    }

    k[kMINE] = k[kMINE] + rent[kMINE] - player[kMINE].renting;
    k[kOPP] = k[kOPP] + rent[kOPP] - player[kOPP].renting;

    //error("[${id1}] >> grow k ${k} id2 ${id2}");
    return k;
}

List<int> h_wait(
    int p1 , int p2 , int id1 , List<int> id2 ,
    Node n , List<Cell> cell , List<Agent> player , List<Tree> tree )
{
    List<int> k = [ 0 , 1 ];
    //k[p1] = player[p1].sun;
    //error("[${id1}] >> wait k ${k}");
    return k;
}

List<int> h_complete(
    int p1 , int p2 , int id1 , List<int> id2 ,
    Node n , List<Cell> cell , List<Agent> player , List<Tree> tree )
{
    List<int> k = [ 0 , 0 ];

    if( player[p1].state == ENDING )
    {
        if( cell[id1].richness == 3 )
        {
            k[p1] = k[p1] + 3 * (player[p1].nutrients + 2 * cell[id1].richness);
        }

        if( player[p1].day == 23 )
        {
            k[p1] = k[p1] + 3 * (player[p1].nutrients + 2 * cell[id1].richness);
        }
    }
    else
    if( player[p1].state == SCORING )
    {
        error("h complete SCORING");

        //k[p1] = k[p1] - 21;
        k[p1] = k[p1] + 3 * (player[p1].nutrients + 2 * ( cell[id1].richness - 1 ) );

        int nWeek = player[p1].day ~/ 6;
        int nDay = (23 - player[p1].day) ~/6;
        List<int> week = [ nDay , nDay , nDay , nDay , nDay , nDay ];
        List<int> rent = [0,0];

        for( int nRest = player[p1].day - nWeek * 6 + 1 ; nRest < 6 ; nRest++ )
        {
            week[nRest]++;
        }
        error(week);

        for( int day = 0 ; day < 6 ; day++ )
        {
            List<int> income = renting2( n , day , cell , player , tree );
            rent[kOPP] = rent[kOPP] + income[kOPP] * week[day];
            rent[kMINE] = rent[kMINE] + income[kMINE] * week[day];
            error("day $day income $income ${week[day]}");
        }

        error("[${player[kMINE].score*3},${player[kMINE].scoring},${player[kMINE].renting},${player[kMINE].sun}]");
        error("[${player[kOPP].score*3},${player[kOPP].scoring},${player[kOPP].renting},${player[kOPP].sun}]");

        k[kMINE] = k[kMINE] + rent[kMINE] - player[kMINE].renting;
        k[kOPP] = k[kOPP] + rent[kOPP] - player[kOPP].renting;
        error("k $k");
    }

    //error("[${id1}] >> over k ${k} id2 ${id2}");
    return k;
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
    int nbTree = 0;

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
        if( this.renting <= opp.renting ) this.state = NOISING;
        else
        if( this.scoring >= opp.scoring ) this.state = FARMING;
        else                              this.state = SCORING;

        //if( this.scoring >= opp.scoring )     this.state = FARMING;    //  GROW, SEED
        //else
        //if( this.renting >= opp.renting )     this.state = SCORING;    //  COMPLETE, WAIT
        //else                                  this.state = NOISING;

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

void main() {

    List inputs;
    Node? best;
    List<List<Node>> both = [];
    int n = 0;

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

        //  Update nb tree
        player[kMINE].nbTree = n;
        player[kOPP].nbTree = n;

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

        //renting( cell , player , tree );
        //player[kMINE].update_fsm( cell , player[kOPP] , tree );

        //debug = read(); error(debug);
        n = parse(read()); // all legal actions
        //n = parse(debug); // all legal actions

        for (int i = 0; i < n ; i++) {
            //debug = read(); error(debug);
            List<String> _ = read().split(' ');
            //List<String> _ = debug.split(' ');
        }

        //  Update more precise renting
        int nWeek = player[kMINE].day ~/ 6;
        int nDay = (23 - player[kMINE].day) ~/6;
        List<int> week = [ nDay , nDay , nDay , nDay , nDay , nDay ];
        List<int> rent = [ 0 , 0 ];

        for( int nRest = player[kMINE].day - nWeek * 6 + 1 ; nRest < 6 ; nRest++ )
        {
            week[nRest]++;
        }
        error("${player[kMINE].day} ${player[kMINE].nutrients} ${week}");

        for( int day = 0 ; day < 6 ; day++ )
        {
            List<int> income = renting2( null , day , cell , player , tree );
            rent[kMINE] = rent[kMINE] + income[kMINE] * week[day];
            rent[kOPP] = rent[kOPP] + income[kOPP] * week[day];
            error("income $income renting $rent");
        }
        player[kMINE].renting = rent[kMINE];
        player[kOPP].renting = rent[kOPP];

        player[kMINE].scoring = 3 * player[kMINE].score + (player[kMINE].sun + rent[kMINE]);
        player[kOPP].scoring = 3 * player[kOPP].score + (player[kOPP].sun + rent[kOPP]);

        player[kMINE].update_fsm( cell , player[kOPP] , tree );
        error("[${player[kMINE].score*3},${player[kMINE].scoring},${player[kMINE].renting},${player[kMINE].sun}]");
        error("[${player[kOPP].score*3},${player[kOPP].scoring},${player[kOPP].renting},${player[kOPP].sun}]");
        error("f_s_m_ ${player[kMINE].state} ${kSTRSTATE[ player[kMINE].state ]}");

        //  State
        List<Node> q = state( kMINE , cell , player , tree );
        List<Node> o = state( kOPP , cell , player , tree );
        List<int> id2 = [];
        List<int> m = [];

        best = q.last;    //  Choose wait
        int best_score = 0;

        String text = "[${player[kMINE].scoring},${player[kMINE].renting},${player[kOPP].scoring},${player[kOPP].renting}]";
        error(text);

        for( final _ in q )
        {
            List<int> kc =
            _.heuristic( kMINE , kOPP , _.p.last , id2 , _ , cell , player , tree );

            _.k = (kc[kMINE] - kc[kOPP]);

            if( _.turn == wait )
                _.p.removeLast();

            if( (kc[kMINE] - kc[kOPP]) > best_score )
            {
                best = _;
                best_score = (kc[kMINE] - kc[kOPP]);
            }
            error("${_.cost} : $_  state ${player[kMINE].state} score ${kc[kMINE] - kc[kOPP]}");
            m.add( (kc[kMINE] - kc[kOPP]) );
        }

        for( int i1 = 0 ; i1 < q.length - 1 ; i1++ )
        {
            for( int i2 = i1 + 1 ; i2 < q.length ; i2++ )
            {
                //List<Node> node_ij = [ q[i1] , q[i2] ];

                Node n1 = q[i1], n2 = q[i2];
                int cost = n1.cost + n2.cost;
                if( n1.turn == grow && n2.turn == grow && cost <= player[kMINE].sun )
                {
                    List<Node> tuple = [ n1 , n2 ];
                    both.add(tuple);
                }
            }
        }

        for( final _ in both )
        {
            if( _[0].k + _[1].k > best_score )
            {
                best = _[0].k >= _[1].k ? _[0] : _[1];
                best_score = _[0].k + _[1].k;
            }
        }
        both = [];

        error(m);

        //  Out
        print(best);
    }
}
