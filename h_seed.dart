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

    //if( player[p1].state == ENDING )
    //{
        //if( n.cost == 0 && cell[id1].richness == 3 && player[p1].day < 20 )
    //    if( cell[id1].richness == 3 && player[p1].day < 20 )
    //    {
    //        k[p1] = k[p1] + 3 * (player[p1].nutrients + 2 * cell[id1].richness);
    //    }
    //    return k;
    //}

    if( n.cost != 0 )
        return k;

    int nbTreeIsMine = 0;
    for( final _ in tree )
        if( _.isMine == kMINE )
            nbTreeIsMine++;

    //  Update cost, sun is point , no sun no point
    if( player[p1].state == NOISING || player[p1].state == STARTING )
    {
        k[p1] = k[p1] - 2 * cell[id1].richness;
        for( final i1 in [19,8,22,10,25,12,28,14,31,16,34,18] )
            if( n.p.last == i1 )
                k[p1]++;
        for( final i1 in [1,2,3,4,5,6] )
            if( n.p.last == i1 )
                k[p1] = k[p1] + 5;

        if( n.p.last == 0 )
            k[p1] = k[p1] - 20;
    }
    else
    {
        k[p1] = k[p1] - 1 - 3 - 7 - 4 - nbTreeIsMine;
        //k[p1] = k[p1] + 3 * ( max(player[kMINE].nutrients - player[kMINE].nbTree,0) + 2 * cell[id1].richness);
        k[p1] = k[p1] + 3 * 2 * cell[id1].richness;
        for( final i1 in [1,2,3,4,5,6] )
            if( n.p.last == i1 )
                k[p1] = k[p1] + 5;

        if( n.p.last == 0 )
            k[p1] = k[p1] - 20;
    }

    for( int d = 0 ; d < 6 ; d++ )
    {
        int hex = cell[n.p.last].neighboor[d];
        if( hex == -1 ) continue;
        if( tree[ hex ].isMine == kMINE )
            k[p1] = k[p1] - 9;
        hex = cell[hex].neighboor[d];
        if( hex == -1 ) continue;
        if( tree[ hex ].isMine == kMINE )
            k[p1] = k[p1] - 6;
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
        if( tree[id1].size == 0 && cell[id1].richness == 3 && player[p1].day < 21 )
        {
            k[p1] = k[p1] + 3 * (player[p1].nutrients + 2 * cell[id1].richness);
        }
        else
        if( tree[id1].size == 1 && cell[id1].richness == 3 && player[p1].day < 22 )
        {
            k[p1] = k[p1] + 3 * (player[p1].nutrients + 2 * cell[id1].richness);
        }
        else
        if( tree[id1].size == 2 && cell[id1].richness == 3 && player[p1].day < 23 )
        {
            k[p1] = k[p1] + 3 * (player[p1].nutrients + 2 * cell[id1].richness);
        }
        return k;
    }

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
