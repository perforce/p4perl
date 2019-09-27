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
package P4::MergeData;

=pod

=head1 NAME

P4::MergeData

=head1 SYNOPSIS

    use P4;
    package MyResolver;
    our @ISA = qw( P4::Resolver );
    sub Resolve( $ )
    {
        my $self      = shift;
        my $mergeData = shift;
	...
	return $mergeData->Hint();
    }
    1;

    package main;

    $p4 = new P4;
    $resolver = new MyResolver;

    $p4->Connect() or die( "Failed to connect to Perforce" );
    $p4->RunResolve( $resolver, ... );

=head1 DESCRIPTION

P4::MergeData is a class for encapsulating the data involved
in performing a merge (resolve) in Perforce. Users may not
create objects of this class; they are created internally
during C<P4::RunResolve()>, and passed down to the 
C<Resolve()> method of a C<P4::Resolver> subclass.

=head1 METHODS

=over

=item YourName()

Returns the name of 'your' file in the merge, in client syntax.

=item TheirName()

Returns the name of 'their' file in the merge, in depot syntax,
including the revision number.

=item BaseName()

Returns the name of the base file in the merge, in depot syntax,
including the revision number.

=item YourPath()

Returns the path to 'your' file in your workspace.

=item TheirPath()

Returns the path to a temporary file containing the contents of
'their' file to use in the merge.

=item BasePath()

Returns the path to a temporary file containing the contents of
the base file to use in the merge.

=item ResultPath()

Returns the path to a temporary file containing the merge result.

=item MergeHint()

Returns a string containing the hint from Perforce's merge
algorithm, indicating the recommended action for performing
the resolve.

=item RunMergeTool()

Runs the user's chosen merge tool (if any). Returns true if
the merge tool was successfully executed, false otherwise.

=back

=head1 SEE ALSO

L<P4>, L<P4::DepotFile>, L<P4::Revision>, L<P4::Integration>, L<P4::Map>,
L<P4::Resolver>, L<P4::Spec>, L<P4::Message>

=head1 COPYRIGHT

Copyright (c) 2008-2010, Perforce Software, Inc. All rights reserved.

=cut
1;
__END__
