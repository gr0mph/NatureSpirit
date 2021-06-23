import 'sakura.dart';

void predictAll( NatureSpirit g ) {

	Queue<NatureSpirit> q = new Queue() , nextQ = new Queue();
	q.add( g ):

	//	Complete
	predictComplete( nextQ , q.removeFirst() );

	//	Seed
	while( nextQ.length > 0 )
		predictSeed( q , nextQ.removeFirst() );

	//	Grow
	while( q.length > 0 )
		predictGrow( q , nextQ , q.removeFirst() );

	//	Seed
	while( nextQ.length > 0 )
		predictSeed( q , nextQ.removeFirst() );


}

void predictComplete( Queue<NatureSpirit> next , NatureSpirit g ) {
	if( g.mineTreeTop <= (36 - 9) && g.agent[kM].sun >= 11 ) {
		int cellIndex = -1;
		int richness = -2;
		for( int indexStack in g.map.values ) {
			Sakura t = g.boardTree[indexStack];
			if( t.size == 3 && richness < t.richness && t.isMine == kM ) {
				cellIndex = t.celIndex;
				richness = t.richness; } }
		if( richness >= 0 ) {
			NatureSpirit add = new NatureSpirit.fromNatureSpirit( g );
			Sakura t  = g.boardTree[ g.map[ cellIndex ] ];
			add.action.add( [ kC , t.isMine , t.cellIndex ] );
			best.completes( add , add.action[0] ); } } }

void predictGrow( NatureSpirit g ) {

	List<int> startSeed = [ 0 , 0 ];
	List<int> endSeed = [ 0 , 0 ]


	for( int o = 0 ; o < 2 ; o++ )
		if( g.agent[o].getCost(0) == 0 )
			print("CHECK SEED $o");

	for( int indexStack in g.map.values ) {
		Sakura t = g.boardTree[indexStack]!;
		error(t);
	}

}

void main() {

	print("HELLO");

	NatureSpirit game = new NatureSpirit();
	game.reset();
	game.updateTree( [ "13" , "0" , "1" , "0" ]);
	game.updateTree( [ "15" , "1" , "1" , "0" ]);
	game.updateTree( [ "17" , "2" , "1" , "0" ]);

	game.agent[kM].sun = 20;

	predictGrow( game );

}
