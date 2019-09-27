use Test::More tests => 6;
BEGIN { use_ok( 'P4' ); }

# Load test utils
unshift( @INC, "." );
unshift( @INC, "t" );
require_ok( "p4test" );

my $test = new P4::Test;
my $p4 = $test->InitClient();

ok( defined( $p4 ) );
$p4->SetProg( $0 );
ok( $p4->Connect() );

$p4->Tagged( 0 );
ok( ! $p4->IsTagged() );

$p4->Debug( 7 );

my $r = $p4->FetchClient();

ok( length($r) != 0, "FetchClientOutput Empty");
