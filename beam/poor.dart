import 'dart:io';
import 'dart:math';
import 'dart:collection';

var error = stderr.writeln, parse = int.parse, line = stderr.write;
final int kM = 1 , kO = 0;
final int kG = 0 , kC = 1, kS = 2, kW = 3;
final List<String> kORDER = ["GROW","COMPLETE","SEED","WAIT"];
final int kB = 3;
final int kLIMIT_START = 700, kLIMIT_TURN = 70;
final List<int> kCOST = [ 0 , 1 , 3 , 7 , 4 ];
final List<int> kFUZZY = [ 7 , 3 , 3 , 0 ];

//  Time
Stopwatch stopwatch = new Stopwatch();
int rtStart = 0, rtEnd = 0, rtPrint = 0;
int rtTime = kLIMIT_START;
int nbChild = 0;
int turn = 0;

String read() {
  String? s = stdin.readLineSync();
  return s == null ? '' : s;
}

List<Field>     mapFields = [];

class Sakura
{
    int private = 0;

    int get cellIndex => private & 0x3f;
    int get size => (private >> 6) & 0x3;
    int get isMine => (private >> 8) & 0x1;
    int get isDormant => (private >> 9) & 0x1;
    void set cellIndex( int d ) => private = private & 0x3c0 | d;
    void set size( int d ) => private = private & 0x33f | (d << 6);
    void set isMine ( int d ) => private = private & 0x2ff | (d << 8);
    void set isDormant ( int d ) => private = private & 0x1ff | (d << 9);

    Sakura( int c , int s , int m ) { this.private = c | ( s << 6 ) | (m << 8); }
    Sakura.fromSakura( Sakura _ ) { this.private = _.private; }

    void seeds( NatureSpirit _ , List<int> i ) {
        int isMine = i[1];
        _.agent[isMine].nextSeed = i[3];
        this.isDormant = 1; }
        //_.agent[isMine].fuzzy -= _.agent[isMine].getCost(0); }

    void grows( NatureSpirit _ , List<int> i ) {
        int isMine = i[1];
        int bill = _.agent[isMine].getCost(this.size);
        _.agent[isMine].sun -= bill;
        _.agent[isMine].decCost(this.size++);
        this.isDormant = 1;
        _.agent[isMine].fuzzy +=  2 * kFUZZY[ kG ] - bill; }

    void completes( NatureSpirit _ , List<int> i ) {
        int isMine = i[1];
        _.agent[isMine].sun -= 4;
        _.agent[isMine].fuzzy += 2 * kFUZZY[ kC ] - 4;

        int indexStack = _.map[ this.cellIndex ]!;

        _.treeTop[isMine] = _.treeTop[isMine] + ( 2 * isMine - 1 );
        _.boardTree[indexStack] = _.boardTree[ _.treeTop[isMine] ];
        int replaceCellIndex = _.boardTree[ _.treeTop[isMine] ]!.cellIndex;

        _.map[ replaceCellIndex ] = indexStack;
        _.map.remove( this.cellIndex ); }

    void turns( NatureSpirit _ , List<int> i ) {
        final List<Function> kFUN = [grows, completes, seeds ];
        kFUN[ i[0] ]( _ , i ); }

    @override
    String toString() => "(${this.cellIndex},${this.size},${this.isMine},${this.isDormant})";
}

void updateAction( SplayTreeMap<int,List<int>> m , List<int> a , int k )
{
    //  WAIT and SEED has ZERO gain
    k = -10 * k;
    while( m.containsKey( k ) ) k--;
    m[k] = a;
}

