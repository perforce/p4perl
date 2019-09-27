#
# Hints for Windows platforms.
# Updated for Perl 5.16 and later which are built with MinGW.
#
use Config;

if ( $Config{cc} =~ /gcc/i ) {
    # With MinGW
    $self->{CC} = "g++";
    $self->{LD} = "g++";
	$self->{LDDLFLAGS} = "-Wl,--allow-multiple-definition -shared"
} else {
    # Alternatively, for pre-5.16 Perl which uses Visual Studio
    $self->{DEFINE} .= " /TP";
    # Make sure we're not linking with -debug on Windows as the linker chokes
    # (the Perforce API is assumed to not be a debug build).
    $self->{LDDLFLAGS} = $Config{ 'lddlflags' };
    $self->{LDDLFLAGS} =~ s/ -debug//g;
}

#
# Hint that our OS name is 'NT' rather than anything else
#
$self->{P4PERL_OS_HINT} = "NT";
$self->{P4PERL_OSVER_HINT} = "";
