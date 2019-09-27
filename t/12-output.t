use Test::More tests => 12;
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

$p4->Debug( 0 );

# Run a sync to make sure we are up to date
$p4->RunSync();

# Now run it again, and this time check the Messages
# array, which should have a files-up-to-date message
$p4->RunSync();
my @m = $p4->Messages();
ok( scalar(@m) == 1 );
ok( ref($m[0]) eq "P4::Message" );
ok( $m[0]->GetSeverity() == $P4::E_WARN );
ok( $m[0]->GetGeneric() == $P4::EV_EMPTY );
ok( $m[0]->GetId() == 6532 );
# Now disconnect, and reconnect with older API level
$p4->Disconnect();
$p4->SetApiLevel( 67 );
$p4->Connect();

$p4->RunSync();
@w = $p4->Warnings();
ok( scalar(@w) == 1 );
ok( !ref($w[0]) );
ok( $w[0] =~ /up-to-date/ );