List<SplayTreeMap<int,List<int>>> predict( NatureSpirit g )
{
    SplayTreeMap<int,List<int>> mpa = new SplayTreeMap<int,List<int>>();
    SplayTreeMap<int,List<int>> opa = new SplayTreeMap<int,List<int>>();
    List<SplayTreeMap<int,List<int>>> pAction = [ opa , mpa ];
    List<int> friendly = [ 0x1fffffff , 0x1fffffff ];

    //for( MapEntry e in g.map.entries )
    //    int cellIndex = e.key , indexStack = e.value;

    opa[ g.agent[kO].fuzzy ] = [ kW , kO ];
    mpa[ g.agent[kM].fuzzy ] = [ kW , kM ];

    for( int indexStack in g.map.values ) {
        Sakura t = g.boardTree[indexStack]!;

        friendly[ t.isMine ] &= mapFields[ t.cellIndex ].friend;
        friendly[ 1 - t.isMine ] &= ~(1 << t.cellIndex);

        if( g.agent[ t.isMine ].wait == 1 ) {
            continue; }

        if( t.isDormant == 1 ) {
            continue; }

        if( t.size < 3 ) {
            int bill = g.agent[ t.isMine].getCost(t.size+1);
            if( bill <= g.agent[t.isMine].sun ) {
                int K   = g.agent[ t.isMine ].fuzzy + 2 * kFUZZY[ kG ] - bill;
                updateAction( pAction[ t.isMine ] , [kG , t.isMine , t.cellIndex ], K );} }

        else
            if( 4 <= g.agent[t.isMine].sun ) {
                int K   = g.agent[ t.isMine ].fuzzy + 2 * kFUZZY[ kC] - 4;
                updateAction( pAction[ t.isMine ] , [kC , t.isMine , t.cellIndex ], K );}}

    for( int indexStack in g.map.values ) {
        Sakura t = g.boardTree[indexStack]!;
        int seedling = 0, bill = g.agent[t.isMine].getCost(0);

        if( g.agent[ t.isMine ].wait == 1 )
            continue;

        if( t.size == 2 && bill <= g.agent[t.isMine].sun )
            seedling    = friendly[t.isMine]
                        & mapFields[t.cellIndex].seedling[0]; else
        if( t.size == 3 && bill <= g.agent[t.isMine].sun )
            seedling    = friendly[t.isMine]
                        &( mapFields[t.cellIndex].seedling[0]
                        | mapFields[t.cellIndex].seedling[1] );

        for( int i = 0 ; i < 37 ; i++ ) {
            if( seedling & 1 == 1 ) {
                int K   = g.agent[ t.isMine ].fuzzy + 2 * kFUZZY[ kS ] - bill;
                updateAction( pAction[ t.isMine ] , [kS , t.isMine , t.cellIndex , i ] , K ); }
            seedling = seedling >> 1; } }

    return pAction;
}

class Agent
{
    static final int kSTART =  0 | (1 << 5) | (3 << 10) | (7 << 15);
    int private = 0;

    int get sun => private & 0xff;
    int get score => (private >> 8) & 0xff;
    int get wait => (private >> 24) & 0x01;
    int get nextSeed => (private >> 16) & 0x3f;
    void set sun( int d ) => private = private & 0x13fff00 | d;
    void set score( int d ) => private = private & 0x13f00ff | (d << 8);
    void set wait( int d ) => private = private & 0x03fffff | (d << 24);
    void set hardsun( int d ) => private = private & 0x03fff00 | d;
    void set nextSeed( int d ) => private = private & 0x100ffff | (d << 16);

    int private2 = kSTART;

    int getCost( int index ) => ( private2 >> (5 * index) ) & 0x1f;
    void incCost( int index ) => private2 = private2 + 1 << (5 * index);
    void decCost( int index ) => private2 = private2 - 1 << (5 * index);

    int fuzzy = 0;
    //int get fuzzy => private2 >> 20;
    //void set fuzzy( int d ) => private2 = private2 & 0xfffff | (d << 20);

    Agent( {required int d }) : this.private = d ;
    Agent.fromAgent(Agent _) : this.private = _.private ;
    @override
    String toString() => "($sun,$score,$wait)";

}

class NatureSpirit
{
    //  Optimization <cellIndex,indexStack>
    Map<int,int> map = new SplayTreeMap<int,int>();

    //  Factorization
    List<int> treeTop = [ 0 , 0 ];

    //  Memcopy
    int day = 0, nutrients = 0;
    late List<Agent> agent ;

