#!/usr/bin/perl
#
# Simple build script for procimap -- era Wed Jan  4 07:47:10 2006
# $Id: build.pl,v 1.3 2006-01-25 19:03:37 era Exp $
#

######## TODO: wrapper should be wrapper_prefix -- don't allow to change pr.rc
######## TODO: FIXME comment about pod2help is not too clear
######## TODO: in pod, mention that world readable is also never OK
######## TODO: in pod, factor out description of internal variables
######## TODO: rename package fnord to substitution or something

use strict;
use warnings;

use Getopt::Long;


my $me = $0;
$me =~ s,.*/,,;


my %Conf = (
    groupaccess => 0,		   	# group readable/writable files OK?
    install_prefix => "/",		# root dir for install
    basedir => "usr/local",		# or maybe "opt" or just "usr"
    wrapper => "share/lib/procimap.rc"
);

# Parse options
######## FIXME: simple copy / paste; make a proper module out of this?

{
  my $pod = <<'=cut';

=head1 NAME

build.pl - configure for local procimap installation


=head1 SYNOPSIS

B<build.pl> I<options ...>


=head1 DESCRIPTION

B<build.pl> builds B<procimap> and B<Makefile.conf>
for your local installation, supplying default parameter values
for those you do not supply yourself.

It also works the other way around, i.e. it can build
the corresponding B<procimap.in> and B<Makefile.conf.in> files
from a live source tree (with your local modifications, for example).

Technically, it reads the designated input files
(currently, their names are hard-coded into B<build.pl> itself),
looking for substitution pattern specifications,
but otherwise just copying the contents verbatim.
See L<|SUBSTITUTION> below
for what the substitution pattern specifications look like.


=head1 OPTIONS

B<build.pl> accepts the following options.

=over 4


=item B<-r>|B<--reverse>

=for Getopt::Long
r reverse ! Run in reverse: generate *.in files from current target files

Run in reverse; generate F<*.in> files from the corresponding
non-F<.in> files.

Currently, the files F<procimap> and F<Makefile.conf> are simply
copied over.


=item B<--groupaccess> I<n>

=for Getopt::Long
- groupaccess =i Set the group access variable (value: 0 or 1)

The B<--groupaccess> parameter should be set to either 0 or 1,
corresponding to boolean false or true, respectively.
It controls whether group-writable / group-readable
private files are tolerated by B<procimap>.
These private files are e.g. the F<procimap.conf> file,
where typically, your remote IMAP password will be stored.

Some Linux distributions, in particular, set up
one personal user group per user.
(I believe Red Hat and Debian / Ubuntu do this, for example.)
On these systems,
you might want to permit group-readable / group-writable
B<procimap> configuration files,
although the checks are crude enough that this does
open up a bit of a security hole;
properly, only the user's primary group should be
permitted, but if you enable group access,
the files can be group-readable for any group.

World-writable private files are never accepted by B<procimap>.


=item B<--install-root> I<directory>

=for Getopt::Long
- install-root =s Root directory for installation

The default root directory is F</>
and should probably not be changed
unless you use some build management
or package management system which
benefits from installing into a chroot.

Building Debian packages comes to mind
as an example of when you might want this,
in which case you'd set it to F<debian/procimap>.


=item B<--basedir> I<directory>

=for Getopt::Long
- basedir =s Specify base directory for installation, relative to root

Base directory for installation, relative to the B<install-root>.

The default is F<usr/local>; just F<usr> or F<opt> are common as well.


=item B<--wrapper> I<pathname>

=for Getopt::Long
- wrapper =s Relative file name for system-wide procimap.rc wrapper

File name to use for installing the system-wide F<procimap.rc> wrapper.
This is relateive to the B<basedir>.

The default is F<share/lib/procimap.rc>.
On some systems, you may want to omit the F<share/> prefix.

This corresponds to the B<build.pl> internal variable C<$wrapper>;
however, the variable will contain a full path name
constructed using the values of the
B<--install-root> and B<--basedir> parameters.


=item B<--help>

=for Getopt::Long
h help ! Print this help message and exit

Print a brief help message and exit.


=back


=head1 SUBSTITUTIONS

B<build.pl> supports a limited form of Perl's B<s///> syntax.
The substitutions are specified in the source file itself,
using a special form of comment.

The comment syntax is defined as follows:

  comment = "#" \s* "@@build.pl" addressing-mode substitution "@@"

where "addressing-mode" specifies on what string to perform the substitution,
and "substitution" is a (limited) B<s///> expression.

The addressing mode is a single character out of the following:

=over 2

=item B<#>

Perform the substitution on the contents of the current line.

=item B<E<gt>>

Search forward through the file;
perform substitution on the next matching line.

=back

Additional addressing modes may be specified in the future.

If the regular expression in the substitution expression
fails to match within the given search scope, a fatal error occurs.

The substitution expression is not passed directly to Perl
for evaluation, but is parsed initially by B<build.pl>.
It imposes the following constraints:

=over 2

=item B<*>

The expression delimiter must be a single character.
Paired delimiters (opening/closing parenthesis, brace, bracket, etc)
are not supported.
There is also no support for backslash-escaping the delimiter.

=item B<*>

Backreferences of the form C<$1> in the replacement string do not work.

=item B<*>

You can (and usually will) interpolate variables
which are however not proper Perl variables,
just the variables understood by B<build.pl> itself.
(That is, C<$wrapper>, C<$groupaccess>, etc,
corresponding to the B<build.pl> options with the same names.)

=item B<*>

There is no support for modifiers.
Case is always significant; there is no support for
global substitution or any of the other B<egosmix> options.

=back

Errors in the substitution expression will probably
result in cryptic or outright misleading error messages,
or just weird behavior.

=cut

  my $Help =
      "$me - build procimap and Makefile.conf from corresponding .in files\n";

  ######## FIXME: use Pod::Usage instead once it works more like this
  my (@options);
  local $^A = "";
  while ($pod =~ m/^=for Getopt::Long\s*(?:\n\s*)*\n(.*)\n\s*\n/mg) {
    my $option = $1;
    if ($option =~ /^\s*(\S+)\s+(\S+)\s+(\S+)\s+(.*?)\s*$/) {
      my ($short, $long, $type, $desc) = ($1, $2, $3, $4);
      $short = "" if ($short =~ /^[-*]$/);
      formline <<'________HERE',
@<<--@<<<<<<<<<<< ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
     ~            ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
     ~            ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
________HERE
	 ($short ? "-$short|" : "   "), $long, $desc, $desc, $desc;
      push @options, "$long|$short$type";
    }
    else {
      die "$me: Internal error: $1\n";
    }
  }
  die "$0: Internal error: no options defined\n" unless @options;

  $Help .= $^A;

  GetOptions (\%Conf, @options) || exit 2;

  if ($Conf{help}) {
    print $Help;
    exit 1;
  }

}


