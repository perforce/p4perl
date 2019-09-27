use Test::More tests => 9;
BEGIN { use_ok( 'P4' ); }

# Load test utils
unshift( @INC, "." );
unshift( @INC, "t" );
require_ok( "p4test" );

package MyResolver;

our @ISA = qw( P4::Resolver );

sub Setup( $$ )
{
    my $self = shift;

    $self->{ 'src' } = shift;
    $self->{ 'tgt' } = shift;
    $self->{ 'result' } = 0;
}

sub Result()
{
    my $self = shift;
    return $self->{ 'result' };
}

sub Resolve( $ )
{
    my $self = shift;
    my $mergeData = shift;

    my $yourName = $mergeData->YourName();
    my $theirName = $mergeData->TheirName();
    my $baseName = $mergeData->BaseName();

    $theirName =~ s/#.*//;

    if( $theirName eq $self->{ 'src' } ) 
    {
	$self->{ 'result' } = 1;
	return $mergeData->MergeHint();
    }
    return "s";
}

package main;
    
my $test = new P4::Test;
my $p4 = $test->InitClient();

ok( defined( $p4 ) );
$p4->SetProg( $0 );
ok( $p4->Connect() );

$p4->Debug( 0 );

#
# Add a revision to test_files/foo, then integrate it to test_branch/foo,
# and resolve...
#
@files = $p4->RunEdit( 'test_files/foo' );
ok( scalar( @files ) == 1 );

$change = $p4->FetchChange();
$change->{ 'Description' } = "Editing the test files";
$p4->RunSubmit( $change );

@opened = $p4->RunOpened();
ok( scalar( @opened ) == 0 );

@files = $p4->RunInteg( "test_files/...", "test_branch/..." );
ok( scalar( @files ) == 1 );

$resolver = new MyResolver;
$resolver->Setup( '//depot/test_files/foo', '//depot/test_branch/foo' );
$p4->RunResolve( $resolver, "//depot/..." );
ok( $resolver->Result() );

$change = $p4->FetchChange();
$change->{ 'Description' } = "Integrate the test files";
$p4->RunSubmit( $change );

@opened = $p4->RunOpened();
ok( scalar( @opened ) == 0 );


