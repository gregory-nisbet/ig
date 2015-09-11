use strict;
use warnings FATAL => 'all';
use Data::Dumper;

# parse keybindings
# regexes for matching individual keys 
my $key = qr/\S|ESC|SPC|TAB/;
my $key_chord = qr/(?:[CMS]-)*$key/;
my $compound_key = qr/^(?:$key_chord\s)+$key_chord/;

my $emacssym = qr/[\w\-]+/;

sub pd {
    print Dumper($_[0]);
}

sub expand_keybinding {
    my $key = shift;
    $key =~ $compound_key or die 'not a compound key';
    return [$key =~ m/($key_chord)\s?/g];
}

sub convert_binding {
    my $in = shift;
    my @sequence;
    for my $x (@$in) {
        if ($x =~ /^C-M-($key)$/) {
            push @sequence, "G", $1;
        }
        elsif ($x =~ /^C-($key)$/) {
            push @sequence, $1;
        }
        elsif ($x =~ /^M-($key)$/) {
            push @sequence, "g", $1;
        }
        elsif ($x =~ /^($key)$/) {
            push @sequence, "SPC", $1;
        }
        else {
            die 'cannot interpret ' . Dumper $in;
        }
    }
    return [@sequence];
}

sub process_line {
    my $line = shift;
    $line =~ m/^($compound_key)\t+($emacssym)/;
    # extract compound key
    my $key = $1;
    my $value = $2;
    return (defined $key and defined $value) ? 
        {
            key => $key,
            value => $value,
            raw => $line,
            expanded => expand_keybinding($key),
            converted => convert_binding(expand_keybinding($key)),
        } 
    : undef;
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
                defined $processed and pd($processed);
            }
        }
    }
}

filter;
