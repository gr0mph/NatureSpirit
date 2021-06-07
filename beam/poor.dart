import 'dart:io';
import 'dart:math';
import 'dart:collection';

var error = stderr.writeln, parse = int.parse, line = stderr.write;
final int kM = 1 , kO = 0;
final int kG = 0 , kC = 1, kS = 2, kW = 3;
final List<String> kORDER = ["GROW","COMPLETE","SEED","WAIT"];
final int kB = 3;
final int kLIMIT_START = 500, kLIMIT_TURN = 50;

//final List<List<int>> kGROW = [ [ 0 , 0 ], [ 1 , 1 ] , [ 3 , 3 ] , [ 7 , 7 ] ];
final List<int> kFUZZYBEAM = [ 00 , 10 , 30 , 70 , 40 ];
final List<int> kCOST = [ 0 , 1 , 3 , 7 , 4 ];

//  Time
Stopwatch stopwatch = new Stopwatch();
int rtStart = 0;
int rtEnd = 0;
int rtTime = kLIMIT_START;
int nbChild = 0;
int turn = 0;

String read() {
  String? s = stdin.readLineSync();
  return s == null ? '' : s;
}

List<Field>     mapFields = [];
List<List<int>> mapShadow = [];

class Sakura
{
    late int cellIndex, size, isMine;
    int isDormant = 0;

    Sakura( c , s , m ) : this.cellIndex = c, this.size = s, this.isMine = m;
    Sakura.fromSakura( Sakura _ ) : this.cellIndex = _.cellIndex , this.size = _.size ,
    this.isMine = _.isMine , this.isDormant = _.isDormant;

    void seeds( NatureSpirit _ , List<int> i )
    {
        int isMine = i[1];
        _.nextSeed[isMine] = i[3];
        this.isDormant = 1;
        _.fuzzyBeam[isMine] += - _.cost[isMine][0];
    }
    void grows( NatureSpirit _ , List<int> i )
    {
        int isMine = i[1];
        _.sun[isMine] -= _.cost[isMine][this.size++]--;
        this.isDormant = 1;
        _.fuzzyBeam[isMine] +=  kFUZZYBEAM[this.size] - (_.cost[isMine][this.size]++ - kCOST[this.size]);
    }
    void completes( NatureSpirit _ , List<int> i )
    {
        int isMine = i[1];
        _.sun[isMine] -= 4;
        _.fuzzyBeam[isMine] += 40;

        int i1 = _.map[ this.cellIndex ]!;

        _.treeTop[isMine] = _.treeTop[isMine] + ( -2 * isMine + 1 );
        _.boardTree[i1] = _.boardTree[ _.treeTop[isMine] ];
        int replaceCellIndex = _.boardTree[ _.treeTop[isMine] ]?.cellIndex ?? -1;

        _.map[ replaceCellIndex ] = i1;
        _.map.remove( this.cellIndex );
    }
    void waits( NatureSpirit _ , List<int> i )
    {
        int isMine = i[1];
        _.wait[isMine] = 1;
    }
    @override
    String toString() => "${this.cellIndex},${this.size},${this.isMine},${this.isDormant}";
}

class NatureSpirit
{
    //  Optimization
    Map<int,int> map = new SplayTreeMap<int,int>();

    //  Factorization
    List<int> treeTop = [ 0 , 0 ];
    List<List<int>> cost = [ [] , [] ];

    //  Memcopy
    int day = 0, nutrients = 0;
    List<int> sun = [ 0 , 0 ], score = [ 0 , 0 ], wait = [ 0 , 0 ], fuzzyBeam = [ 0 , 0 ] , scoring = [ 0 , 0 ];
    List<int> shadows = [ 0 , 0 , 0 ];

    List<int> oppCost = [ 0 , 1 , 3 , 7 ];
    List<int> mineCost = [ 0 , 1 , 3 , 7 ];
    List<Sakura?> boardTree = [
    null , null , null , null , null , null , null , null , null , null, null , null ,
    null , null , null , null , null , null , null , null , null , null, null , null ,
    null , null , null , null , null , null , null , null , null , null, null , null , null ];

    int oppTreeTop = 0;
    int mineTreeTop = 36;

    //  Variable for Beam
    //  Variable for Simulatioon
    int complete = 0;
    List<int> nextSeed = [ -2 , -1 ];

    int getCellIndex ( int tree ) => tree & 0x3f;
    int getSize( int tree ) => (tree >> 6) & 0x3;
    int getMine( int tree ) => (tree >> 8) & 0x1;
    int getDormant( int tree ) => (tree >> 9) & 0x1;

