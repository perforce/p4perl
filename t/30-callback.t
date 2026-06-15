use Test::More tests => 13;
BEGIN { use_ok('P4'); }    ## test 1

# Load test utils
unshift( @INC, "." );
unshift( @INC, "t" );
require_ok("p4test");      ## test 2

require_ok("file_hdl");    ## test 3

my $test = new P4::Test;
my $p4   = $test->InitClient();

ok( defined($p4) );        ## test 4
ok( $p4->Connect() );      ## test 5

## create callback object
my $file_cb = new file_hdl;

## test set/get methods
$p4->SetHandler($file_cb);
my $h = $p4->GetHandler();
ok( $h->isa(file_hdl) );    ## test 6
is( $h, $file_cb );         ## test 7

## test callback: mode 0 - 'add output'
my @s1 = $p4->RunFiles("//...");
ok( scalar(@s1) == 9 );     ## test 8
my $c1 = $file_cb->getCount('outputStat');
ok( $c1 == 9 );             ## test 9

## test callback: mode 1 - 'no output'
$file_cb->setReturn(1);
$p4->SetHandler($file_cb);
my @s2 = $p4->RunFiles("//...");
ok( scalar(@s2) == 0 );     ## test 10
my $c2 = $file_cb->getCount('outputStat');
ok( $c2 == 9 );             ## test 11

## test break: mode 2/3
diag("\nTest will abort callback, expect an RpcTransport message...");
add_file( $p4, 100 );

if( $^O eq 'MSWin32' )
{
    # On Windows, RSH pipe handle inheritance causes a hang when the break
    # callback aborts a command because inherited handles prevent the pipe
    # from receiving EOF. Disconnect the RSH p4d cleanly first, then use
    # a fresh TCP p4d for the break test — TCP socket cleanup does not hang.
    $p4->Disconnect();
    _win32_break_test( $test, $file_cb );
}
else
{
    $file_cb->setReturn(3);
    $p4->SetHandler($file_cb);
    my @s3 = $p4->RunFiles("//...");
    ok( scalar(@s3) == 0 );     ## test 12
    my $c3 = $file_cb->getCount('outputStat');
    diag( "\nTotal callbacks logged : $c3");
    ok( $c3 < 500 );            ## test 13
}


sub _win32_break_test {
    my ( $test, $file_cb ) = @_;
    require IO::Socket::INET;
    require Win32::Process;

    # Find a free TCP port
    my $ls = IO::Socket::INET->new(
        LocalAddr => 'localhost', LocalPort => 0, Proto => 'tcp' );
    my $port = $ls->sockport();
    $ls->close();

    # Start TCP p4d on the same server root (RSH p4d already exited)
    my $root = $test->ServerRoot();

    # Convert root path to Windows backslashes (cwd() may return forward slashes)
    ( my $root_w = $root ) =~ s{/}{\\}g;

    # p4d.exe is placed by EC component sync at this known container path.
    my $p4d_exe = 'C:\\mount\\p4-bin\\bin.ntx64\\p4d.exe';
    die "p4d not found at $p4d_exe" unless -f $p4d_exe;

    # Win32::Process::Create: full app path + absolute cwd (not '.').
    my $proc;
    Win32::Process::Create(
        $proc, $p4d_exe,
        "$p4d_exe -r \"$root_w\" -p localhost:$port",
        0, 0x08000000, $root_w
    ) or die "Failed to start TCP p4d: " . Win32::FormatMessage( Win32::GetLastError() );

    # Poll until p4d accepts connections (avoids hardcoded sleep)
    for ( 1..20 ) {
        my $ts = IO::Socket::INET->new(
            PeerAddr => 'localhost', PeerPort => $port,
            Proto => 'tcp', Timeout => 0.5 );
        if ($ts) { $ts->close(); last; }
        select( undef, undef, undef, 0.25 );
    }

    my $p4_tcp = new P4;
    $p4_tcp->SetPort( "localhost:$port" );
    $p4_tcp->SetClient( $test->{ 'P4CLIENT' } );
    $p4_tcp->Connect() or die "Cannot connect to TCP p4d on port $port";
    $p4_tcp->SetPassword( $P4::Test::SUPER_PASSWORD );
    $p4_tcp->RunLogin();

    $file_cb->setReturn(3);
    $p4_tcp->SetHandler($file_cb);
    my @s3 = $p4_tcp->RunFiles("//...");
    ok( scalar(@s3) == 0 );     ## test 12
    my $c3 = $file_cb->getCount('outputStat');
    diag( "\nTotal callbacks logged : $c3" );
    ok( $c3 < 500 );            ## test 13

    $p4_tcp->Disconnect();
    $proc->Kill(0);
}


sub add_file {
	my $p4  = shift;
	my $max = shift;

	mkdir("more_files") or die("Can't create subdirectory 'more_files'");
	my $id = 0;
	do {
		my $n = "more_files/file.$id.txt";
		open( FH, ">$n" ) or die("Can't create '$n'");
		print( FH "This is a test file\n" );
		close(FH);
		$p4->RunAdd($n);
		$id++;
	} while ( $id <= $max );

	## Submit
	my $change = $p4->FetchChange();
	$change->{'Description'} = "Adding $id test files";
	$p4->RunSubmit($change);
}