    List<Sakura?> boardTree = [
    null , null , null , null , null , null , null , null , null , null, null , null ,
    null , null , null , null , null , null , null , null , null , null, null , null ,
    null , null , null , null , null , null , null , null , null , null, null , null , null ];

    int get oppTreeTop  => treeTop[ kO ];
    int get mineTreeTop => treeTop[ kM ];
    void set oppTreeTop ( int d ) => treeTop[ kO ] = d;
    void set mineTreeTop ( int d ) => treeTop[ kM ] = d;

    //  Variable for Beam
    //  Variable for Simulatioon
    int complete = 0;

    @override
    String toString() {
        String out = "";
        for( int i = 0 ; i < 37 ; i++ )
        {
            if( i == this.oppTreeTop ) {
                i = this.mineTreeTop + 1;
                out = "$out\n";
            }
            out = "$out $i[${(this.boardTree[i])}]";
        }
        return out;
    }

    NatureSpirit( ) : this.agent = [ new Agent( d : 0 ) , new Agent( d : 0 ) ];

    NatureSpirit.fromNatureSpirit(NatureSpirit _) {

        this.day = _.day;
        this.nutrients = _.nutrients;
        this.agent = [ new Agent.fromAgent( _.agent[0]) , new Agent.fromAgent( _.agent[0] ) ];
        this.mineTreeTop = _.mineTreeTop;
        this.oppTreeTop = _.oppTreeTop;

        _.map.forEach( (int k, int v) {
            this.map[k] = v ;
            this.boardTree[ v ] = new Sakura.fromSakura( _.boardTree[ v ]! ) ;
        } ); }

    void predictSum( List<int> r , int d , List<int> week ) {
        List<int> shadows = [ Field.kFOG , Field.kFOG , Field.kFOG ];

        for( final e in this.map.entries ) {
            Sakura t = this.boardTree[e.value]!;
            Field f = mapFields[e.key];

            for( int s = 0 ; s < 3 ; s++ ) {
                if( s < t.size )
                    shadows[s] &= f.shadows[d][s];
                else
                    break; } }

        for( int indexStack in this.map.values ) {
            Sakura t = this.boardTree[indexStack]!;

            if( t.size == 0 )
                continue;
            int compute = (1 << t.cellIndex) & ( shadows[ t.size - 1] );
            if( compute != 0 )
                r[t.isMine] = r[t.isMine] + t.size * week[d]; } }

    void resolveSeed() {
        if( this.agent[kO].nextSeed == this.agent[kM].nextSeed ) {
            this.agent[kO].nextSeed = 40;
            this.agent[kM].nextSeed = 41; }

        else {
            for( int o = 0 ; o < 2 ; o++ ) {
                if( this.agent[o].nextSeed > 36 )
                    continue;

                int cellIndex = this.agent[o].nextSeed, indexStack = this.treeTop[o];
                Sakura t = new Sakura( cellIndex , 0, o );

                int cost = this.agent[o].getCost(0);
                this.agent[o].fuzzy += 2 * kFUZZY[ kS ] - cost;
                this.agent[o].sun -= cost;
                this.agent[o].incCost(0);
                this.boardTree[ indexStack ] = t;
                this.map[cellIndex] = indexStack;
                this.treeTop[o] = this.treeTop[o] - 2 * o + 1;
                this.agent[o].nextSeed = 40 + o; } } }

    void reset() {
        this.map = new SplayTreeMap<int,int>();
        this.boardTree = [
        null , null , null , null , null , null , null , null , null , null, null , null ,
        null , null , null , null , null , null , null , null , null , null, null , null ,
        null , null , null , null , null , null , null , null , null , null, null , null , null ];        this.oppTreeTop = 0;
        this.oppTreeTop = 0;
        this.mineTreeTop = 36; }

    void updateSun( List<String> i ) {
        if( i.length == 2 ) {
            this.agent[kM].hardsun = parse(i[0]);
            this.agent[kM].score = parse(i[1]); }
        else {
            this.agent[kO].sun = parse(i[0]);
            this.agent[kO].score = parse(i[1]);
            this.agent[kO].wait = parse(i[2]); } }

