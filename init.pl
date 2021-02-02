#!/usr/bin/env perl

### WARNING ####################################################################
# Project initialization from the template can only happen once. To facilitate #
# keeping to this rule, this file (`init.pl') will try to delete itself,       #
# after a successful, non-dry run.                                             #
# Keep this in mind.                                                           #
# Thank you, bodand!                                                           #
################################################################################

# This file is part of the `cxxlibs-template' template.
#
# Copyright (C) 2020 bodand
#
# Permission to use, copy, modify, and/or distribute this software for any purpose
# with or without fee is hereby granted.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
# REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND
# FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
# INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS
# OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER
# TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF
# THIS SOFTWARE.

use v5.22;

use strict;
use warnings;
no warnings qw/experimental/;
use utf8;

use Getopt::Long qw/&VersionMessage &HelpMessage
    :config no_auto_abbrev no_getopt_compat
    gnu_compat gnu_getopt permute bundling_override no_ignore_case
    auto_version pass_through/;
use Carp;
use Config;
use Cwd qw/cwd/;
use File::Basename qw/basename/;
use File::Copy qw/move/;

# file_proc (%db, $file)
sub do_file :prototype(\%_);
sub dry_file :prototype(\%_);
# dir_proc (file_proc, %db, $dir)
sub do_dir :prototype($\%_);
sub dry_dir :prototype($\%_);

use version 0.77;
our $VERSION = version->declare('v1.0.0');
my %config = (
    dry       => 0,
    file_proc => \&do_file,
    dir_proc  => \&do_dir,
    logger    => sub {},
);
my %db = (
    'Init.Version'   => $VERSION->stringify,
    'Static.NewLine' => "\n",
    'Static.Tab'     => "\t",
    'Git.Config'     => sub :prototype($;$) {
        my ($key, $force_reload) = (@_, 0);
        state %cache = ();

        delete $cache{$key} if $force_reload;

        unless (exists $cache{$key}) {
            $cache{$key} = `git config "$key"`;
            chomp $cache{$key}
        }

        $cache{$key}
    },
);

GetOptions(
    "project|P=s" => \$db{'Project.Name'},
    "target|T=s"  => \$db{'Project.Target'},
    "value|v=s%"  => \%db,
    "dry-run|n!"  => sub {
        my (undef, $dry) = @_;
        if (($config{dry} = $dry)) {
            $config{file_proc} = \&dry_file;
            $config{dir_proc} = \&dry_dir
        }
        else {
            $config{file_proc} = \&do_file;
            $config{dir_proc} = \&do_dir
        }
    },
    'd'           => sub {
        $config{logger} = sub {say STDERR @_}
    },
    "help|h|?"    => sub {
        HelpMessage(
            -output  => \*STDOUT,
            -exitval => 1,
            -verbose => 1
        )
    }
);

sub db_add_date :prototype($) {
    my ($hash) = @_;
    my @times = localtime time;

    my @keys = qw/Time.Sec Time.Min Time.Hour Date.Day Date.Month Date.Year/;
    $hash->@{@keys} = @times;

    $hash->{'Date.Year'} += 1900;
    $hash->{'Date.Full'} = sprintf "%s-%02s-%02s",
        $hash->{'Date.Year'},
        $hash->{'Date.Month'},
        $hash->{'Date.Day'};
    $hash->{'Time.Full'} = sprintf "%02s:%02s:%02s",
        $hash->{'Time.Hour'},
        $hash->{'Time.Min'},
        $hash->{'Time.Sec'};
}

sub db_get :prototype(\%$) {
    my ($db, $key) = @_;
    given (ref $db{$key}) {
        $db->{$key}
            when /^(|CODE)$/n;
        $db->{$key}->$*
            when 'SCALAR';
        '[' . join(',', $db->{$key}->@*) . ']'
            when 'ARRAY';
        '{' . join(',', $db->{$key}->%*) . '}'
            when 'HASH';
        default {'bad db entry'};
    }
}

db_add_date \%db;
$db{'Project.Target'} = $db{'Project.Name'}
    unless defined $db{'Project.Target'};

sub interpol :prototype(\%_) {
    my $db = shift;
    local $_ = shift;

    s!\@([^\{\@]+?)\{([^\}]+?)\}\@!
        db_get($db->%*, $1)->($2) // ''
    !eg;
    s{\@([^\@]+?)\@}{
        my ($val, $def) = (split('//', $1), '');

        db_get($db->%*, $val) // $def;
    }eg;
    $_
}

sub do_file :prototype(\%_) {
    my ($db, $file) = @_;

    $config{logger}->("entering file: $file");
    local $^I = '';
    local @ARGV = ($file);
    while (<<>>) {
        $_ = interpol $db->%*, $_;
        print
    }
    $config{logger}->("leaving file: $file");
}