    int setSize( int tree , int s ) => (tree & 0x33f) | (s << 6);
    int setMine( int tree , int o ) => (tree & 0x2ff) | (o << 8);
    int setDormant( int tree , int d ) => (tree & 0x1ff) | (d << 9);

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

    NatureSpirit( ) {
        this.cost = [ this.oppCost , this.mineCost ];
        this.treeTop = [ this.oppTreeTop , this.mineTreeTop ];
    }

    NatureSpirit.fromNatureSpirit(NatureSpirit _) {

        this.day = _.day;
        this.nutrients = _.nutrients;
        this.sun.setRange(0 , 2 , _.sun ) ;
        this.score.setRange( 0 , 2 , _.score ) ;
        this.wait.setRange( 0 , 2 , _.wait ) ;
        this.fuzzyBeam.setRange( 0 , 2 , _.fuzzyBeam);
        this.shadows.setRange( 0 , 3 , _.shadows ) ;
        this.mineCost.setRange( 0 , 4 , _.mineCost ) ;
        this.oppCost.setRange( 0 , 4 , _.oppCost );
        this.mineTreeTop = _.mineTreeTop;
        this.oppTreeTop = _.oppTreeTop;

        this.cost = [ this.oppCost , this.mineCost ];
        this.treeTop = [ this.oppTreeTop , this.mineTreeTop ];
        _.map.forEach( (int k, int v) {
            this.map[k] = v ; this.boardTree[ v ] = new Sakura.fromSakura( _.boardTree[ v ]! ) ;
        } );
    }

    List<List<int>> predict(int own)
    {
        List<List<int>> action = [];
        int friendly = 0x1fffffffff;
        //friendly = friendly & ~this.mine;
        //friendly = friendly & ~this.opp;

        if( this.wait[own] == 1 )
        {
            action.add( [ kW , own ] );
            return action;
        }

        late List<int> lTree , cost;
        if( own == kO )
        {
            cost = this.oppCost;
            lTree = [for (int i = 0; i < this.oppTreeTop ;i++ ) this.boardTree[i] ];
        }
        else
        {
            cost = this.mineCost;
            lTree = [for (int i = 36; i > this.mineTreeTop ;i-- ) this.boardTree[i] ];
        }

        for( int i = 0 ; i < 37 ; i++ )
        {
            if( i == this.oppTreeTop )  i = this.mineTreeTop + 1;

            int t = getCellIndex( this.boardTree[i] );
            int s = getSize( this.boardTree[i] );
            int o = getMine( this.boardTree[i] );

            if( own == o )
            {
                if( getDormant( this.boardTree[i] ) != 0 )  continue;

                if( s < 3 )
                    if( cost[s+1] <= this.sun[own] )        action.add( [ kG , own , t ] );
                else
                    if( cost[3] <= this.sun[own] )          action.add( [ kC , own , t ] );
            }
            else
            {
                friendly = friendly & ~(1 << t);
            }
        }

        for( final int tree in lTree )
        {
            int t = getCellIndex(tree);
            int s = getSize(tree);
            int seedling = 0;

            if( getDormant(tree) != 0 )
                continue;

            if( s == 2 && cost[0] <= this.sun[own] )
                seedling = friendly & mapFields[t].seedling[2 - 2];
            if( s == 3 && cost[0] <= this.sun[own] )
                seedling = friendly & (mapFields[t].seedling[2 - 2] | mapFields[t].seedling[3 - 2]);

            //if( this.tree[2] & (1 << t) != 0 && cost[0] <= this.sun[o] )
            //{
            //    seedling = friendly & mapFields[t].seedling[2 - 2];
            //}
            //else if( this.tree[3] & (1 << t) != 0 && cost[0] <= this.sun[o] )
            //{
            //    seedling = friendly & (mapFields[t].seedling[2 - 2] | mapFields[t].seedling[3 - 2]);
            //}
            for( int i = 0 ; i < 37 ; i++ )
            {
                if( seedling & 1 != 0 ) {
                    action.add( [ kS , own , t , i ] );
                }
                seedling = seedling >> 1;
            }
        }
        action.add( [ kW , own ] );
        return action;
    }