my @files = qw(procimap Makefile.conf);


if ($Conf{reverse})
{
    for my $file (@files)
    {
	system ("cp","$file","$file.in") == 0 and next;
	warn "$me: Could not copy $file to $file.in\n";
	exit $? >> 8;
    }
    exit 0;
}

# else


package fnord;

use strict;
use warnings;

use Carp;

sub new
{
    my ($class, %data) = @_;
    my $self = bless { _data => \%data } , $class;
    return $self;
}


sub substitute
{
    my ($self, $string, $from, $to) = @_;

    die "$me: Internal error: \$from not set" unless defined $from;
    die "$me: Internal error: \$to not set" unless defined $to;

    $to =~ s/\$([_A-Za-z][-_0-9A-Za-z]*)/$self->get("$1")/eg;
    if ($string =~ s/$from/$to/)
    {
	return $string;
    }
    # else
    return undef;
}


sub get
{
    my ($self, $attribute) = @_;
    my $value = $self->{$attribute};
    unless (defined $value)
    {
	my $method = $self->can($attribute);
	if ($method)
	{
	    $value = $method->($self, @args);
	}
	else
	{
	    $value = $self->{_data}->{$attribute};
	}

	croak "Could not get attribute '$attribute'" unless defined $value;
	$self->{$attribute} = $value;
    }
    return $value;
}

sub wrapper
{
    my ($self) = @_;
    my $path = $self->get('root') . $self->get('basedir');
    my $value = $self->{_data}->{'wrapper'};
    return join ("/", $path, $value);
}

######## TODO: obsolete this method (??)
sub root
{
    my ($self) = @_;
    return $self->get('install_prefix'); # Oog, not very consistent labels :-(
}


package main;

my $fnord = fnord->new(%Conf);

for my $file (@files)
{
    open (IN, "<$file.in") || die "$me: Could not open $file.in: $!\n";
    open (OUT, ">$file") || die "$me: Could not open $file: $!\n";
    my %subst;
    my $where = "$me: (nowhere yet)";
    while (<IN>)
    {
	# Prefix for diagnostics
	my $fileline = "$file.in:$.";
	$where = "$me: $file.in:$.";

	if (defined $subst{where})
	{
	    my $newline = $fnord->substitute($_, $subst{from}, $subst{to});
	    if ($newline)
	    {
		print OUT $newline;
		undef %subst;
		next;
	    }
	}

	#     #1              #2      #3            #4     #5
	if (m/(.*\@\@build\.pl(\S)s([^][\{\}\(\)<>])(.*?)\3(.*?)\3\@\@.*)/)
	{ # really weird cperl error, end of m/.../ not found

	    die "$where: Substitution at line $subst{where} didn't match\n"
		if (defined $subst{where});

	    my ($line, $addrmode, $from, $to) = ($1, $2, $4, $5);
	    if ($addrmode eq '#')
	    {
		my $newline = $fnord->substitute($line, $from, $to);
		unless ($newline)
		{
		    close OUT;
		    unlink "$file";
		    die "$where: Did not match '$from' -- aborting: $line\n";
		}
		# else
		print OUT "$newline\n";
	    }
	    elsif ($addrmode eq '>')
	    {
		print OUT;
		%subst = (where => $fileline, from => $from, to => $to);
	    }
	    else
	    {
		die "$where: Bad addressing mode '$addrmode': $line";
	    }
	}
	else
	{
	    print OUT;
	}
    }

    # if %subst defined at eof, die again (TODO: sell rights to Bond movie)
    die "$where: Substitution at line $subst{where} didn't match\n"
	if (defined $subst{where});
}


=head1 BUGS

This POD documentation sucks.

This ought to be a standard tool
so I wouldn't have to invent it.


=head1 AUTHOR

era eriksson
L<http://www.iki.fi/era/>


=head1 LICENSE

BSD "new-style" (attribution-free).

=cut
