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
package P4::IterateSpec;

my %specTypes = (
	'clients'  => [ 'client', 'client' ],
	'labels'   => [ 'label',  'label' ],
	'branches' => [ 'branch', 'branch' ],
	'changes'  => [ 'change', 'change' ],
	'streams'  => [ 'stream', 'Stream' ],
	'jobs'     => [ 'job',    'Job' ],
	'users'    => [ 'user',   'User' ],
	'groups'   => [ 'group',  'group' ],
	'depots'   => [ 'depot',  'name' ],
	'servers'  => [ 'server', 'Name' ]
);

=pod

=head1 NAME

P4::IterateSpec

=head1 SYNOPSIS

	use P4;
	
	my $p4 = P4->new;
	$p4->Connect or die "Couldn't connect";
		
	my $i = $p4->IterateClients();
	while($i->hasNext) {
		my $spec = $i->next;
		print( "Client: " . ($spec->{Client} or "<undef>") . "\n" );
	}

=head1 DESCRIPTION

P4::IterateSpec is a class for iterating over Perforce specs.
It's intended to be used on one spec type, returning an 
iterable object with next() and hasNext() methods.

Arguments can be passed to the iterator to filter the results,
for example:

	$p4->IterateClients( "-m2" );

or like the Run("cmd") option the spec type can be passed as an
argument, for example:

	$p4->Iterate( "changes" );
	
=head1 METHODS

=cut

sub new {
	my $class = shift;
	my $p4    = shift;
	my $type  = shift;

	my $self = {};
	bless( $self, $class );

	$self->{p4}   = $p4;
	$self->{list} = $p4->Run( $type, @_ );
	$self->{type} = $type;

print("type: " . $type . "\n");
	return $self;
}

=pod

=over

=item next()

=over

Returns the next Perforce spec form the iterator; otherwise
undef.

=back

=back

=cut

sub next {
	my $self = shift;
	my $p4   = $self->{p4};

	## lookup unit and id names
	my $unit = $specTypes{ $self->{type} }[0];
	my $id   = $specTypes{ $self->{type} }[1];

	## pop spec from list get id
	my $spec = pop( @{ $self->{list} } );
	if ($spec) {
		my $name = $spec->{$id};
		return shift @{ $p4->Run( $unit, "-o", $name ) };
	}
	else {
		return undef;
	}
}

=pod

=over

=item hasNext()

=over

Returns true (1) if there are specs left in the iterator;  
otherwise false if empty. 

=back

=back

=cut

sub hasNext {
	my $self = shift;

	my $len = scalar @{ $self->{list} };
	return 1 if ( $len > 0 );
	return undef;
}

=pod

=head1 SEE ALSO

L<P4>, L<P4::Spec>

=head1 COPYRIGHT

Copyright (c) 2008-2012, Perforce Software, Inc. All rights reserved.

=cut

1;
__END__
