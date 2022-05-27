#!/usr/bin/perl
# By Christian Hollinger. Public domain because setting up a license for it is too much of a hassle for such a small script lol.
use strict;
use warnings FATAL => 'all';
use Net::Ping;
use Text::CSV;
use Term::ANSIColor;
use MIME::Lite;
use Socket::GetAddrInfo "getaddrinfo";
use Data::Dumper;
use 5.32.1;
use experimental 'smartmatch';

use constant {
    TO_EMAIL     => [''],
    FROM_EMAIL   => '',
};

=head3 SEND($msg):
Define your own subroutine for sending a notification email here.

=cut
sub SEND {
    $_[0]->send("your", "arguments", "here");
}

say("Started at ",my $starttime = localtime(),"...");
# Create an array from the targets.csv file of scanning targets.
my $csv = Text::CSV->new();
my @targets;
say("Opening targets.csv...");
open(FH, '<', "targets.csv") or die($!);
while (my $line = <FH>) {
    chomp $line;
    if ($csv->parse($line)) {
        push(@targets, $csv->fields());
    }
}
close(FH);

say("Read ", scalar @targets," hosts.");

my $p = Net::Ping->new();
my @unreached_targets;
for(;;) {
    foreach my $target (@targets) {
        say("Pinging $target...");
        my ($result, $time, $ip) = $p->ping($target);
        my %host = (
            "hostname" => $target,
            "ip"       => $ip,
            "time"     => $time
        );

        if (!defined($result) || $result == 0) {
            say("\a".colored(my $msg_text = ("Unable to reach $target at ".localtime().". Reason: ".Dumper(getaddrinfo($target))), "red"));

            if ($target  !~~ @unreached_targets) {
                my $msg = MIME::Lite->new(
                    From    => FROM_EMAIL,
                    To      => TO_EMAIL,
                    Subject => 'Network Monitor Warning',
                    Data    => $msg_text . " (" . localtime() . ") " . getaddrinfo($target)
                );

                # Uncomment the line below if you want to send an email when a device is down.
                #SEND($msg);
                push(@unreached_targets, $target);
            } else { say(colored("Not sending a notification because one was already sent for this host.")) }
        }
        else {
            say(colored("Reached $host{'hostname'} at $host{'ip'} in $time seconds.", "green"));
        }
        sleep(2);
    }
}





