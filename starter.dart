import 'dart:io';

var error = stderr.writeln, parse = int.parse;
final int kM = 1 , kO = 0;
final int kG = 0 , kC = 1, kS = 2, kW = 3;

final List<List<int>> kGROW = [ [ 0 , 0 ], [ 1 , 1 ] , [ 3 , 3 ] , [ 7 , 7 ] ];
final List<int> kFUZZYBEAM = [ 1 , 3 , 7 , 11 ];

//  Time
Stopwatch stopwatch = new Stopwatch();
int time = 700;

String read() {
  String? s = stdin.readLineSync();
  return s == null ? '' : s;
}

List<Field>     mapFields = [];
List<List<int>> mapShadow = [];

class NatureSpirit
{
    int day = 0, nutrients = 0;
    List<int> sun = [ 0 , 0 ], score = [ 0 , 0 ], wait = [ 0 , 0 ], scoring = [ 0 , 0 ];
    List<int> tree = [ 0 , 0 , 0 , 0 ];
    List<int> shadows = [ 0 , 0 , 0 ];

    int mine = 0, opp = 0, dormant = 0;

    List<List<int>> cost = kGROW;
    List<List<int>> ownTree = [ [] , [] ];

    int complete = 0;
    List<int> nextSeed = [ -2 , -1 ];

    int fuzzyBeam = 37 * kFUZZYBEAM[3];

    NatureSpirit( );

    NatureSpirit.fromNatureSpirit(NatureSpirit _) :
    this.sun = List.generate( 2 , (i) => _.sun[i] , growable : false ) ,
    this.score = List.generate( 2 , (i) => _.score[i] , growable : false ) ,
    this.wait = List.generate( 2 , (i) => _.wait[i] , growable : false ) ,
    this.scoring = [ 0 , 0 ],
    this.tree = List.generate( 4 , (i) => _.tree[i] , growable : false ) ,
    this.shadows = List.generate( 3 , (i) => _.shadows[i] , growable : false ) ,
    this.mine = _.mine , this.opp = _.opp , this.dormant = _.dormant ,
    this.cost = List.generate( 4 ,
    (i) => List.generate( 2 , (j) => _.cost[i][j] , growable: false ) , growable:  false) ,
    this.ownTree = List.generate( 2 ,
    (i) => List.generate( _.ownTree[i].length , (j) => _.ownTree[i][j] ) , growable: false);

    List<List<int>> predict(int o)
    {
        List<List<int>> action = [];
        int friendly = ~0;
        for( final int t in ownTree[o] )
        {
            if( (1 << t) & this.dormant != 0 )
                continue;

            for( int s = 0 ; s < 3 ; s++ )
            {
                if( this.tree[s] & (1 << t) != 0 && this.cost[o][s+1] <= this.sun[o]  )
                {
                    action.add( [ kG , o , t ] );
                    break;
                }
            }
            if( this.tree[3] & (1 << t) != 0 && 4 <= this.sun[o]  )
            {
                action.add( [ kC , o , t ] );
                break;
            }

            friendly = friendly & mapFields[t].friend;
        }
        for( final int t in ownTree[o] )
        {
            int seedling = 0;
            if( (1 << t) & this.dormant != 0 )
                continue;

            if( this.tree[2] & (1 << t) != 0 && this.cost[o][0] <= this.sun[o] )
            {
                seedling = friendly & mapFields[t].seedling[2 - 2];
            }
            else if( this.tree[3] & (1 << t) != 0 && this.cost[o][0] <= this.sun[o] )
            {
                seedling = friendly & (mapFields[t].seedling[2 - 2] | mapFields[t].seedling[3 - 2]);
            }
            for( int i = 0 ; i < 37 ; i++ )
            {
                if( seedling & 1 != 0 ) action.add( [ kS , o , t , i ] );
                seedling = seedling >> 1;
            }
        }
        action.add( [ kW , o ] );
        return action;
    }

