#oodist: *** DO NOT USE THIS VERSION FOR PRODUCTION ***
#oodist: This file contains OODoc-style documentation which will get stripped
#oodist: during its release in the distribution.  You can use this file for
#oodist: testing, however the code of this development version may be broken!

#XXX WARNING: large overlap with Mail::Box::Parser:Perl; you may need to change both!

package Mail::Box::Parser::C;
use base qw/Mail::Box::Parser DynaLoader/;

our $VERSION = '3.014';

use strict;
use warnings;

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

B<This is a maintenance release for the old interface>.  Read
F<https://github.com/markov2/perl5-Mail-Box/wiki/> how
to move towards version 4.

=cut

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

=section Constructors

=c_method new %options

=requires  filename $name
The $name of the file to be read.

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

=cut

sub init(@)
{	my ($self, $args) = @_;
	$self->SUPER::init($args) or return;

	$self->{MBPC_mode}     = $args->{mode} || 'r';
	$self->{MBPC_filename} = $args->{filename} || ref $args->{file}
		or $self->log(ERROR => "Filename or handle required to create a parser."), return;

	$self->start(file => $args->{file});
	$self;
}

#--------------------
=section Attributes

=method boxnr
The number internally used by the C implementation to administer a
single mail folder access.
=cut

sub boxnr() { $_[0]->{MBPC_boxnr} }

=method filename
Returns the name of the file this parser is working on.

=method openMode
=method file
=cut

sub filename() { $_[0]->{MBPC_filename} }
sub openMode() { $_[0]->{MBPC_mode} }
sub file()     { $_[0]->{MBPC_file} }

#--------------------
=section Parsing

=method start %options
Start the parser by opening a file.

=option  file FILEHANDLE|undef
=default file undef
The file is already open, for instance because the data must be read from STDIN.
=cut

sub start(@)
{	my ($self, %args) = @_;
	$self->openFile(%args) or return;
	$self->takeFileInfo;

	$self->log(PROGRESS => "Opened folder ".$self->filename." to be parsed");
	$self;
}

=method stop
Stop the parser, which will include a close of the file.  The lock on the
folder will not be removed (is not the responsibility of the parser).

=warning File $file changed during access.
When a message parser starts working, it takes size and modification time
of the file at hand.  If the folder is written, it checks whether there
were changes in the file made by external programs.

Calling M<Mail::Box::update()> on a folder before it being closed
will read these new messages.  But the real source of this problem is
locking: some external program (for instance the mail transfer agent,
like sendmail) uses a different locking mechanism as you do and therefore
violates your rights.

=cut

sub stop()
{	my $self = shift;
	$self->log(NOTICE => "Close parser for file ".$self->filename);
	$self->closeFile;
}

=method restart %options
Restart the parser on a certain file, usually because the content has
changed.  The %options are passed to M<openFile()>.
=cut

sub restart()
{	my $self     = shift;
	$self->closeFile;
	$self->openFile(@_) or return;
	$self->takeFileInfo;
	$self->log(NOTICE => "Restarted parser for file ".$self->filename);
	$self;
}

=method fileChanged
Returns whether the file which is parsed has changed after the last
time takeFileInfo() was called.
=cut

sub fileChanged()
{	my $self = shift;
	my ($size, $mtime) = (stat $self->filename)[7,9];
	return 0 if !defined $size || !defined $mtime;
	$size != $self->{MBPC_size} || $mtime != $self->{MBPC_mtime};
}

=method filePosition [$position]
Returns the location of the next byte to be used in the file which is
parsed.  When a $position is specified, the location in the file is
moved to the indicated spot first.
=cut

sub filePosition(;$)
{	my $boxnr = shift->boxnr;
	@_ ? set_position($boxnr, shift) : get_position($boxnr);
}

=method takeFileInfo
Capture some data about the file being parsed, to be compared later.
=cut

sub takeFileInfo()
{	my $self = shift;
	@$self{ qw/MBPC_size MBPC_mtime/ } = (stat $self->filename)[7,9];
}


sub pushSeparator($)
{	my ($self, $sep) = @_;
	push_separator $self->boxnr, $sep;
}

sub popSeparator()  { pop_separator $_[0]->boxnr }

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

=method openFile %options
[3.013] Open the file to be parsed.
=cut

sub openFile(%)
{	my ($self, %args) = @_;
	my %log = $self->logSettings;

	my $boxnr;
	my $name = $args{filename} || $self->filename;

	if(my $file = $args{file})
	{	$boxnr   = open_filehandle($file, $name // "$file", $log{trace});
	}
	else
	{	my $mode = $args{mode} || $self->openMode || 'r';
		$boxnr   = open_filename($name, $mode, $log{trace});
	}

	$self->{MBPC_boxnr} = $boxnr;
	defined $boxnr ? $self : undef;
}

sub closeFile() {
	my $boxnr = delete $_[0]->{MBPC_boxnr};
	defined $boxnr ? close_file $boxnr : ();
}

1;
