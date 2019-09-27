use Test::More tests => 2;

# Load test utils
unshift( @INC, "." );
unshift( @INC, "t" );
require_ok( "p4test" );

my $test = new P4::Test();

$test->CreateTestTree();
ok( -d $test->ServerRoot() );