    void updateTree( List<String> i )
    {
        Sakura t = new Sakura( parse(i[0]) , parse(i[1]) , parse(i[2]) )..isDormant = parse(i[3]);

        this.agent[ t.isMine ].incCost( t.size );
        int indexStack = this.treeTop[ t.isMine ];
        this.boardTree[ indexStack ] = t;
        this.map[ t.cellIndex ] = indexStack;
        this.treeTop[ t.isMine ] += - 2 * t.isMine + 1;
    }

    void simuDay() {
        this.nutrients = this.nutrients - this.complete;
        this.complete = 0;
        this.day++;
        int d = (this.day % 6);
        List<int> sun = [ this.agent[kO].sun , this.agent[kM].sun ];
        this.predictSum( sun , d , [ 1 , 1 , 1 , 1 , 1 , 1 ] );
        this.agent[kO].hardsun = sun[kO];
        this.agent[kM].hardsun = sun[kM];

        for( int indexStack in this.map.values ) {
            this.boardTree[indexStack]!.isDormant = 0; } }

    bool simuTurn( List<int> mine , List<int> opp ) {
        bool isNewDay = true;
        if( mine[0] == kW )
            this.agent[ mine[1] ].wait = 1;
        else {
            this.boardTree[ this.map[ mine[2] ]! ]!.turns( this , mine );
            isNewDay = false; }

        if( opp[0] == kW )
            this.agent[ opp[1] ].wait = 1;
        else {
            this.boardTree[ this.map[ opp[2] ]! ]!.turns( this , opp );
            isNewDay = false; }

        this.resolveSeed();
        return isNewDay ; }
}

class Field
{
    static final int kFOG = 0x1fffffffff;
    int friend = ~0 ;
    List<int> seedling = [ 0 , 0 ];
    List<List<int>> shadows = [
    [ kFOG , kFOG , kFOG ] , [ kFOG , kFOG , kFOG ] , [ kFOG , kFOG , kFOG ] ,
    [ kFOG , kFOG , kFOG ] , [ kFOG , kFOG , kFOG ] , [ kFOG , kFOG , kFOG ]
    ];
    int index = 0, richness = 0;
    List<int> neigh = [];

    Field( {required List<String> i} ) {
        this.index = parse(i[0]);
        this.richness = (parse(i[1]) - 1) * 2;
        i.add( i[2] );
        this.neigh = List.generate( 7 , (j) => parse(i[j+2]) , growable : false );
        this.friend = 0x1fffffffff & ~(1 << this.index);
    }

    void memoizationFog( List<Field> fields ) {
        //  Update shadows (size - 1)
        for( int day = 0 , size = 0 ; day < 6 ; day++ , size = 0 ) {
            int next = this.neigh[ day ];
            if( next == -1 )
                break;
            Field current = fields[next];

            for( next = this.neigh[day] ; size < 3 ; size++ , next = current.neigh[day] ) {
                if( next != -1 ) {
                    current = fields[next];
                    break; }
                this.shadows[day][size] &= ~(1 << next); } } }

    void memoization(List<Field> fields) {
        //  Update seedling
        for( int day = 0 ; day < 6 ; day++ )
        {
            int next1 = this.neigh[day];
            if( next1 == -1 )   continue;
            int next2 = fields[next1].neigh[day + 1];
            if( next2 == -1 )   continue;
            if( fields[next2].richness >= 0 )
                this.seedling[0] = (1 << next2 ) | this.seedling[0];

            next1 = fields[next2].neigh[day];
            if( next1 != -1 )
            {
                if( fields[next1].richness >= 0 )
                    this.seedling[1] = (1 << next1 ) | this.seedling[1];
            }
            next1 = fields[next2].neigh[day+1];
            if( next1 != -1 )
            {
                if( fields[next1].richness >= 0 )
                    this.seedling[1] = (1 << next1 ) | this.seedling[1];
            }
        }

        //  Update friend and seedling
        for( int day = 0 ; day < 6 ; day++ )
        {
            Field _ = this;
            int next = _.neigh[day];
            for( int s = 0 ; s < 3 ; s++ )
            {
                if( next == -1 )    break;
                this.friend = ~(1 << next) & this.friend;
                next = fields[next].neigh[day];
            }
        }
    }
}

