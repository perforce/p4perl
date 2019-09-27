use Test::More tests => 3;
BEGIN { use_ok( 'P4' ); }

# Load test utils
unshift( @INC, "." );
unshift( @INC, "t" );
require_ok( "p4test" );

my $test = new P4::Test();
my $p4 = $test->InitClient();

ok( defined( $p4 ) );
