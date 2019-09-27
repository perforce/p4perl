use Test::More tests => 9;
BEGIN { use_ok('P4'); }    ## test 1

# Load test utils
unshift( @INC, "." );
unshift( @INC, "t" );
require_ok("p4test");      ## test 2

our %count;

# ---- MyProgress Class -----------------------------------------------------
package TestProgress; 
{
	use base qw( P4::Progress );
	
	sub Init {
	    my $self = shift;
	    $count->{Description} = 0;
		$count->{Update} = 0;
		$count->{Total} = 0;
		$count->{Done} = 0;
	}
	
	sub Description {
	    my $self = shift;
	    $count->{Description}++;
	}
	
	sub Update {
	    my $self = shift;
	    $count->{Update}++;
	}
	
	sub Total {
	    my $self = shift;
	    $count->{Total}++;
	}
	
	sub Done {
	    my $self = shift;
	    my $fail = shift;
		if($fail) {
			$count->{Done}++;
		}
	}

	sub getCount {
		return $count;
	}
}	


# ---- Main Class -----------------------------------------------------------
package main;

my $test = new P4::Test;
my $p4   = $test->InitClient();

ok( defined($p4) );        					## test 3
ok( $p4->Connect() );      					## test 4


## new sub classed progress object
my $progress = new TestProgress();
ok( $progress->isa(P4::Progress) );			## test 5


## test set/get methods
$p4->SetProgress($progress);
my $p = $p4->GetProgress();
ok( $p->isa(P4::Progress) );				## test 6
is( $p, $progress );						## test 7

## sync all files with progress
$p4->RunSync("-f", "-q", "//...");

## create and add test files (100 x 1K)
my $dir = "progress";
mkdir( $dir ) or die( "Can't create subdirectory '$dir'");

my $c = $progress->getCount();

ok( scalar( $c->{Done} ) == 1 );			## test 8

ok( scalar( $c->{Update} ) > 0 );			## test 9


