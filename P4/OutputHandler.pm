#-------------------------------------------------------------------------------
# Copyright (c) 2008-2012, Perforce Software, Inc.  All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1.  Redistributions of source code must retain the above copyright
#     notice, this list of conditions and the following disclaimer.
#
# 2.  Redistributions in binary form must reproduce the above copyright
#     notice, this list of conditions and the following disclaimer in the
#     documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL PERFORCE SOFTWARE, INC. BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#-------------------------------------------------------------------------------
package P4::OutputHandler;

=pod

=head1 NAME

P4::OutputHandler

=head1 SYNOPSIS

    use P4;
    
	package MyHandler; 
	{
		use base qw( P4::OutputHandler );
		
		sub new {
			my $proto = shift;
			my $class = ref($proto) || $proto;
			my $self  = {};
			...
			
			bless($self, $class);
			return $self;
		}
				
		sub OutputMessage {
			my $self = shift;
			...
			return $val;
		}
		
		sub OutputText {
			my $self = shift;
			...
			return $val;
		}
		
		sub OutputInfo {
			my $self = shift;
			...
			return $val;
		}
		
		sub OutputBinary {
			my $self = shift;
			...
			return $val;
		}
		
		sub OutputStat {
			my $self = shift;
			...
			return $val;		
		}
	}
	1;
	
	package main;
	
	$p4 = new P4;
	$p4->Connect() or die( "Failed to connect to Perforce" );
	        
	$handler = new MyHandler;
	$p4->SetHandler($handler);
		
	## Run something large that you might want to exit early.
	$p4->RunFiles("//...");
	...

=head1 DESCRIPTION

P4::OutputHandler is a class for handling Perforce output callbacks.

Typical use-case is for processing large results and exit early when
a specific condition is found. 

The P4::OutputHandler should be sub-classed with methods used to 
handle the returned outputs from a P4::Run command.  A callback
method can return the following values to alter the Run behaviour:

	0 = added to output
	1 = handled (don't add to output)
	2 = mark command for abort (add to output)
	3 = mark command for abort (don't to output)

=head1 METHODS

=cut

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self  = {};
	$self->{val} = 0;
	bless( $self, $class );
	return $self;
}

=pod

=over

=item OutputMessage()

=over

Called when the running command returns a P4::Message object.

=back

=back

=cut

sub OutputMessage {
	my $self = shift;
	return $self->{val};
}

=pod

=over

=item OutputText()

=over

Called when the running command returns text. 
For example, p4 print on a text file.

=back

=back

=cut

sub OutputText {
	my $self = shift;
	return $self->{val};
}

=pod

=over

=item OutputInfo()

=over

Called when the running command returns text information and
is commonly used to display listings of information about files.

=back

=back

=cut

sub OutputInfo {
	my $self = shift;
	return $self->{val};
}

=pod

=over

=item OutputBinary()

=over

Called when the running command returns binary to stdout. 
For example, p4 print on a binary file.

=back

=back

=cut

sub OutputBinary {
	my $self = shift;
	return $self->{val};
}

=pod

=over

=item OutputStat()

=over

Called when the running command returns information in tagged output.
For example, p4 fstat.

=back

=back

=cut

sub OutputStat {
	my $self = shift;
	return $self->{val};
}


=pod

=head1 SEE ALSO

L<P4>, L<P4::Message>, L<P4::Progress>

=head1 COPYRIGHT

Copyright (c) 2008-2012, Perforce Software, Inc. All rights reserved.

=cut

1;
__END__
