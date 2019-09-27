use Test::More tests => 17;
BEGIN { use_ok('P4'); }    ## test 1

# Load test utils
unshift( @INC, "." );
unshift( @INC, "t" );
require_ok("p4test");      ## test 2


my $test = new P4::Test;
my $p4   = $test->InitClient();

ok( defined($p4) );        ## test 3
ok( $p4->Connect() );      ## test 4

## Read value from returned spec
my $i    = $p4->IterateChanges("-m4");
my $spec = $i->next;
ok( $spec->{Change} == 8 );    ## test 5

## Read all remaining specs (changes 9,10,11)
$c = 0;
while ( $i->hasNext ) {
	my $spec = $i->next;
	$c++;
}
ok( $c == 3 );                 ## test 6

## Test iterate when empty
my $null = $i->next;
ok( !defined $null );          ## test 7

my @specs = (
	'clients', 'labels', 'branches', 'changes',   'streams', 'jobs', 'users',
	'groups',  'depots', 'servers'
);

foreach my $s (@specs) {
	my $i = $p4->Iterate($s);
	ok( defined($i) );         ## test 8-17
}
