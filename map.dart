Map<int,Node> m = new Map();
for( final _ in o )
{
    int key = _.p[0];
    if( m.containsKey( key ) )
    {
        Node? n = m[key];
        if( n != null && n.cost > _.cost )  m[key] = _;
    }
    else
    {
        m[ key ] = _;
    }
}
