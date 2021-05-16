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
        rent[kOPP] = rent[kOPP] + income[kOPP];
        rent[kMINE] = rent[kMINE] + income[kMINE];
    }

    k[kMINE] = k[kMINE] + rent[kMINE] - player[kMINE].renting;
    k[kOPP] = k[kOPP] + rent[kOPP] - player[kOPP].renting;

    //error("[${id1}] >> grow k ${k} id2 ${id2}");
    return k;
}
