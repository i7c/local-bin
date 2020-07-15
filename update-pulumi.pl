#!/usr/bin/perl

use strict;
use warnings;

use LWP::Simple;
use File::Temp qw/ tempdir /;
use File::Basename;

sub installation_path {
    if (defined $ARGV[0]) {
        return $ARGV[0];
    }
    my $pulumi_bin = `which pulumi` or die "Did not find current installation and you did not specify an installation path.";
    dirname($pulumi_bin);
}

my $installation_dir = installation_path();
print "Will try to install to $installation_dir\n";

my $content = get('https://www.pulumi.com/docs/get-started/install/versions/')
    or die "Could not parse the pulumi page for current versions.";
$content =~ m{The current stable version of Pulumi is <strong>(\d+\.\d+\.\d+)</strong>\.};

my $download_link = "https://get.pulumi.com/releases/sdk/pulumi-v$1-linux-x64.tar.gz";
print "\n >\n > Will install $download_link\n >\n";


my $dir = tempdir( CLEANUP => 1 );
my $download_path = "$dir/pulumi.tar.gz";

print "Will save to $download_path\n";
`wget -O $download_path $download_link`;

print "Unpacking ...\n";
`tar xfv $download_path --strip-components=1 -C $installation_dir` or die "Unpacking failed.";

`$installation_dir/pulumi version`;
