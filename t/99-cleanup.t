use Test::More tests => 3;

# Load test utils
unshift( @INC, "." );
unshift( @INC, "t" );
require_ok( "p4test" );

my $test = new P4::Test;
ok( defined( $test ) );
if( defined $ENV{ 'KEEPTESTS' } )
{
    ok( 1 );
}
else
{
    ok( $test->CleanupTestTree() );
}
