# $Id: Compact.pm,v 1.1.1.1 2004/09/23 02:34:31 andrew Exp $
# Copyright (c) 2004 Andrew Stewart Williams. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

package Getopt::Compact;
use strict;
use Getopt::Long;
use Carp;
use vars qw($VERSION %DEFAULT_CONFIG);
use 5.004;

BEGIN {
    %DEFAULT_CONFIG = (no_auto_abbrev => 1, bundling => 1);
    $VERSION = '0.01';
}

=head1 NAME

Getopt::Compact - getopt processing in a compact statement with both
long and short options, and usage functionality.

=head1 SYNOPSIS

inside foobar.pl:

    use Getopt::Compact;

    my $opt = new Getopt::Compact
        (name => 'foobar program', version => '1.0',
         modes => [qw(verbose test debug)],
         struct =>
         [[[qw(w wibble)], qq(specify a wibble parameter), ':s'],
          [[qw(f foobar)], qq(apply foobar algorithm)],
          [[qw(j joobies)], qq(jooby integer list), '=i', \@joobs],
         ]
        )->opts;

    print "applying foobar algorithm\n" if $opt->{foobar};
    print "joobs: @joobs\n" if @joobs;

running the command './foobar.pl -x' results in the following output:

    Unknown option: x
    foobar program v1.0
    usage: foobar.pl [options]
    options
    -h, --help      This help message
    -v, --verbose   Verbose mode
    -n, --test      Test mode
    -d, --debug     Debug mode
    -w, --wibble    Specify a wibble parameter
    -f, --foobar    Apply foobar algorithm
    -j, --joobies   Jooby integer list

=head1 DESCRIPTION

This is yet another Getopt related module.  Getopt::Compact is geared
towards compactly and yet quite powerfully describing an option
syntax.  Options can be parsed, returned as a hashref of values,
and/or displayed as a usage string.  Options can be retrieved in a
single statement by instantiating a Getopt::Compact object and calling
the opts() method (see SYNOPSIS).

=head1 PUBLIC METHODS

=over 4

=item new()

    my $go = new Getopt::Compact(%options)

Instantiates a Getopt::Compact object.  This will parse the command
line arguments and store them for later retrieval (via the opts()
method).  On error a usage string is printed and exit() is called,
unless you have set the 'usage' option to false.

The following constructor options are recognised:

=over 4

=item name

=over 4

The name of the program.  This is printed at the start of the usage string.

=back

=item cmd

=over 4

The command used to execute this program.  Defaults to $0.  This will be
printed as part of the usage string.

=back

=item version

=over 4

Program version.  Can be an RCS Version string, or any other string.
Displayed in usage information.

=back

=item usage

=over 4

'usage' is set to true by default.  Set it to false (0) to disable the
default behaviour of automatically printing a usage string and exiting
when there are parse errors or the --help option is given.  When set
to true a help option (-h or --help) is automatically prepended to the
list of available options.

=back

=item args

=over 4

A string describing mandatory arguments to display in the usage string.
eg: 

