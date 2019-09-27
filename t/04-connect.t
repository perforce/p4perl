use Test::More tests => 7;
BEGIN { use_ok( 'P4' ); }

# Load test utils
unshift( @INC, "." );
unshift( @INC, "t" );
require_ok( "p4test" );

my $test = new P4::Test;
ok( defined( $test ) );

my $p4 = $test->InitClient();
ok( defined( $p4 ) );

ok( !$p4->IsConnected() );
ok( $p4->Connect() );
ok( $p4->IsConnected() );
