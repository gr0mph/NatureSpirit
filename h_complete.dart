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
