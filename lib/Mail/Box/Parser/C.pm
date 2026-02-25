#oodist: *** DO NOT USE THIS VERSION FOR PRODUCTION ***
#oodist: This file contains OODoc-style documentation which will get stripped
#oodist: during its release in the distribution.  You can use this file for
#oodist: testing, however the code of this development version may be broken!

package Mail::Box::Parser::C;
use parent qw/Mail::Box::Parser DynaLoader/;

our $VERSION = '4.01';

use strict;
use warnings;

use Log::Report   'mail-box-parser-c';

use Mail::Message::Field ();

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

B<Be aware:>
This module versions 4.00 and up is not fully compatible with older releases:
mainly the exception handling has changed.  When you need to upgrade, please
read F<https://github.com/markov2/perl5-Mail-Box/wiki/>
B<Version 3 is still maintained> and may see new releases as well.

=cut

bootstrap Mail::Box::Parser::C $VERSION;

## Defined in the XS library
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

=section Constructors

=method new %options

=requires  filename FILENAME
The name of the file to be read.

=option  file $filehandle
=default file undef
Any M<IO::File> or C<GLOB> $filehandle which can be used to read
the data from.  In case this option is specified, the P<filename> is
informational only.

=option  mode $mode
=default mode C<'r'>
File open $mode, which defaults to C<'r'>, which means `read-only'.
See C<perldoc -f open> for possible modes.  Only applicable
when no P<file> is specified.

=error filename or handle required to create a parser.
=cut

sub init(@)
{	my ($self, $args) = @_;
	$self->SUPER::init($args);

	$self->{MBPC_file}     = my $fh = $args->{file};
	$self->{MBPC_mode}     = $args->{mode}     || 'r';
	$self->{MBPC_filename} = $args->{filename} || ref $fh
		or error __x"filename or handle required to create a parser.";

	$self->start;
	$self;
}

#--------------------
=section Attributes

=method filename
Returns the name of the file this parser is working on.
=method openMode
=method file
Only returns a value when passed as instantiation parameter.  Otherwise,
the used file-handle stays in 'C-space'.  The connection between C and
Perl is via the M<boxnr()>.
=cut

sub filename() { $_[0]->{MBPC_filename} }
sub openMode() { $_[0]->{MBPC_mode} }
sub file()     { $_[0]->{MBPC_file} }

=method boxnr
The number internally used by the C implementation to administer a
single mail folder access.
=cut

sub boxnr()    { $_[0]->{MBPC_boxnr} }

#--------------------
=section Parsing

=method start %options
Start the parser by opening a file.

=option  file FILEHANDLE|undef
=default file undef
The file is already open, for instance because the data must be read
from STDIN.
=cut

sub start(@)
{	my ($self, %args) = @_;
	$self->openFile(%args) or return;

	trace "opened folder ".$self->filename." to be parsed";
	$self;
}

=method stop
Stop the parser, which will include a close of the file.  The lock on the
folder will not be removed (is not the responsibility of the parser).
=cut

sub stop()
{	my $self = shift;
	trace "close parser for file " . $self->filename;
	$self->closeFile;
}

sub pushSeparator($)
{	my ($self, $sep) = @_;
	push_separator $self->boxnr, $sep;
}

sub popSeparator()  { pop_separator $_[0]->boxnr }

sub filePosition(;$)
{	my $boxnr = shift->boxnr;
	@_ ? set_position($boxnr, shift) : get_position($boxnr);
}

sub readHeader()    { read_header $_[0]->boxnr }

sub readSeparator() { read_separator $_[0]->boxnr }

sub bodyAsString(;$$)
{	my ($self, $exp_chars, $exp_lines) = @_;
	body_as_string $self->boxnr, $exp_chars // -1, $exp_lines // -1;
}

sub bodyAsList(;$$)
{	my ($self, $exp_chars, $exp_lines) = @_;
	body_as_list $self->boxnr, $exp_chars // -1, $exp_lines // -1;
}

sub bodyAsFile($;$$)
{	my ($self, $file, $exp_chars, $exp_lines) = @_;
	body_as_file $self->boxnr, $file, $exp_chars // -1, $exp_lines // -1;
}

sub bodyDelayed(;$$)
{	my ($self, $exp_chars, $exp_lines) = @_;
	body_delayed $self->boxnr, $exp_chars // -1, $exp_lines // -1;
}

sub openFile(%)
{	my ($self, %args) = @_;
	my $trace    = $args{trace} || 0;

	my $filename = $args{filename} || $self->filename;
	my $mode     = $args{mode}     || $self->openMode;
	my $fh       = $args{file}     || $self->file;

	my $boxnr;
	if(defined $fh)
	{	$boxnr = open_filehandle($fh, $filename // "$fh", $trace);
	}
	else
	{	$boxnr = open_filename($filename, $mode, $trace);
	}

	$self->{MBPC_boxnr} = $boxnr;
	defined $boxnr ? $self : undef;
}

sub closeFile() {
	my $boxnr = delete $_[0]->{MBPC_boxnr};
	defined $boxnr ? close_file $boxnr : ();
}

1;
