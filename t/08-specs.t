use Test::More tests => 14;
BEGIN { use_ok( 'P4' ); }

# Load test utils
unshift( @INC, "." );
unshift( @INC, "t" );
require_ok( "p4test" );

my $test = new P4::Test;
my $p4 = $test->InitClient();

ok( defined( $p4 ) );
$p4->SetProg( $0 );

my %client;
#
# Number of fields here influences number of tests. Change with care...
#
$client{ 'Client' } = "foo";
$client{ 'Owner'  } = "tony";
$client{ 'Root'   } = "/home/tony";
$client{ 'View'   } = [ "//depot/... //foo/..." ];

my $c = $p4->FormatClient( \%client );
ok( length( $c ) > 0 );

my $newclient = $p4->ParseClient( $c );
foreach my $k (keys %client)
{
    ok( defined( $newclient->{ $k } ) );
    if( ref( $newclient->{ $k } ) eq "ARRAY" )
    {
	for( my $i = 0; defined( $client{ $k }->[ $i ] ); $i++ )
	{
	    is( $newclient->{ $k }->[ $i ], $client{ $k }->[ $i ] )
	}
    }
    else
    {
	is( $newclient->{ $k }, $client{ $k } );
    }
}

ok( ref( $newclient ) eq "P4::Spec" );
ok( grep( /Owner/, $newclient->PermittedFields() ) );
