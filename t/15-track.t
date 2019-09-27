use Test::More tests => 8;
BEGIN { use_ok( 'P4' ); }

# Load test utils
unshift( @INC, "." );
unshift( @INC, "t" );
require_ok( "p4test" );

my $test = new P4::Test;
my $p4 = $test->InitClient();
ok( $p4->SetTrack( 1 ) );
ok( $p4->IsTrack() );
$p4->Connect();
ok( $p4->IsConnected() );

# Suppress the expected warning in the test
my $old_warn = $SIG{ __WARN__ };
$SIG{ __WARN__ } = sub {};
ok( !$p4->SetTrack( 0 ) );
$SIG{ __WARN__ } = $old_warn;

ok( $p4->IsTrack() );
$p4->Run( "info" );
my @track = $p4->TrackOutput();
ok( @track );
$p4->Disconnect();
