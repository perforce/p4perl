#-------------------------------------------------------------------------------
# Copyright (c) 2008-2010, Perforce Software, Inc.  All rights reserved.
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
package P4::Resolver;

=pod

=head1 NAME

P4::Resolver

=head1 SYNOPSIS

    use P4;
    package MyResolver;
    our @ISA = qw( P4::Resolver );
    sub Resolve( $ )
    {
        my $self      = shift;
        my $mergeData = shift;
	...
	return $mergeData->MergeHint();
    }
    1;

    package main;

    $p4 = new P4;
    $resolver = new MyResolver;

    $p4->Connect() or die( "Failed to connect to Perforce" );
    $p4->RunResolve( $resolver, ... );

=head1 DESCRIPTION

P4::Resolver is a class for handling resolves in Perforce. It's 
intended to be subclassed, and for subclasses to override the
C<Resolve()> method. When C<P4::RunResolve()> is called with
a P4::Resolver object, it calls the C<Resolve()> method of the
object once for each scheduled resolve.

=head1 METHODS

=cut

sub new
{
    my $class = shift;
    my $self = {};
    bless( $self, $class );
    return $self;
}

=pod

=over

=item Resolve()

=over

Returns the resolve decision as a string. The standard Perforce
resolve strings apply: "am", "at", "ay", etc. By default, all
automatic merges are accepted, and all merges with conflicts are
skipped.

The C<Resolve()> method is called with a single parameter, which
is a reference to a P4::MergeData object. 

=back

=back

=cut
sub Resolve( $ )
{
    my $self      = shift;
    my $mergeData = shift;

    return "s" if( $mergeData->MergeHint() eq "e" );
    return $mergeData()->MergeHint();
}

=pod

=head1 SEE ALSO

L<P4>, L<P4::DepotFile>, L<P4::Revision>, L<P4::Integration>, L<P4::Map>,
L<P4::Spec>, L<P4::MergeData>, L<P4::Message>

=head1 COPYRIGHT

Copyright (c) 2008-2010, Perforce Software, Inc. All rights reserved.

=cut
1;
__END__
