use Test::More tests => 15;
BEGIN { use_ok('P4'); }

# Load test utils
unshift( @INC, "." );
unshift( @INC, "t" );
require_ok("p4test");

# ---- MyResolver Class -----------------------------------------------------
package MyResolver;
our @ISA = qw( P4::Resolver );

sub new() {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self  = {};

	$self->{'Resolve'} = 0;
	$self->{'ActionResolve'} = 0;
	$self->{'type'} = "";
	$self->{'hint'} = "";
	$self->{'info'} = {};

	bless( $self, $class );
	return $self;
}

sub GetCount() {
	my $self = shift;
	my $key = shift;
	return $self->{$key};
}

sub GetType() {
	my $self = shift;
	return $self->{'type'};
}

sub GetHint() {
	my $self = shift;
	return $self->{'hint'};
}

sub GetInfo() {
	my $self = shift;
	return $self->{'info'};
}

sub Resolve( $ ) {
	my $self      = shift;
	my $mergeData = shift;

	$self->{'Resolve'} += 1;
	$self->{'hint'} = $mergeData->MergeHint();

	return $mergeData->MergeHint();
}

sub ActionResolve( $ ) {
	my $self      = shift;
	my $mergeData = shift;

	$self->{'ActionResolve'} += 1;
	$self->{'type'} = $mergeData->Type();
	$self->{'hint'} = $mergeData->MergeHint();
	$self->{'info'} = $mergeData->MergeInfo();

	return $mergeData->MergeHint();
}

# ---- Main Class -----------------------------------------------------------
package main;

my $test = new P4::Test;
my $p4   = $test->InitClient();

ok( defined($p4) );
$p4->SetProg($0);
ok( $p4->Connect() );

$p4->Debug(0);

SKIP: {
	skip "skipping Action Resolve", 11
	  if ( $p4->ServerLevel() < 31 );

	#
	# [CASE 1]
	# New branch test_action/... and schedule branch resolve
	#
	@files = $p4->RunInteg( "-3", "-Rb", "test_files/foo", "test_action/foo" );
	ok( scalar(@files) == 1 );

	$resolver = new MyResolver();
	$p4->RunResolve( $resolver, "//depot/..." );
	ok( $resolver->GetCount('ActionResolve') == 1 );
	ok( $resolver->GetType() eq 'Branch resolve' );

	# check returned info hash
	my $info = $resolver->GetInfo();
	ok( $info->{'fromFile'}    eq '//depot/test_files/foo' );
	ok( $info->{'resolveType'} eq 'branch' );

	$change = $p4->FetchChange();
	$change->{'Description'} = "Action resolve the test files";
	$p4->RunSubmit($change);

	@opened = $p4->RunOpened();
	ok( scalar(@opened) == 0 );

	#
	# [CASE 2]
	# Edit types and merge for 'Filetype resolve'
	#
	$p4->RunEdit( "-t+m", "test_files/foo" );

	$change = $p4->FetchChange();
	$change->{'Description'} = "Change type";
	$p4->RunSubmit($change);

	@opened = $p4->RunOpened();
	ok( scalar(@opened) == 0 );

	@files = $p4->RunInteg( "-3", "test_files/foo", "test_action/foo" );
	ok( scalar(@files) == 1 );

	$resolver = new MyResolver();
	$p4->RunResolve( $resolver, "//depot/..." );
	ok( $resolver->GetCount('ActionResolve') == 1 );
	ok( $resolver->GetType() eq 'Filetype resolve' );

	$change = $p4->FetchChange();
	$change->{'Description'} = "Action resolve the test files";
	$p4->RunSubmit($change);

	@opened = $p4->RunOpened();
	ok( scalar(@opened) == 0 );
}