    void predictSum( List<int> r , List<int> shadow , int d , List<int> week )
    {
        //int shadows = (shadow[ 1-1 ] | shadow[ 2 - 1 ] | shadow[ 3 - 1 ] );

        List<int> shadows = [
            ( shadow[ 1 - 1 ] | shadow[ 2 - 1 ] | shadow[ 3 - 1 ] ),
            ( shadow[ 2 - 1 ] | shadow[ 3 - 1 ] ),
            ( shadow[ 3 - 1 ] ),
        ];
        //for( int s = 1 ; s < 4 ; s++ )
        //{
        //    List<int> compute =
        //    [ this.tree[s] & this.opp & ~shadows , this.tree[s] & this.mine & ~shadows ];
        //    for( int i = 0 ; i < 37 ; i++ )
        //    {
        //        r[kO] = r[kO] + ( (compute[kO] & 1) * s ) * week[d];
        //        compute[kO] = compute[kO] >> 1;
        //
        //        r[kM] = r[kM] + ( (compute[kM] & 1) * s ) * week[d];
        //        compute[kM] = compute[kM] >> 1;
        //    }
        //    shadows = shadows & ~(shadow[s-1]);
        //}

        for( int i = 0 ; i < 37 ; i++ ) {

            if( i == this.oppTreeTop )  i = this.mineTreeTop + 1;

            int t = getCellIndex( this.boardTree[i] );
            int s = getSize( this.boardTree[i] );
            int o = getMine( this.boardTree[i] );

            if( s == 0 )                continue;

            int compute = (1 << t) & ~( shadows[ s - 1 ] ) ;
            if( compute != 0 )
            {
                r[o] = r[o] + s * week[d];
            }
        }

    }

    void resolveSeed()
    {
        if( this.nextSeed[kO] == this.nextSeed[kM] )
            ;
        else
        {
            for( int o = 0 ; o < 2 ; o++ )
            {
                if( this.nextSeed[o] < 0 )  continue;

                int nextTree = this.nextSeed[o];
                nextTree = setSize( nextTree , 0 );
                nextTree = setDormant( nextTree , 1 );
                nextTree = setMine( nextTree , o );

                //this.dormant = (1 << this.nextSeed[o]) | this.dormant;
                //this.tree[0] = (1 << this.nextSeed[o]) | this.tree[0];

                if( o == kO )
                {
                    this.sun[o] = this.sun[o] - this.oppCost[0];
                    this.oppCost[0]++;
                    this.boardTree[ this.oppTreeTop ] = nextTree;   //this.nextSeed[o];
                    this.oppTreeTop++;
                }
                else
                {
                    this.sun[o] = this.sun[o] - this.mineCost[0];
                    this.mineCost[0]++;
                    this.boardTree[ this.mineTreeTop ] = nextTree; // this.nextSeed[o];
                    this.mineTreeTop--;
                }

                //this.opp = (1 << this.nextSeed[o]) | this.opp;
                //  Update beam
                this.fuzzyBeam = this.fuzzyBeam - kFUZZYBEAM[o];
            }
        }
        ;
        this.nextSeed = [-2 , -1 ];
    }

    void reset()
    {
        ///this.tree = [ 0 , 0 , 0 , 0 ];
        //this.mine = 0;
        //this.opp = 0;
        //this.dormant = 0;
        this.mineCost = [ 0 , 1 , 3 , 7 ];
        this.oppCost = [ 0 , 1 , 3 , 7 ];
        this.boardTree = [ 0 , 0 , 0 , 0 , 0 , 0, 0 , 0 , 0 , 0 , 0 , 0, 0 , 0 , 0 , 0 , 0 , 0,
        0 , 0 , 0 , 0 , 0 , 0, 0 , 0 , 0 , 0 , 0 , 0, 0 , 0 , 0 , 0 , 0 , 0, 0 ];
        this.oppTreeTop = 0;
        this.mineTreeTop = 36;

        //  Beam update
        this.fuzzyBeam = 37 * kFUZZYBEAM[3] - this.score[kO] - this.score[kM];
    }

    void updateSun( List<String> i )
    {
        if( i.length == 2 ) {
            this.sun[kM] = parse(i[0]);
            this.score[kM] = parse(i[1]);
            this.wait[kM] = 0;
        }
        else {
            this.sun[kO] = parse(i[0]);
            this.score[kO] = parse(i[1]);
            this.wait[kO] = parse(i[2]);
        }
    }

