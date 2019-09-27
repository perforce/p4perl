#-------------------------------------------------------------------------------
# Copyright (c) 2010, Perforce Software, Inc.  All rights reserved.
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
package P4::Message;

=pod

=head1 NAME

P4::Message

=head1 SYNOPSIS

	foreach my $m ( $p4->Messages() )
	{
		my $id 	     = $m->GetId();
		my $severity = $m->GetSeverity();
		my $generic  = $m->GetGeneric();
		my $text     = $m->GetText();
	}

=head1 DESCRIPTION

P4::Message objects encapsulate the error messages, and warnings
that can arise when using P4Perl. Their strings are also accessible
to the caller through the C<P4::Errors()>, and C<P4::Warnings()> 
methods (both of which return a list of Strings).

		
		foreach my $e ( $p4->Errors() ) 
		{
			print("ERROR: $e\n");
		}
		
		foreach my $w ( $p4->Warnings() ) 
		{
			print("WARN: $w\n");
		}

Although errors and warnings are already separated, it is
occasionally useful to know the severity of an error, or its
generic cause (its category). Those attributes of a message
are accessible using the methods below.

=head1 METHODS

=over

=item GetId()

=over

C<$id = $e-E<gt>GetId()>

Returns the unique ID of this error message. Script authors
can test this value instead of parsing the message text.

=back

=back

=over

=item GetGeneric()

=over

C<$gen = $e-E<gt>GetGeneric()>

Returns the generic reason for the error. Possible values,
and their meanings are:

=over

=item The fault of the user

=over

=item *

C<$P4::EV_NONE>

=over 

No error

=back

=item *

C<$P4::EV_USAGE>

=over

Usage error

=back

=item *

C<$P4::EV_UNKNOWN>

=over

Using unknown entity

=back

=item *

C<$P4::EV_CONTEXT>

=over

Using entity in wrong context

=back

=item *

C<$P4::EV_ILLEGAL>

=over

Trying to do something you can't

=back

=item *

C<$P4::EV_NOTYET>

=over

Something must be corrected first

=back

=item *

C<$P4::EV_PROTECT>

=over

Protections prevented operation

=back

=back

=item No fault at all

=over 

=item *

C<$P4::EV_EMPTY>

=over

Action returned empty result set

=back 

=back

=item Not the fault of the user

=over 

=item *

C<$P4::EV_FAULT>

=over

Inexplicable program fault

=back 

=item *

C<$P4::EV_CLIENT>

=over

Client side program errors

=back 

=item *

C<$P4::EV_ADMIN>

=over

Server administrative action required

=back 

=item *

C<$P4::EV_CONFIG>

=over

Client configuration inadequate

=back 

=item *

C<$P4::EV_UPGRADE>

=over

Client or server too old to interact

=back 

=item *

C<$P4::EV_COMM>

=over

Communications error

=back 

=item *

C<$P4::EV_TOOBIG>

=over

Not even Perforce can handle this much

=back 

=back

=back

=back

=item GetSeverity()

=over

C<$sev = $e-E<gt>GetSeverity()>

Returns the severity of the error. Possible values,
and their meanings are:

=over

=item *

C<$P4::E_EMPTY>

=over 

Nothing yet

=back

=item *

C<$P4::E_INFO>

=over 

Informational message

=back

=item *

C<$P4::E_WARN>

=over 

Warning message

=back

=item *

C<$P4::E_FAILED>

=over 

An error occurred

=back

=item *

C<$P4::E_FATAL>

=over 

A fatal error occurred; nothing can continue.

=back

=back

=back

=item GetText()

=over

C<$gen = $e-E<gt>GetText()>

Returns the text of the error message.

=back

=back

=head1 SEE ALSO

L<P4>, L<P4::DepotFile>, L<P4::Revision>, L<P4::Integration>, L<P4::Map>,
L<P4::Resolver>, L<P4::Spec>, L<P4::MergeData>

=head1 COPYRIGHT

Copyright (c) 2010, Perforce Software, Inc. All rights reserved.

=cut

1;
__END__
