#oodist: *** DO NOT USE THIS VERSION FOR PRODUCTION ***
#oodist: This file contains OODoc-style documentation which will get stripped
#oodist: during its release in the distribution.  You can use this file for
#oodist: testing, however the code of this development version may be broken!

package Mail::Box::Parser::C;
use base qw/Mail::Box::Parser Exporter DynaLoader/;

our $VERSION = '3.012';

use strict;
use warnings;

use Carp;

#--------------------
=chapter NAME

Mail::Box::Parser::C - Parsing folders for MailBox with C routines

=chapter SYNOPSIS

=chapter DESCRIPTION

The Mail::Box::Parser::C implements parsing of messages in ANSI C,
using Perl's XS extension facility.

This is an optional module for MailBox, and will (once installed)
automatically be used by MailBox to parse e-mail message content when
the message is supplied as file-handle.  In all other cases,
MailBox will use L<Mail::Box::Parser::Perl>.

=cut

use Mail::Message::Field ();

our %EXPORT_TAGS = (
	field => [ qw( ) ],
	head  => [ qw( ) ],
	body  => [ qw( ) ],
);


our @EXPORT_OK = @{$EXPORT_TAGS{field}};

bootstrap Mail::Box::Parser::C $VERSION;

## Defined in the library
sub open_filename($$$);
sub open_filehandle($$$);
sub get_filehandle($);
sub close_file($);
sub push_separator($$);
sub pop_separator($);
sub get_position($);
sub set_position($$);
sub read_header($);
sub fold_header_line($$);
sub in_dosmode($);
sub read_separator($);
sub body_as_string($$$);
sub body_as_list($$$);
sub body_as_file($$$$);
sub body_delayed($$$);

# Not used yet.
#fold_header_line(char *original, int wrap)
#in_dosmode(int boxnr)

#--------------------
=chapter METHODS

=section Initiation

=section The Parser

=section Parsing

=cut

sub pushSeparator($)
{	my ($self, $sep) = @_;
	push_separator $self->{MBPC_boxnr}, $sep;
}

sub popSeparator() { pop_separator shift->{MBPC_boxnr} }

sub filePosition(;$)
{	my $boxnr = shift->{MBPC_boxnr};
	@_ ? set_position($boxnr, shift) : get_position($boxnr);
}

sub readHeader() { read_header shift->{MBPC_boxnr} }

sub readSeparator() { read_separator shift->{MBPC_boxnr} }

sub bodyAsString(;$$)
{	my ($self, $exp_chars, $exp_lines) = @_;
	body_as_string $self->{MBPC_boxnr}, $exp_chars // -1, $exp_lines // -1;
}

sub bodyAsList(;$$)
{	my ($self, $exp_chars, $exp_lines) = @_;
	body_as_list $self->{MBPC_boxnr}, $exp_chars // -1, $exp_lines // -1;
}

sub bodyAsFile($;$$)
{	my ($self, $file, $exp_chars, $exp_lines) = @_;
	body_as_file $self->{MBPC_boxnr}, $file, $exp_chars // -1, $exp_lines // -1;
}

#--------------------
=section Reading and Writing [internals]
=cut

sub bodyDelayed(;$$)
{	my ($self, $exp_chars, $exp_lines) = @_;
	body_delayed $self->{MBPC_boxnr}, $exp_chars // -1, $exp_lines // -1;
}

sub openFile($)
{	my ($self, $args) = @_;
	my %log = $self->logSettings;

	my $boxnr;
	if(my $file = $args->{file})
	{	my $name = $args->{filename} || "$file";
		$boxnr   = open_filehandle($file, $name, $log{trace});
	}
	else
	{	$boxnr   = open_filename($args->{filename}, $args->{mode}, $log{trace});
	}

	$self->{MBPC_boxnr} = $boxnr;
	defined $boxnr ? $self : undef;
}

sub closeFile() {
	my $boxnr = delete $_[0]->{MBPC_boxnr};
	defined $boxnr ? close_file $boxnr : ();
}

1;
