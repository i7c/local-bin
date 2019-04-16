#!/bin/perl
#
# Login to a specific Azure subscription read from a simple key/val config file.
# You might want to use this script in combination with this shell alias:
# alias pulumi-auth-sp='echo -n "Enter password for credentials: "; read -s PULUMI_CONFIG_PASSPHRASE; export PULUMI_CONFIG_PASSPHRASE; pulumi-auth-sp.pl'
#
# Scrpt expects PULUMI_CONFIG_PASSPHRASE to be set.
# If you want to store passwords in plaintext, change --secret to --plaintext.


use JSON;
use Config::Simple;
use Data::Dumper;

die "Need a config file!" unless defined $ARGV[0];
my $cfg = Config::Simple->new($ARGV[0])->vars;

die "Missing client_id" unless my $client = $cfg->{"default.client_id"};
die "Missing secret_id" unless my $secret = $cfg->{"default.client_secret"};
die "Missing tenant_id" unless my $tenant = $cfg->{"default.tenant_id"};
die "Missing subscription_id" unless my $subscription = $cfg->{"default.subscription_id"};

print `pulumi config set azure:clientId $client`;
print `pulumi config set azure:clientSecret $secret --secret`;
print `pulumi config set azure:tenantId $tenant`;
print `pulumi config set azure:subscriptionId $subscription`;
print "\n\n";
print "Careful! The variable PULUMI_CONFIG_PASSPHRASE contains your password in this shell! Closing the shell will get rid of it.\n";