class Tree {

    Tree? parent = null;
    late NatureSpirit game;
    List<List<Tree?>> child = [
        [ null , null , null ] , [ null , null , null ] , [ null , null , null ] ];

    String chosen( List<int> i ) {
        final List<Function> kFUN = [printg, printc , prints , printw ];
        return kFUN[i[0]](i);
    }

    String printg(List<int> i) => "GROW ${i[2]}";
    String printc(List<int> i) => "COMPLETE ${i[2]}";
    String prints(List<int> i) => "SEED ${i[2]} ${i[3]}";
    String printw(List<int> i) => "WAIT";

    String choosed() => 'WAIT';

    //  MCTS
    //List<int> mcts_w1 = [], mcts_w2 = [], mcts_n1 = [], mcts_n2 = [];

    //  Beam
    //List<int> beam_sum1 = [] , beam_sum2 = [] , beam_n1 = [] , beam_n2 = [];

    List<int> mine = [];
    List<int> opp = [];

    //  Best three action determined by predict 3 x 3
    late SplayTreeMap<int,List<int>> minePredictAction ;
    late SplayTreeMap<int,List<int>> oppPredictAction ;

    @override
    String toString() {
        return "[${this.game.day},${this.mine}]";
    }

    Tree( {required NatureSpirit g } )
    {
        this.game = new NatureSpirit.fromNatureSpirit(g);

    }

    void updateHeap( SplayTreeMap t )
    {
        int b = 10 * (this.game.agent[kO].fuzzy - this.game.agent[kM].fuzzy);
        error("HEAP $b ${this.game.agent[kO].fuzzy} ${this.game.agent[kM].fuzzy}");
        while( t.containsKey(b) )   b--;
        t[b] = this;
    }

    void updateScoring( SplayTreeMap t )
    {
        Function predictSum = this.game.predictSum;
        late int scoring;
        //  Scoring
        int nWeek = (this.game.day ~/ 6) * 6;
        int nDay = (23 - this.game.day) ~/ 6;
        List<int> week = [ nDay , nDay , nDay , nDay , nDay , nDay ];

        for( int nRest = this.game.day - nWeek + 1 ; nRest < 6 ; nRest++ )
            week[nRest]++;

        List<int> renting = [ 0 , 0 ] ;
        for( int day = 0 ; day < 6 ; day++ ) {
            predictSum( renting , day , week ); }

        List<int> richning = [ 0 , 0 ];
        List<int> score = [ 0 , 0 ];
        for( int o = 0 ; o < 2 ; o++ )
            score[o]   = this.game.agent[o].score * 3
                        + this.game.agent[o].sun
                        + renting[o]
                        + richning[o];

        scoring = 2000 - score[kM] + score[kO];

        //  Add in heap
        t[scoring] = this;
    }

}

void resolveNode( int end , Tree g , SplayTreeMap bst , SplayTreeMap brt )
{
    late Tree node = g , child;

    List _ = predict( node.game );

    if( stopwatch.elapsedMilliseconds >= rtTime )
        return;

    node.minePredictAction = _[kM];
    node.oppPredictAction = _[kO];

    for( int m1 = 0 ; m1 < 3 ; m1++ ) {
        if( node.minePredictAction.length == 0 )
            break;

        int key = node.minePredictAction.firstKey()!;
        List<int> mine = node.minePredictAction[key]!;
        node.minePredictAction.remove( key );

        for( int o1 = 0 ; o1 < 3 ; o1++ ) {
            if( node.oppPredictAction.length == 0 )
                break;

            int key = node.oppPredictAction.firstKey()!;
            List<int> opp = node.oppPredictAction[key]!;
            node.oppPredictAction.remove( key );

            rtStart = stopwatch.elapsedMilliseconds;

            child =
            new Tree( g : node.game)..mine = mine..opp = opp..parent = node ;

            rtEnd = stopwatch.elapsedMilliseconds;

            if( stopwatch.elapsedMilliseconds >= rtTime )
                break;

            if( child.game.simuTurn( child.mine , child.opp ) == true ) {
                child.game.simuDay(); }

            if( stopwatch.elapsedMilliseconds >= rtTime )
                break;

            if( child.game.day == end ) {
                child.updateScoring( brt ); }
            else {
                child.updateHeap( bst ); }

            node.child[m1][o1] = child;

            nbChild++;
            if( stopwatch.elapsedMilliseconds >= rtTime )
                break; }

        if( stopwatch.elapsedMilliseconds >= rtTime )
            break; }

}