    void resolveSum()
    {
        List<int> sum = [ 0 , 0 ];

        int shadows = (this.shadows[ 1-1 ] | this.shadows[ 2 - 1] | this.shadows[ 3 - 1] );
        for( int s = 1 ; s < 4 ; s++ )
        {
            List<int> compute = [ this.tree[s] & this.opp & ~shadows , this.tree[s] & this.mine & ~shadows ];
            for( int i = 0 ; i < 37 ; i++ )
            {
                sum[kO] = sum[kO] + (compute[kO] & 1) * s;
                compute[kO] = compute[kO] >> 1;

                sum[kM] = sum[kM] + (compute[kM] & 1) * s;
                compute[kM] = compute[kM] >> 1;
            }
            shadows = shadows & ~(this.shadows[s-1]);
        }
        this.sun = [ this.sun[kO] + sum[kO] , this.sun[kM] + sum[kM] ];
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
                this.sun[o] = this.sun[kO] - this.cost[0][o];
                this.cost[0][o]++;
                this.dormant = (1 << this.nextSeed[o]) | this.dormant;
                this.tree[0] = (1 << this.nextSeed[o]) | this.tree[0];
                this.ownTree[o].add( this.nextSeed[o] );
                this.opp = (1 << this.nextSeed[o]) | this.opp;
                //  Update beam
                this.fuzzyBeam = o == kM ? this.fuzzyBeam - kFUZZYBEAM[o] : this.fuzzyBeam + kFUZZYBEAM[o];
            }
        }
        ;
        this.nextSeed = [-2 , -1 ];
    }

    void reset()
    {
        this.tree = [ 0 , 0 , 0 , 0 ];
        this.mine = 0;
        this.opp = 0;
        this.dormant = 0;
        this.cost = kGROW;
        this.ownTree = [ [] , [] ];

        //  Beam update
        this.fuzzyBeam = 37 * kFUZZYBEAM[3] + this.score[kO] - this.score[kM];
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
            this.score[kO] = parse(i[0]);
            this.wait[kO] = parse(i[2]);
        }
    }

    void updateTree( List<String> i )
    {
        int id = parse(i[0]), s = parse(i[1]) , o = parse(i[2]) , d = parse(i[3]);
        this.tree[s] = (1 << id) | this.tree[s];
        this.dormant = (d << id) | this.dormant;
        this.ownTree[ o ].add( id );

        if( o == kM )
            this.mine = (1 << id) | this.mine;
        else
            this.opp = (1 << id) | this.opp;

        //  Beam update
        this.fuzzyBeam = o == kM ? this.fuzzyBeam - kFUZZYBEAM[s] : this.fuzzyBeam + kFUZZYBEAM[s];
    }

    void simuDay()
    {
        this.nutrients = this.nutrients - this.complete;
        this.complete = 0;
        this.day++;
        this.shadows = mapShadow[ this.day ];
        resolveSum();
        this.wait = [ 0 , 0 ];
        this.dormant = 0;
    }

    void simuTurn()
    {
        resolveSeed();
    }

    void grows( int t1 )
    {
        int own = ( this.mine & ( 1 << t1 ) ) != 0 ? kM : kO;
        for( int s = 0 ; s < 3 ; s++ )
        {
            if( this.tree[s] & (1 << t1) != 0 )
            {
                this.sun[own] = this.sun[own] - this.cost[s+1][own];
                this.cost[s+1][own]++;
                this.cost[s][own]--;
                this.tree[s+1] = (1 << t1) | this.tree[s+1];
                this.tree[s] = ~(1 << t1) & this.tree[s];
                this.dormant = (1 << t1) | this.dormant;

                //  Update Beam
                this.fuzzyBeam = own == kM ? this.fuzzyBeam - kFUZZYBEAM[s] : this.fuzzyBeam + kFUZZYBEAM[s];
                break;
            }
        }
    }

    void completes( int t1 )
    {
        int own = ( this.mine & ( 1 << t1 ) ) != 0 ? kM : kO;
        this.sun[own] = this.sun[own] - 4;
        this.cost[3][own]--;
        this.tree[3] = ~(1 << t1) & this.tree[3];

        if( own == kO )
            this.mine = ~(1 << t1) & this.mine;
        else
            this.opp = ~(1 << t1) & this.opp;

        this.complete++;
        int scored = this.nutrients + mapFields[t1].richness;
        this.score[own] = this.score[own] + scored;
        this.ownTree[own].removeWhere( (i) => i == t1 );

        //  Update Beam
        this.fuzzyBeam = own == kM ? this.fuzzyBeam - scored : this.fuzzyBeam + scored;
    }

    void seeds( int t1 , int t2 )
    {
        int own = ( this.mine & ( 1 << t1 ) ) != 0 ? kM : kO;
        this.nextSeed[own] = t2;
        this.dormant = (1 << t1) | this.dormant;
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
        this.friend = ~(1 << this.index);
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
            for( int s = 0 , next = _.neigh[day] ; s < 3 ; s++ , next = _.neigh[day] )
            {
                if( next == -1 )    break;
                friend = ~(1 << next) & friend;
            }
        }
    }
}

class Tree {

    late NatureSpirit game;
    List<List<NatureSpirit?>> child = [];

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

    Tree( {required NatureSpirit g } )
    {
        this.game = new NatureSpirit.fromNatureSpirit(g);
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


void main()
{
    //  Needs fields
    mapFields = List.generate( 37 , (j) => new Field( i : ["0","0","0","0","0","0","0","0"] ) , growable : false );
    mapShadow = List.generate( 6 , (i) => [ 0 , 0 , 0 ], growable: false );

    NatureSpirit game = new NatureSpirit();
    Tree node = new Tree( g: game )..mine = []..opp = [];
    int n = 0;

    n = parse(read());
    for (int i = 0; i < n; i++)
        mapFields[i] = new Field( i : read().split(' ') );
    for (int i = 0; i < n; i++)
        mapFields[i].memoization( mapFields );
    for( int day = 0 ; day < 6 ; day++ )
        mapShadow[day] = memoizationShadow( mapFields , day );

    // game loop
    while (true)
    {
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


        //  Out
        print( node.choosed() );
    }
}