    void updateTree( List<String> i )
    {
        int tree = parse(i[0]), s = parse(i[1]) , o = parse(i[2]) , d = parse(i[3]);
        //this.tree[s] = (1 << id) | this.tree[s];
        //this.dormant = (d << id) | this.dormant;
        tree = setSize( tree , s );
        tree = setMine( tree , o );
        tree = setDormant( tree , d );

        if( o == kM )
        {
            this.mineCost[s]++;
            this.boardTree[ this.mineTreeTop ] = tree; //id;
            this.mineTreeTop--;
            //this.mine = (1 << id) | this.mine;
        }
        else
        {
            this.oppCost[s]++;
            this.boardTree[ this.oppTreeTop ] = tree; //id;
            this.oppTreeTop++;
            //this.opp = (1 << id) | this.opp;
        }

        //  Beam update
        this.fuzzyBeam = this.fuzzyBeam - kFUZZYBEAM[s] ;
    }

    void simuDay()
    {
        this.nutrients = this.nutrients - this.complete;
        this.complete = 0;
        this.day++;
        int d = (this.day % 6);
        this.shadows = mapShadow[ d ];
        this.predictSum( this.sun , this.shadows , d , [ 1 , 1 , 1 , 1 , 1 , 1 ] );
        this.wait = [ 0 , 0 ];
        //this.dormant = 0;
        for( int i = 0 ; i < 37 ; i++ )
        {
            if( i == this.oppTreeTop )  i = this.mineTreeTop + 1;
            this.boardTree[i] = setDormant( this.boardTree[i] , 0 );
        }
    }

    bool simuTurn( List<int> mine , List<int> opp )
    {
        final List<Function> kFUN = [grows, completes, seeds, waits];
        kFUN[ mine[0] ]( mine );
        kFUN[ opp[0] ]( opp );
        resolveSeed();
        return this.wait[kO] == 1 && this.wait[kM] == 1 ? true : false ;
    }

    void grows( List<int> i )
    {
        int own = i[1], t1 = i[2];

        if( own == kO )
        {
            int i = this.boardTree.lastIndexWhere( (e) => getCellIndex(e) == t1 );
            int s = getSize( this.boardTree[i] );

            this.sun[own] = this.sun[own] - this.oppCost[s+1];
            this.oppCost[s+1]++;
            this.oppCost[s]--;
            this.boardTree[i] = setSize( this.boardTree[i] , s + 1 );
            this.boardTree[i] = setDormant( this.boardTree[i] , 1 );

            //  Update Beam
            this.fuzzyBeam = this.fuzzyBeam - kFUZZYBEAM[s];
        }
        else
        {
            int i = this.boardTree.lastIndexWhere( (e) => getCellIndex(e) == t1 );
            int s = getSize( this.boardTree[i] );

            this.sun[own] = this.sun[own] - this.mineCost[s+1];
            this.mineCost[s+1]++;
            this.mineCost[s]--;
            this.boardTree[i] = setSize( this.boardTree[i] , s + 1 );
            this.boardTree[i] = setDormant( this.boardTree[i] , 1 );

            //  Update Beam
            this.fuzzyBeam = this.fuzzyBeam - kFUZZYBEAM[s];
        }


        //for( int s = 0 ; s < 3 ; s++ )
        //{
        //    if( this.tree[s] & (1 << t1) != 0 )
        //    {
        //        if( own == kO )
        //        {
        //            this.sun[own] = this.sun[own] - this.oppCost[s+1];
        //            this.oppCost[s+1]++;
        //            this.oppCost[s]--;
        //        }
        //        else
        //        {
        //            this.sun[own] = this.sun[own] - this.mineCost[s+1];
        //            this.mineCost[s+1]++;
        //            this.mineCost[s]--;
        //        }
        //        this.tree[s+1] = (1 << t1) | this.tree[s+1];
        //        this.tree[s] = ~(1 << t1) & this.tree[s];
        //        this.dormant = (1 << t1) | this.dormant;

        //        //  Update Beam
        //        this.fuzzyBeam = this.fuzzyBeam - kFUZZYBEAM[s];
        //        break;
        //    }
        //}
    }