print new Getopt::Compact
    (args => 'foo', cmd => 'bar.pl)->usage;

displays:

usage: bar.pl [options] foo

=back

=item modes

=over 4

This is a shortcut for defining boolean mode options, such as verbose
and test modes.  Set it to an arrayref of mode names, eg
[qw(verbose test)].  The following statements are equivalent:

    my $go = new Getopt::Compact
        (struct => [[[qw(v verbose)], qw(verbose mode)],
                    [[qw(n test)],    qw(test mode)],
                    [[qw(d debug)],   qw(debug mode)],
		    [[qw(f foobar)],  qw(activate foobar)],
                   ]);

and

    my $go = new Getopt::Compact
        (modes => [qw(verbose test debug)],
	 struct => [[[qw(f foobar)], qq(activate foobar)]]);

modes will be prepended to options defined via the 'struct' option.

=back

=item struct

=over 4

This is where most of the option configuration is done.  The format for
a struct option is an arrayref of arrayrefs in the following form
([] denotes an arrayref):

struct => [arrayref, arrayref]

arrayref is of the form (only optref is required):

[optref, description, argument specification, destination]

optref is of the form:

[qw(x yyyyy)]
where x is the short (single character) option and yyyyy is the long option.

The 'argument specification' is passed directly to Getopt::Long, so
any argument specification recognised by Getopt::Long should also work
here.  Some argument specifications are:

    =s  Required string argument
    :s  Optional string argument
    =i  Required integer argument
    +   Value incrementing

Refer to Getopt::Long documentation for more details on argument
specifications.

The 'destination' is an optional reference to a variable that will
hold the option value.  If destination is not specified it will be
stored internally by Getopt::Compact and can be retrieved via the
opts() method.
This is useful if you want options to accept multiple values.  The
only way to achieve this is to use a destination that is a reference
to a list (see the joobies option in SYNOPSIS by way of example).

=back

=item configure

=over 4

Optional configure arguments to pass to Getopt::Long::Configure in the form
of a hashref of key, boolean value pairs.
By default, the following configuration is used:

{ no_auto_abbrev => 1, bundling => 1 }

To disable bundling and have case insensitive single-character options you
would do the following:

new Getopt::Compact
    (configure => { ignorecase_always => 1, bundling => 0 });

see Getopt::Long documentation for more information on configuration options.

=back

=back

=item usage()

    print $go->usage();

Returns a usage string.  Normally the usage string will be printed
automatically and the program will exit if the user supplies an
unrecognised argument or if the -h or --help option is given.
Automatic usage and exiting can be disabled by setting 'usage'
to false (0) in the constructor (see new()).
This method uses Text::Table internally to format the usage output.

=item status()

    print "getopt ".($go->status ? 'success' : 'error'),"\n";

The return value from Getopt::Long::Getoptions(). This is a true value
if the command line was processed successfully. Otherwise it returns a
false result.

=item opts()

    $opt = $go->opts;

Returns a hashref of options keyed by long option name.  If the
constructor usage option is true (on by default), then a usage string
will be printed and the program will exit if it encounters an
unrecognised option or the --help option is given.

=back

=head1 AUTHOR

Andrew Stewart Williams <andrew.s.williams@adelaide.edu.au>

=head1 SEE ALSO

Getopt::Long

=cut

sub version { $VERSION }

sub new {
    my($proto, %args) = @_;
    my $self = bless {}, ref $proto || $proto;
    my(%opt, $i);

    $args{struct} ||= [];
    for $i (qw(struct usage name version cmd args configure modes)) {
        next unless exists $args{$i};
        $self->{$i} = $args{$i};
        delete $args{$i};
    }
    for $i (keys %args) { carp("unrecognised option: $i"); }
    my $struct = $self->{struct};
    $self->{usage} = 1 unless exists $self->{usage};
    unless($self->{cmd}) {
	$self->{cmd} = $0 || '';
	$self->{cmd} =~ s|^.*/||;
    }

    # struct sanity checking
    for(my $i = 1; $i <= @$struct; $i++) {
	my $s = $struct->[$i-1];
	croak "option #$i: malformed option string"
	    unless @{$s->[0]} == 2;
    }

    # add mode options
    if($self->{modes}) {
	my @modeopt;
	for my $m (@{$self->{modes}}) {
	    my($mc) = $m =~ /^(\w)/;
	    $mc = 'n' if $m eq 'test';
	    push @modeopt, [[$mc, $m], qq($m mode)];
	}
	unshift @$struct, @modeopt;
    }
    # add help option if usage is enabled
    unshift @$struct, [[qw(h help)], qq(this help message)]
	if $self->{usage} && !grep $_->[0]->[1] eq 'help', @$struct;

    $self->{opthash} = {
	map {
	    join('|', @{$_->[0]}).($_->[2] || "") => 
		$_->[3] ? $_->[3] : \$opt{$_->[0]->[1]} 
	} @$struct
    };
    $self->{opt} = \%opt;

    # configure getopt option preferences
    my $config = $self->{configure} || {};
    $config->{$_} = $DEFAULT_CONFIG{$_} for 
	grep !exists $config->{$_}, keys %DEFAULT_CONFIG;
    Getopt::Long::Configure(grep $config->{$_}, keys %$config);

    # parse options
    $self->{ret} = GetOptions(%{$self->{opthash}});

    return $self;
}

sub opts {
    my($self) = @_;
    my $opt = $self->{opt};
    if($self->{usage} && ($opt->{help} || $self->status == 0)) {
        print $self->usage;
        exit !$self->status;
    }
    return $opt;
}

sub status {
    my($self) = @_;
    return $self->{ret};  # return return value of GetOptions
}

sub _rev2version {
    my($v) = @_;
    $v =~ s/\$//g;  # remove rcs $ signs
    $v =~ s/Revision:?\s*//g;
    return $v || '1.0';
}

# return a string explaining usage
sub usage {
    my($self) = @_;
    my $usage = "";
    my($v, @help);

    if($self->{name}) {
	$usage .= $self->{name};
	if($v = $self->{version}) {
	    $v = &_rev2version($v);
	    $usage .= " v$v";
	}
	$usage .= "\n";
    }
    $usage .= "usage: ".$self->{cmd}." [options] ".
	($self->{args} || "")."\n";
    for my $o (@{$self->{struct}}) {
	next unless $o->[1];
	my $optname = join
	    (', ',map { (length($_) > 1 ? '--' : '-').$_ } (@{$o->[0]}));
	push @help, [ $optname, ucfirst($o->[1]) ];
    }
    require Text::Table;
    my $sep = '   ';
    my $tt = new Text::Table('options', \$sep, '');
    $tt->load(@help);
    $usage .= $tt."\n";
    return $usage;
}

1;
