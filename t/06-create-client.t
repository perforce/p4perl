use Test::More tests => 9;
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

my $client = $p4->FetchClient();
ok( defined( $client ) );
ok( ref( $client ) );

$client->{ 'Description' } = "Client for P4Perl Tests";
$client->{ 'Root' } = $test->ClientRoot();
$p4->SaveClient( $client );
ok( $p4->ErrorCount() == 0 );

@info = $p4->RunInfo();
ok( length( scalar(@info) ) == 1 );
ok( $info[0]->{ 'clientName' } ne "*unknown*" );