    void completes( List<int> i )
    {
        int own = i[1], t1 = i[2];
        this.sun[own] = this.sun[own] - 4;
        //this.tree[3] = ~(1 << t1) & this.tree[3];

        if( own == kO )
        {
            this.oppCost[3]--;
            this.oppTreeTop--;
            for( int i1 = 0 ; i1 < this.oppTreeTop ; i1++ )
                if( this.boardTree[i1] == t1 )
                {
                    this.boardTree[ i1 ] = this.boardTree[ this.oppTreeTop ];
                    break;
                }
            //this.opp = ~(1 << t1) & this.opp;
        }
        else
        {
            this.mineCost[3]--;
            this.mineTreeTop++;
            for( int i1 = 36 ; i1 > this.mineTreeTop ; i1-- )
                if( this.boardTree[i1] == t1 )
                {
                    this.boardTree[ i1 ] = this.boardTree[ this.mineTreeTop ];
                    break;
                }
            //this.mine = ~(1 << t1) & this.mine;
        }

        this.complete++;
        int scored = this.nutrients + mapFields[t1].richness;
        this.score[own] = this.score[own] + scored;

        //  Update Beam
        this.fuzzyBeam = this.fuzzyBeam - mapFields[t1].richness;
    }

    void seeds( List<int> i )
    {
        int own = i[1], t1 = i[2] , t2 = i[3];
        this.nextSeed[own] = t2;

        int _ = this.boardTree.lastIndexWhere( (e) => getCellIndex(e) == t1 );

        this.boardTree[_] = setDormant( this.boardTree[_]  , 1 );
    }

    void waits( List<int> i )
    {
        int own = i[1];
        this.wait[own] = 1;
    }

}

class Field
{
    int friend = ~0 ;
    List<int> seedling = [ 0 , 0 ];
    int index = 0, richness = 0;
    List<int> neigh = [];

    Field( {required List<String> i} ) {
        this.index = parse(i[0]);
        this.richness = (parse(i[1]) - 1) * 2;
        i.add( i[2] );
        this.neigh = List.generate( 7 , (j) => parse(i[j+2]) , growable : false );
        this.friend = 0x1fffffffff & ~(1 << this.index);
    }

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
    List<List<Tree>> child = [];

    String chosen( List<int> i ) {
        final List<Function> kFUN = [printg, printc , prints , printw ];
        return kFUN[i[0]](i);
    }

    String printg(List<int> i) => "GROW ${i[2]}";
    String printc(List<int> i) => "COMPLETE ${i[2]}";
    String prints(List<int> i) => "SEED ${i[2]} ${i[3]}";
    String printw(List<int> i) => "WAIT";

    String choosed() => 'WAIT';
    int i1 = -1, i2 = -1, day = 0;

    //  MCTS
    List<int> mcts_w1 = [], mcts_w2 = [], mcts_n1 = [], mcts_n2 = [];

    //  Beam
    List<int> beam_sum1 = [] , beam_sum2 = [] , beam_n1 = [] , beam_n2 = [];

    List<int> mine = [];
    List<int> opp = [];

    List<List<int>> minePredictAction = [ ];
    List<List<int>> oppPredictAction = [ ];

    @override
    String toString() {
        return "[${this.game.day},${this.game.sun},${this.mine}]";
    }

    Tree( {required NatureSpirit g } )
    {
        this.game = new NatureSpirit.fromNatureSpirit(g);

    }

    void reset()
    {
        this.minePredictAction = [];
        this..oppPredictAction = [];
        this.child = [];
        this.parent = null;
        this.mine = [];
        this.opp = [];
    }

    void updateHeap( SplayTreeMap t )
    {
        int b = 10 * this.game.fuzzyBeam;
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
        for( int day = 0 ; day < 6 ; day++ )
        {
            predictSum( renting , mapShadow[day] , day , week );
        }

        //List<int> nTree = [ this.game.ownTree[kO].length , this.game.ownTree[kM].length ];
        List<int> richning = [ 0 , 0 ];
        //for( int o = 0 ; o < 2 ; o++ )
        //{
        //    richning[o] = 3 *
        //    ( (this.game.nutrients - nTree[(o + 1) & 1]) + (this.game.nutrients - nTree[0] - nTree[1]) ) * nTree[o]
        //    ~/ 2 ;

        //    for( final t in this.game.ownTree[o] )
        //        richning[o] = richning[o] - 15 + (mapFields[t].richness * 3);
        //}

        List<int> score = [ 0 , 0 ];
        score[kO] = this.game.score[kO] * 3 + this.game.sun[kO] + renting[kO] + richning[kO];
        score[kM] = this.game.score[kM] * 3 + this.game.sun[kM] + renting[kM] + richning[kM];

        scoring = 2000 - score[kM] + score[kO];

        //  Add in heap
        //error("${this.game.ownTree[kO]} ${this.game.ownTree[kM]} $renting $richning ${this.game.score}");
        t[scoring] = this;
    }

}