void main()
{
    //  Needs fields
    mapFields = List.generate( 37 , (j) => new Field( i : ["0","0","0","0","0","0","0","0"] ) , growable : false );

    SplayTreeMap beamSearchTree = new SplayTreeMap<int,Tree>();
    SplayTreeMap beamBestResult = new SplayTreeMap<int,Tree>();
    NatureSpirit game = new NatureSpirit();
    Tree node = new Tree( g: game );
    int n = 0;

    n = parse(read());
    for (int i = 0; i < n; i++)
        mapFields[i] = new Field( i : read().split(' ') );
    for (int i = 0; i < n; i++) {
        mapFields[i].memoization( mapFields );
        mapFields[i].memoizationFog( mapFields ); }

    stopwatch.start();
    while (true)
    {
        //  Restart stopwatch after first read
        //  Update Game
        game.day = parse(read());
        game.nutrients = parse(read());
        game.updateSun( read().split(' ') );
        game.updateSun( read().split(' ') );

        n = parse(read());

        //  Update Tree
        game.reset();
        for (int i = 0; i < n ; i++)
            game.updateTree( read().split(' ') );

        n = parse(read());
        for (int i = 0; i < n ; i++)
            var _ = read().split(' ');

        stopwatch.reset();
        turn++;
        node = new Tree( g: game );

        beamSearchTree = new SplayTreeMap<int,Tree>();
        beamBestResult = new SplayTreeMap<int,Tree>();
        node.updateHeap( beamSearchTree );

        int end = min(game.day + 3,24);

        Queue<Tree> beam = new Queue<Tree>();
        while( stopwatch.elapsedMilliseconds < rtTime ) {
            //break;

            late Tree current;
            if( beamSearchTree.length == 0 )
                break;

            for( int i = 0 ; i < min( 3, beamSearchTree.length ) ; i++ ) {
                int key = beamSearchTree.firstKey();
                beam.add( beamSearchTree[key] );
                beamSearchTree.remove( key ); }

            for( int i = 0 ; i < beam.length ; i++ ) {
                if( stopwatch.elapsedMilliseconds >= rtTime )
                    break;
                current = beam.removeFirst();
                resolveNode( end , current , beamSearchTree , beamBestResult ); } }


        late int key;
        late Tree chosen;
        //  Find best result
        if( beamBestResult.length == 0 )
        {
            key = beamSearchTree.firstKey();
            chosen = beamSearchTree[key];
            error("NOT FOUND $key $chosen ${chosen.mine}");
        }
        else
        {
            key = beamBestResult.firstKey();
            chosen = beamBestResult[key];
        }
        while( chosen.parent != null  )
        {
            Tree next = chosen.parent ?? chosen;
            if( next.mine.length > 0 )
                chosen = next;
            else
                break;
        }

        //  Out
        //print( "${chosen.chosen(chosen.mine)} [${rtStart},${rtEnd},${stopwatch.elapsedMilliseconds},${beamBestResult.length},$end,$key]" );
        //print( "${chosen.chosen(chosen.mine)} [${rtStart},${rtEnd},${stopwatch.elapsedMilliseconds},$key]" );
        rtPrint = stopwatch.elapsedMilliseconds;
        print( "${chosen.chosen(chosen.mine)} [${nbChild},${rtStart},${rtEnd},${rtPrint}]" );

        //print( "WAIT");

        rtTime = kLIMIT_TURN;
    }
}
