use Test::More tests => 8;
BEGIN { use_ok( 'P4' ); }						## test 1

# Load test utils
unshift( @INC, "." );
unshift( @INC, "t" );
require_ok( "p4test" );							## test 2

my $test = new P4::Test;
my $p4 = $test->InitClient();
$p4->SetStreams( 1 );
ok( $p4->IsStreams() );							## test 3
$p4->Connect();
ok( $p4->IsConnected() );						## test 4

my $spec = $p4->FetchDepot("streams");
$spec->{'Type'} = "stream";
$p4->SaveDepot($spec);

my @depots = $p4->RunDepots();
ok( scalar( @depots ) == 2 );					## test 5

my $stream = $p4->FetchStream("//streams/MAIN");
$stream->{'Type'} = "mainline";
$stream->{'Paths'} = "## First comment,
            share ... ## Second comment,
            ## Third comment";
$p4->SaveDepot($stream);

## look for 'extraTag' field names like 'firmerThanParent'
ok( $stream->{'firmerThanParent'} );			## test 6

$p4->SetStreams( 0 );
ok( !$p4->IsStreams() );						## test 7

my $readStream = $p4->FetchStream("//streams/MAIN");
ok ( $stream->{'Paths'} ==  "## First comment,
            share ... ## Second comment,
            ## Third comment" );                ## test 8

$p4->Disconnect();