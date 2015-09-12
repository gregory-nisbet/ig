use strict;
use warnings FATAL => 'all';
use Data::Dumper;

# parse keybindings
# regexes for matching individual keys 
my $key = qr/\S|ESC|SPC|TAB/;
my $key_chord = qr/(?:[CMS]-)*$key/;
my $compound_key = qr/(?:$key_chord\s)*$key_chord/;

my $emacssym = qr/[\w\-]+/;

sub pd {
    print Dumper($_[0]);
}

sub expand_keybinding {
    @_ == 1 or die;
    my $k = shift;
    ref $k eq q[] or die;
    defined $k or die;
    $k =~ $compound_key or die 'not a compound key';
    return [$k =~ m/($key_chord)\s?/g];
}

sub convert_binding {
    @_ == 1 or die;
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
    @_ == 1 or die;
    my $line = shift;
    $line =~ m/^\s*($compound_key)\t+($emacssym)/;
    # extract compound key
    my $key = $1;
    my $value = $2;

    do { print "BAD LINE:: $line\n"; return 0 } unless defined $key and defined $value;

    my $expanded = expand_keybinding($key);
    my $converted = convert_binding($expanded);
    my $snippet = elisp_snippet($converted, $value);
    my $test = 
        {
            key => $key,
            value => $value,
            raw => $line,
            expanded => $expanded = expand_keybinding($key),
            converted => $converted = convert_binding($expanded),
            snippet => elisp_snippet($converted, $value),
        };
    return $test;
}

sub elisp_snippet {
    @_ == 2 or die;
    my $keys_ref = shift;
    my $command = shift;
    return sprintf q[(define-key 'ig-map (kbd "%s") %s)], "@$keys_ref", $command;
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