sub dry_file :prototype(\%_) {
    my ($db, $file) = @_;
    $config{logger}->("entering file: $file");

    local $.;
    open my $fh, '<', $file
        or croak "error: cannot open file $file: $!";
    while (<$fh>) {
        # note: since v5.20 $& and co are safe to use
        while (/\@([^\@\{]+?)\{([^\}]+?)\}\@/gc) {
            my $rep = db_get($db->%*, $1)->($2);
            my $col = 1 + index $_, $&;
            say "$file:$.:$col: replace '$&' with '$rep'"
        }
        while (/\@([^\{\}\@]+?)\@/gc) {
            my ($val, $def) = (split('//', $1), '');

            my $rep = db_get($db->%*, $val) // $def;
            my $col = 1 + index $_, $&;
            say "$file:$.:$col: replace '$&' with '$rep'"
        }
    }

    $config{logger}->("leaving file: $file");
}

sub dry_dir :prototype($\%_) {
    state $name = basename $0;
    state $depth = 0;
    my ($file_proc, $db, $dir) = @_;

    $depth++;
    $config{logger}->($name . "[$depth]: entering directory: $dir");

    opendir my $dh, $dir
        or croak "error: cannot open directory $dir: $!";
    while (local $_ = readdir $dh) {
        next if /^\./;
        next if $_ eq $name;

        if (/^!/) {
            my $new_name = interpol($db->%*, $_);
            $new_name =~ s/^!//;
            say "rename '$dir/$_' to '$dir/" . $new_name . "'";
        }

        &dry_dir($file_proc, $db, "$dir/$_") if -d "$dir/$_";
        $file_proc->($db, "$dir/$_") if -f "$dir/$_";
    }

    $config{logger}->($name . "[$depth]: leaving directory: $dir");
    $depth--;
}

sub do_dir :prototype($\%_) {
    state $name = basename $0;
    state $depth = 0;
    my ($file_proc, $db, $dir) = @_;

    $depth++;
    $config{logger}->($name . "[$depth]: entering directory: $dir");

    opendir my $dh, $dir
        or croak "error: cannot open directory $dir: $!";
    while (local $_ = readdir $dh) {
        next if /^\./;
        next if $_ eq $name;

        if (/^!/) {
            my $new_name = interpol($db->%*, $_);
            $new_name =~ s/^!//;
            rename "$dir/$_", "$dir/$new_name";
            $_ = $new_name;
        }

        $config{logger}->("checking $dir/$_: " . (-d "$dir/$_" ? 'dir' : 'not-dir'));
        &do_dir($file_proc, $db, "$dir/$_") if -d "$dir/$_";
        $file_proc->($db, "$dir/$_") if -f "$dir/$_";
    }

    $config{logger}->($name . "[$depth]: leaving directory: $dir");
    $depth--;
}

$config{dir_proc}->($config{file_proc}, \%db, cwd);

__END__

=pod

=head1 NAME

init.pl - Initializes the library template

=head1 SYNOPSIS

init.pl [OPTIONS] -P TestProject

=head1 OPTIONS

=over 4

=item B<--help>, B<-h>, B<-?>

Prints this help

=item B<--version>

Prints version information

=item B<--project> C<name>, C<-P> C<name>

The name of the project. This value has to be provided

=item B<--target> C<target>, C<-T> C<target>

Defines the target to build for the project.

=item B<--value> C<key>=C<value>, B<-v> C<key>=C<value>

Adds a user provided value into the database. This allows C<key> to be used
inside a replacement as a string value and it'll be mapped to C<value>.

=item B<--dry-run>, B<-n>

Do not actually do anything, just print what I'd have done normally.

=back

=head1 DESCRIPTION

Initializes the template by inserting the given values into the placeholder values.

The database always contains the keys as described by the following table. Type
is discussed in further detail in the L</Values injection> section.

 Key            | Type     | Defaulted-ness?
 -------------------------------------------------------------------------------
 Date.Day         String     Default
 Date.Month       String     Default
 Date.Year        String     Default
 Date.Full        String     Default ("Year-Month-Day")
 Time.Sec         String     Default
 Time.Min         String     Default
 Time.Hour        String     Default
 Time.Full        String     Default ("Hour:Min:Sec")
 Project.Name     String     User provided
 Project.Target   String     User provided or defaulted to Project.Name
 Git.Config       Function   Default

=head2 Values injection

The database to insert consists of a key-value correlation, where the values
can be either simple strings, or a function. Functions take one argument
and return an appropriate string which is then interpolated into the file.

Syntax for insertion is the following:

 @Key@ for simple strings
 @Key{Argument}@ for functions

Functions cannot be inserted by themselves and will expand to an undefined
string when you try to do so nevertheless.

=cut
