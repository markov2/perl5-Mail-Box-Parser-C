package Mail::Box::Parser::C;
our $VERSION = 3.002;

use strict;
use warnings;
use Carp;

use base qw/Mail::Box::Parser Exporter DynaLoader/;

=head1 NAME

Mail::Box::Parser::C - Parsing folders for MailBox with C routines

=head1 DESCRIPTION

This is an optional module for MailBox, and will (once installed)
automatically be used by MailBox to parse e-mail message content when
the message is supplied as file-handle.  In all other cases,
MailBox will use L<Mail::Box::Parser::Perl>.

=cut

use Mail::Message::Field;

our %EXPORT_TAGS =
 ( field => [ qw( ) ]
 , head  => [ qw( ) ]
 , body  => [ qw( ) ]
 );


our @EXPORT_OK = ( @{$EXPORT_TAGS{field}} );

bootstrap Mail::Box::Parser::C $VERSION;

## Defined in the library
sub open_filename($$$);
sub open_filehandle($$$);
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

=head1 NAME

Mail::Box::Parser::C - reading messages from file using C (XS)

=head1 SYNOPSIS

=head1 DESCRIPTION

The Mail::Box::Parser::C implements parsing of messages in ANSI C,
using Perl's XS extension facility.  

=head1 METHODS

=cut

#------------------------------------------

=head2 Initiation

=cut

#------------------------------------------

=head2 The Parser

=cut

#------------------------------------------

=head2 Parsing

=cut

#------------------------------------------

sub pushSeparator($)
{   my ($self, $sep) = @_;
    push_separator $self->{MBPC_boxnr}, $sep;
}

#------------------------------------------

sub popSeparator() { pop_separator shift->{MBPC_boxnr} }
    
#------------------------------------------

sub filePosition(;$)
{   my $boxnr = shift->{MBPC_boxnr};
    @_ ? set_position($boxnr, shift) : get_position($boxnr);
}

#------------------------------------------

sub readHeader() { read_header shift->{MBPC_boxnr} }

#------------------------------------------

sub readSeparator() { read_separator shift->{MBPC_boxnr} }

#------------------------------------------

sub bodyAsString(;$$)
{   my ($self, $exp_chars, $exp_lines) = @_;
    $exp_chars = -1 unless defined $exp_chars;
    $exp_lines = -1 unless defined $exp_lines;
    body_as_string $self->{MBPC_boxnr}, $exp_chars, $exp_lines;
}


#------------------------------------------

sub bodyAsList(;$$)
{   my ($self, $exp_chars, $exp_lines) = @_;
    $exp_chars = -1 unless defined $exp_chars;
    $exp_lines = -1 unless defined $exp_lines;
    body_as_list $self->{MBPC_boxnr}, $exp_chars, $exp_lines;
}

#------------------------------------------

sub bodyAsFile($;$$)
{   my ($self, $file, $exp_chars, $exp_lines) = @_;
    $exp_chars = -1 unless defined $exp_chars;
    $exp_lines = -1 unless defined $exp_lines;
    body_as_file $self->{MBPC_boxnr}, $file, $exp_chars, $exp_lines;
}

#------------------------------------------

=head2 Reading and Writing [internals]

=cut

#------------------------------------------

sub bodyDelayed(;$$)
{   my ($self, $exp_chars, $exp_lines) = @_;
    $exp_chars = -1 unless defined $exp_chars;
    $exp_lines = -1 unless defined $exp_lines;
    body_delayed $self->{MBPC_boxnr}, $exp_chars, $exp_lines;
}

#------------------------------------------

sub openFile($)
{   my ($self, $args) = @_;
    my $boxnr;
    my %log = $self->logSettings;

    if(my $file = $args->{file})
    {   my $name = $args->{filename} || "$file";
        $boxnr   = open_filehandle($file, $name, $log{trace});
    }
    else
    {   $boxnr   = open_filename($args->{filename}, $args->{mode}, $log{trace});
    }

    $self->{MBPC_boxnr} = $boxnr;
    defined $boxnr ? $self : undef;
}

#------------------------------------------

sub closeFile() {
   my $boxnr = delete shift->{MBPC_boxnr};
   return unless defined $boxnr;
   close_file $boxnr;
}

#------------------------------------------

1;

