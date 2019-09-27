use Test::More tests => 9;
BEGIN { use_ok('P4'); }    ## test 1

# Load test utils
unshift( @INC, "." );
unshift( @INC, "t" );
require_ok("p4test");      ## test 2

my $test = new P4::Test;
my $p4   = $test->InitClient();

ok( defined($p4) );        ## test 3
ok( $p4->Connect() );      ## test 4

#	Create an unload depot
my $depot = $p4->FetchDepot("unload_depot");
$depot->{Type} = "unload";
$p4->SaveDepot($depot);

#	Create a client workspace, which we'll unload as part of the test
my $client = $p4->FetchClient("unload_client");
$p4->SaveClient($client);

#	Ensure that the client is created
my @clients = $p4->RunClients( "-e", "unload_client" );
ok( scalar(@clients) == 1 );			## test 5

#	Sync -k some files to the client workspace
$p4->SetClient("unload_client");
my @sync = $p4->RunSync( "-f", "-k", "//..." );
ok( scalar(@sync) == 111 );				## test 6

#	Unload the client workspace and check it was successful
$p4->RunUnload( "-c", "unload_client" );

@clients = $p4->RunClients( "-U", "-e", "unload_client" );
ok( scalar(@clients) == 1 );			## test 7

#	Reload the client workspace
$p4->RunReload( "-c", "unload_client" );

@clients = $p4->RunClients( "-U", "-e", "unload_client" );
ok( scalar(@clients) == 0 );			## test 8

my @have = $p4->RunHave();
ok( scalar(@have) == scalar(@sync) );	## test 9
