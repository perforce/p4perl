package file_hdl;
use strict;
use warnings;

use Data::Dumper;

use base qw( P4::OutputHandler );

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self  = {};
	$self->{retval} = 0;
	$self->{outputMessage} = 0;
	$self->{outputText} = 0;
	$self->{outputInfo} = 0;
	$self->{outputBinary} = 0;
	$self->{outputStat} = 0;
	
	bless($self, $class);
	return $self;
}

sub OutputMessage {
	my $self = shift;
	$self->{outputMessage}++;
	return $self->{retval};
}

sub OutputText {
	my $self = shift;
	$self->{outputText}++;
	return $self->{retval};
}

sub OutputInfo {
	my $self = shift;
	$self->{outputInfo}++;
	return $self->{retval};
}

sub OutputBinary {
	my $self = shift;
	$self->{outputBinary}++;
	return $self->{retval};
}

sub OutputStat {
	my $self = shift;
	$self->{outputStat}++;
	return $self->{retval};		
}

# returns 	[0:0]	0 = added to (O) output
#			[0:1]	1 = dealt with (don't add to output)
#			[1:0]	2 = mark for (A) abort (add to (O) output)
#			[1:1]	3 = mark for (A) abort (don't to output)
sub setReturn {
	my $self = shift;
	my $r = shift;
	$self->{retval} = $r;
}

sub getCount {
	my $self = shift;
	my $method = shift;
	
	my $cnt = $self->{$method};
	$self->{$method} = 0;
	return $cnt;
}

1;