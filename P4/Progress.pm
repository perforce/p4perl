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
package P4::Progress;

=pod

=head1 NAME

P4::Progress

=head1 SYNOPSIS

    use P4;

	package MyProgress;
	{
		use base qw( P4::Progress );

		# type: 1 SENDFILE, 2 RECEIVEFILE, 3 TRANSFER, 4 COMPUTATION
		sub Init {
		    my $self = shift;
		    my $type = shift;
			print( "SubmitProgress::init\n" );
		}

		# units: 1 percent, 2 files, 3 KBytes, 4 MBytes
		sub Description {
		    my $self = shift;
		    my $desc = shift;
		    my $units = shift;
			print( "SubmitProgress::description: $desc, $units\n" );
		}

		sub Update {
		    my $self = shift;
		    my $progress = shift;
			print( "SubmitProgress::update: $progress\n" );
		}

		sub Total {
		    my $self = shift;
		    my $total = shift;
			print( "SubmitProgress::total: $total\n" );
		}

		sub Done {
		    my $self = shift;
		    my $fail = shift;
			print( "SubmitProgress::done: $fail\n" );
		}
	}
    1;

    package main;

    $p4 = new P4;
    $progress = new MyProgress;
    $p4->SetProgress($progress);

    $p4->Connect() or die( "Failed to connect to Perforce" );
    $p4->RunSync("-q", "//...");
    ...

=head1 DESCRIPTION

P4::Progress is a class for handling Perforce progress callbacks

=head1 METHODS

=cut

sub new {
	my $class = shift;
	my $self  = {};
	bless( $self, $class );
	return $self;
}

=pod

=over

=item Init()

=over

Called when object constructed, arg 'type' 

=back

=back

=cut

sub Init {
	my $self = shift;
	my $type = shift;
	$self->{type} = $type;
}

=pod

=over

=item Description()

=over

Invoked with arguments 'description' and 'units' 

=back

=back

=cut

sub Description {
	my $self        = shift;
	my $description = shift;
	my $units       = shift;

	$self->{description} = $description;
	$self->{units}       = $units;
}

=pod

=over

=item Total()

=over

Invoked with argument 'total' 

=back

=back

=cut

sub Total {
	my $self  = shift;
	my $total = shift;
	$self->{total} = $total;
}

=pod

=over

=item Update()

=over

Invoked with argument 'position' 

=back

=back

=cut

sub Update {
	my $self     = shift;
	my $position = shift;
	$self->{position} = $position;
}

=pod

=over

=item Done()

=over

Invoked with argument fail (0:1) 

=back

=back

=cut

sub Done {
	my $self = shift;
	my $fail = shift;
}

=pod

=head1 SEE ALSO

L<P4>, L<P4::Message>

=head1 COPYRIGHT

Copyright (c) 2008-2012, Perforce Software, Inc. All rights reserved.

=cut

1;
__END__
