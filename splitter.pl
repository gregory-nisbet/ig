use strict;
use warnings FATAL => 'all';
use Data::Dumper;

use vars q[*LOG];

sub ref_eq {
    ref $_[0] or return 0;
    ref $_[1] or return 0;
    $_[0] == $_[1] and return 1;
}

# parse keybindings
# regexes for matching individual keys 
# does not handle digit argument or keybind ranges
# TODO handle ranges better
my $key = qr/[^ \t\n]|ESC|SPC|TAB|RET|left|right|up|down/;
my $key_chord = qr/(?:[CMS]-)*$key/;
my $compound_key = qr/<?(?:$key_chord\s)*$key_chord>?/;

my $emacssym = qr/[\w\-]+/;

my @lines;

sub record_line {
    push @lines, $_[0];
}

# open log file.
open(LOG, ">", "/tmp/splitter-log");

sub expand_keybinding {
    @_ == 1 or die;
    my $k = shift;
    ref $k eq q[] or die;
    defined $k or die;
    $k =~ $compound_key or die 'not a compound key';

    printf "%\n", (join " ", $k =~ m/($key_chord)\b/g) if index($k, '@') != -1;

    return [$k =~ m/($key_chord)\b/g];
}

sub convert_binding {
    @_ == 1 or die;
    my $in = shift;
    my @sequence;
    for my $x (@$in) {
        if ($x =~ /^C-M-S-($key)/) {
            push @sequence, qw[ctrl meta shift], $1;
        }
        elsif ($x =~ /^C-M-($key)$/) {
            push @sequence, qw[ctrl meta], $1;
        }
        elsif ($x =~ /^C-($key)$/) {
            push @sequence, "ctrl", $1;
        }
        elsif ($x =~ /^M-($key)$/) {
            push @sequence, "meta", $1;
        }
        elsif ($x =~ /^($key)$/) {
            push @sequence, $1;
        }
        else {
            die 'cannot interpret ' . Dumper $in;
        }
    }
    return [@sequence];
}

sub process_line {
    @_ == 1 or die;
    my $line = shift;
    $line =~ m/^\s*($compound_key)\t+($emacssym)/;
    # extract compound key
    my $key = $1;
    my $value = $2;

    defined $value and $value eq 'Prefix' and return;

    do { print LOG "BAD LINE:: $line"; return 0 } unless defined $key and defined $value;

    do {
        local $@;
        eval {
            my $expanded = expand_keybinding($key);
            my $converted = convert_binding($expanded);
            my $test = 
                {
                    key => $key,
                    value => $value,
                    raw => $line,
                    expanded => $expanded,
                    converted => $converted,
                };
            printf "%s -> %s -> %s\n", $key, "@$expanded", "@$converted";
            return $test;
        };
        # catch previous excluded_key_binding
        # comparing $@ pointerwise, not ideal
    }
}


sub filter {
    my $start_of_section = 0;
    my $end_of_section = 0;

    while (<>) {
        my $line = $_;
        if ($line =~ /^C-@.*set-mark-command$/) {
            $start_of_section = 1;
        }
        elsif ($line =~ /^Input.*:$/) {
            $end_of_section = 1;
            last;
        }
        if (not $line =~ /^\s*$/) {
            if ($start_of_section and not $end_of_section) {
                my $processed = process_line($line);
                defined $processed and record_line($processed);
            }
        }
    }
}


filter;
