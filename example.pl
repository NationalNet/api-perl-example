#!/usr/bin/perl

use strict;
use warnings;
use URI::Escape;
use Digest::SHA qw(hmac_sha256_base64);
use LWP;
use POSIX qw(strftime);
use Data::Dumper;
use JSON;

# Defaults
my $timestamp = time();
my $host = 'api.nationalnet.com';
my $method = 'GET';
my $user = ''; # your myNatNet username
my $api_key = ''; # api-key string found in myNatNet user profile

# The different API Endpoints
my $list_graphs_path = '/api/v1/graphs';
my $data_path = '/api/v1/graphs/:id/data';

# User Agent
my $ua = LWP::UserAgent->new;
$ua->agent("Mozilla/5.0 (X11; Linux i686) AppleWebKit/535.11 (KHTML, like Gecko) Chrome/17.0.963.56 Safari/535.11");
$ua->default_header('content_type' => 'application/json');
$ua->default_header('accept' => 'application/json');
$ua->default_header('host' => $host);

#############################################################################
# Fetch your account graphs.
#############################################################################

my $uri = 'https://' . $host . $list_graphs_path;
my %parameters = (
	'date' => $timestamp,
	'method' => 'GET',
	'username' => $user,
	'canonical' => get_canonical_string(()),
	'api_key' => $api_key,
	'host' => $host
);

my $signature = create_signature(\%parameters);
$ua->default_header('x-nnws-auth' => "$user:$signature");
$ua->default_header('date' => strftime("%a, %d %b %Y %H:%M:%S %z", localtime($timestamp)));

my $request = HTTP::Request->new(GET => $uri);
my $response = $ua->request($request);

my $graphs = from_json($response->{'_content'});
my $graph_id = '';
for my $graph (@{$graphs}) {
    $graph_id = $graph->{'id'};
    last;
    # Uncomment for debugging.
    #print $graph->{'id'} . "\n";
    #print Dumper($graph);
}

#############################################################################
# Fetch some data
#############################################################################

my $start_time = $timestamp - 86400;
my $end_time = $timestamp;
my %query_params = ('start' => $start_time, 'end' => $end_time);

$uri = 'https://' . $host . $data_path . '?start=' . $start_time . '&end=' . $end_time;
$uri =~ s/:id/$graph_id/g;

%parameters = (
	'date' => $timestamp,
	'method' => 'GET',
	'username' => $user,
	'canonical' => get_canonical_string(\%query_params),
	'api_key' => $api_key,
	'host' => $host
);

$signature = create_signature(\%parameters);

$ua->default_header('x-nnws-auth' => "$user:$signature");
$ua->default_header('date' => strftime("%a, %d %b %Y %H:%M:%S %z", localtime($timestamp)));

$request = HTTP::Request->new(GET => $uri);
$response = $ua->request($request);

my $all_series = from_json($response->{'_content'});

for my $series_name (%{$all_series}) {
    while ((my $poll_time, my $data_val) = each(%{$all_series->{$series_name}})) {
        # Uncomment for debugging.
        #print "$poll_time $data_val\n";
    }
}

##
# Create a canonical string off a hashref of query parameters
##
sub get_canonical_string {
    my $params = shift;
    my $string = '';
    
    foreach my $key (sort keys %{$params}) {
        $string .= uri_escape($key) . '=' . uri_escape($params->{$key}) . '&';
    }
    
    return $string eq '' ? $string : substr($string, 0, -1);
}

##
# Create the HMAC Signature. Takes hashref of parameters.
##
sub create_signature {
    my $params = shift;
    
    my $string_to_sign = $params->{'method'} . "\n"
        . $params->{'username'} . "\n"
        . $params->{'host'} . "\n"
        . $params->{'date'} . "\n"
        . $params->{'canonical'};
                
    my $digest = hmac_sha256_base64($string_to_sign, $params->{'api_key'});
    
    while (length($digest) % 4) {
        $digest .= '=';
    }
	
    return $digest;
}
