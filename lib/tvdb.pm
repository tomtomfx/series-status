package tvdb;	
use LWP::UserAgent;
use LWP::Simple;
use JSON;
use Time::localtime;
use Data::Dumper;
use strict;

require Exporter;
my @ISA = qw/Exporter/;
my @EXPORT = qw/authentication getShowImage/;

sub sendRequest
{
	my $ua = $_[0]; my $req = $_[1];
	my $resp = $ua->request($req);
	if ($resp->is_success) 
	{
		my $message = $resp->decoded_content;
		return $message;
	}
	else 
	{
		print "HTTP POST error code: ", $resp->code, "\n";
		print "HTTP POST error message: ", $resp->message, "\n";
		return 0;
	}
}

sub authentication {
    my ($verbose, $tvdbApiKey, $tvdbUser, $tvdbUserKey) = @_;
	my $ua = LWP::UserAgent->new;
	my $authURL = "https://api.thetvdb.com/login";
	my $token = "";
	
    my $header = ['Content-Type' => 'application/json', 'Accept' => 'application/json'];
    my $data = {apikey => $tvdbApiKey, username => $tvdbUser, userkey => $tvdbUserKey};
    my $encoded_data = encode_json($data);
 
    my $r = HTTP::Request->new('POST', $authURL, $header, $encoded_data);
    my $res = sendRequest($ua, $r);

	if ($res ne 0)
	{
        $data = decode_json($res);
		return $data->{'token'};
	}
	else {return 0;}
}

sub getShowImage()
{
    my ($verbose, $token, $showId, $type) = @_;
    my $tvdbImagePath = 'https://artworks.thetvdb.com/banners';
    my $ua = LWP::UserAgent->new;
	my $url = "https://api.thetvdb.com/series/$showId/images/query?keyType=$type";
    my $data = "";
    my $imageUrl = "";
    my $imageRating = -1;


    my $header = ['Content-Type' => 'application/json', 'Accept-Language' => 'en', 'Authorization' => "Bearer $token"];
    
    my $r = HTTP::Request->new('GET', $url, $header);
    my $res = sendRequest($ua, $r);

	if ($res ne 0)
	{
        $data = decode_json($res);
		# print Dumper ($data);
        foreach my $imageInfo (@{$data->{'data'}})
        {
            if ($imageInfo->{'ratingsInfo'}->{'average'} > $imageRating)
            {
                $imageRating = $imageInfo->{'ratingsInfo'}->{'average'};
                $imageUrl = $imageInfo->{'fileName'};
                # print Dumper ($imageUrl);
            }
        }
        return "$tvdbImagePath/$imageUrl";
	}
	else {return 0;}
}