List<int> memoizationShadow(List<Field> fields , int day)
{
    List<int> shadow = [ 0 , 0 , 0 ];
    int s = 0;
    for( final Field f in fields )
    {
        Field _ = f;
        for( int s = 0 ; s < 3 ; s++ )
        {
            int next = _.neigh[ day ];
            if( next == -1 )    break;
            shadow[ s ] = shadow[ s ] | (1 << next);
            _ = fields[ next ];
        }
    }
    return shadow;
}

void resolveNode( int end , Tree g , SplayTreeMap bst , SplayTreeMap brt )
{
    late Tree node = g ,child;

    node.minePredictAction = node.game.predict( kM );
    node.oppPredictAction = node.game.predict( kO );

    node.child = List.generate( node.minePredictAction.length , (i) => [] , growable : false );
    int m1 = 0;
    for( final List<int> mine in node.minePredictAction )
    {
        int o1 = 0;

        node.child[m1] = List.generate( node.oppPredictAction.length ,
        (i) => new Tree( g : node.game )..i1 = m1..mine = mine..parent = node , growable : false );

        for( final List<int> opp in node.oppPredictAction )
        {
            child = node.child[m1][o1];

            child.i2 = o1;
            child.opp = opp;

            if( child.game.simuTurn( child.mine , child.opp ) == true )
            {
                child.game.simuDay();
            }

            if( child.game.day == end )
            {
                child.updateScoring( brt );
            }
            else
            {
                child.updateHeap( bst );
            }

            //error("SIMU TURN ${kORDER[child.mine[0]]} ${child.mine} ${kORDER[child.opp[0]]} ${child.opp} ${child.game.fuzzyBeam}");
            if( stopwatch.elapsedMilliseconds >= rtTime )   break;
            o1++;
            nbChild++;
        }
        if( stopwatch.elapsedMilliseconds >= rtTime )   break;
        m1++;
    }
    //error("RESOLVE [ ${bst.length} , ${brt.length} ] ");

}

void main()
{
    //  Needs fields
    mapFields = List.generate( 37 , (j) => new Field( i : ["0","0","0","0","0","0","0","0"] ) , growable : false );
    mapShadow = List.generate( 6 , (i) => [ 0 , 0 , 0 ], growable: false );

    SplayTreeMap beamSearchTree = new SplayTreeMap<int,Tree>();
    SplayTreeMap beamBestResult = new SplayTreeMap<int,Tree>();
    NatureSpirit game = new NatureSpirit();
    Tree node = new Tree( g: game )..mine = []..opp = []..game = game;
    int n = 0;

    n = parse(read());
    for (int i = 0; i < n; i++)
        mapFields[i] = new Field( i : read().split(' ') );
    for (int i = 0; i < n; i++)
        mapFields[i].memoization( mapFields );
    for( int day = 0 ; day < 6 ; day++ )
        mapShadow[day] = memoizationShadow( mapFields , day );

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
        error(turn++);

        beamSearchTree = new SplayTreeMap<int,Tree>();
        beamBestResult = new SplayTreeMap<int,Tree>();
        beamSearchTree[ game.fuzzyBeam ] = node ;

        //  Update Node
        node.reset();

        int end = min(game.day + 3,24);

        node.minePredictAction = node.game.predict( kM );
        node.oppPredictAction = node.game.predict( kO );

        error(node.game);
        for( List<int> a in node.minePredictAction )
            error( a );

        //for( List<int> a in node.oppPredictAction )
        //    error( a );

        Queue<Tree> beam = new Queue<Tree>();
        while( stopwatch.elapsedMilliseconds < rtTime )
        {
            //break;

            rtStart = stopwatch.elapsedMilliseconds;

            late Tree current;
            if( beamSearchTree.length == 0 )    break;

            for( int i = 0 ; i < min( 3, beamSearchTree.length ) ; i++ )
            {
                int key = beamSearchTree.firstKey();
                beam.add( beamSearchTree[key] );
                beamSearchTree.remove( key );
            }

            for( int i = 0 ; i < beam.length ; i++ )
            {
                if( stopwatch.elapsedMilliseconds >= rtTime )   break;
                current = beam.removeFirst();
                resolveNode( end , current , beamSearchTree , beamBestResult );
            }

        }
        rtEnd = stopwatch.elapsedMilliseconds;

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
        print( "${chosen.chosen(chosen.mine)} [${nbChild}]" );

        //print( "WAIT");

        rtTime = kLIMIT_TURN;
    }
}
