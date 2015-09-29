use strict;
use warnings FATAL => 'all';

use Data::Dumper;
use List::Util qw[max];
use feature qw[say];


sub wanted_line {
    my $line = shift;
    my @words = split /\s+/, $line;
    return 0 unless @words;
    # Prefix Command means not a keybinding we care about
    return 0 if $line =~ /prefix.command/i;
    # must start with actual binding
    return 0 if $line =~ /^key/i;
    # delimiters
    return 0 if $words[0] eq '---';
    # major mode bindings
    return 0 if /^major mode bindings/i;
    # .. indicates a range 
    return 0 if /\.\./;
    # global bindings
    return 0 if /^global bindings/i;
    # process of elimination
    return 1;
}

sub split_words {
    my $raw = shift;
    my @words = split /\s+/, $raw;
    @words = map {
        my $word = $_;
        $word =~ /(C\-)?(M\-)?(S\-)?(\S+)/;
        my @out;
        push @out, "ctrl" if $1;
        push @out, "meta" if $2;
        push @out, "shift" if $3;
        push @out, $4 if $4;
        @out;
    } @words;
    return @words;
}

sub process_line {
    my $line = shift;
    $line =~ s/<([\w\-]+)>/$1/gr;
}

my @stored;
while (<>) {
    my $line = $_;
    $line = process_line($line);
    chomp $line;
    if (wanted_line($line)) {
        my @sections = split /\t+/, $line;

        if (@sections == 1) {
            # print "skipping: $line\n";
            next;
        }

        my ($lhs, $rhs) = map { [split_words($_)] } @sections;
        
        printf "%-32s=%40s\n" , "@$lhs", "@$rhs";
    }
}

