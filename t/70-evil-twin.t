use Test::More tests => 4;
BEGIN { use_ok( 'P4' ); }						## test 1

# Load test utils
unshift( @INC, "." );
unshift( @INC, "t" );
require_ok( "p4test" );							## test 2

my $test = new P4::Test;
my $p4 = $test->InitClient();

$p4->SetClient('TestClient');
$p4->SetUser('bruno');

$p4->Connect();
ok( $p4->IsConnected() );						## test 3

my $client_name = $p4->FetchClient($p4->GetClient());
$p4->SaveClient($client_name);

# add A1
# branch A→B
# move A1→A2
# readd A1
# merge A→B

############################
# Prep dirs

my $dirA = "A";
my $dirB = "B";
my $fileA = "fileA";
my $fileA1 = "fileA1";

unless(mkdir $dirA) {
    die "Unable to create $dirA\n";
}
unless(mkdir $dirB) {
    die "Unable to create $dirB\n";
}

############################
# Adding

chdir "A";

unless(open FILE, '>'.$fileA) {
    die "\nUnable to create $fileA\n";
}

close FILE;

chdir ".." ;

$p4->Run( "add", "A/fileA");
my $change1	= $p4->FetchChange();
$change1->{ 'Description' } = 'Submitiing file A';
$p4->RunSubmit( $change1 );

############################
# Branching

$p4->Run("integ", "//depot/A/...", "//depot/B/...");
my $change2	= $p4->FetchChange();
$change2->{ 'Description' } = 'Integrating';
$p4->RunSubmit( $change2 );

############################
# Moving

$p4->Run("edit", "A/fileA");
$p4->Run("move", "-f", "A/fileA", "A/fileA1");
my $change3	= $p4->FetchChange();
$change3->{ 'Description' } = 'Moving';
$p4->RunSubmit( $change3 );

############################
# Re-adding origianl

chdir "A";

unless(open FILE, '>'.$fileA) {
    die "\nUnable to create $fileA\n";
}

close FILE;

chdir ".." ;

$p4->Run( "add", "A/fileA");
my $change4	= $p4->FetchChange();
$change4->{ 'Description' } = 'Re-submitiing file A';
$p4->RunSubmit( $change4 );

############################
# Second merge

$p4->Run("integ", "//depot/A/...", "//depot/B/...");

my $change5	= $p4->FetchChange();
$change5->{ 'Description' } = 'Merging re-added A';
$p4->RunSubmit( $change5 );


my @m2 = $p4->Messages();
my $message = $m2[0]->GetText();
ok ( $message == "//TestClient/B/fileA - must resolve //depot/A/fileA#3" ); ## test 4

$p4->Disconnect();