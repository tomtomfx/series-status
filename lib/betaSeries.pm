
package betaSeries;	
use LWP::UserAgent;
use LWP::Simple;
use XML::Simple;
use Time::localtime;
use Data::Dumper;
use strict;

require Exporter;
my @ISA = qw/Exporter/;
my @EXPORT = qw/getEpisodeToDownload authentification setDownloaded getEpisodesToSee setEpisodeSeen searchSerie addShow getSubtitles/;

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

sub getEpisodeToDownload
{
	my ($verbose, $token, $betaSeriesKey) = @_;
	my @episodeToDownload;
	my $ua = LWP::UserAgent->new;

	# Get list of unseen episodes
	my $unseen = "http://api.betaseries.com/episodes/list?token=$token";
	my $req = HTTP::Request->new(GET => "$unseen");
	$req->header('X-BetaSeries-Version' => '2.2');
	$req->header('Accept' => 'text/xml');
	$req->header('X-BetaSeries-Key' => $betaSeriesKey);

	my $message = sendRequest($ua, $req);
	
	my $parser = XML::Simple->new( KeepRoot => 0 );
	my $episodes = $parser->XMLin($message);
	if (keys(%{$episodes->{shows}}) == 0){return @episodeToDownload;}
	my %shows = %{$episodes->{shows}->{show}};
	if (exists $shows{"thetvdb_id"})
	{
		%shows = %{$episodes->{shows}};
	}
	# Get episodes than require a download
	foreach my $show (keys (%shows))
	{	
		my $serie = $shows{$show}->{title};
		my %keys = %{$shows{$show}->{unseen}->{episode}};
		my $numberOfEps = 1;
		if (!exists $keys{"thetvdb_id"})
		{
			my @epNumbers = keys(%keys);
			$numberOfEps = scalar @epNumbers;
		}
		my $epNumber = "";
		my $title = "";
		my $id = "";
		my %eps;
		if ($numberOfEps == 1){%eps = %{$shows{$show}->{unseen}};}
		else {%eps = %{$shows{$show}->{unseen}->{episode}};}
		foreach my $ep (keys (%eps))
		{
			if (ref $eps{$ep} eq ref {})
			{
				$epNumber = $eps{$ep}->{code};
				$title = $eps{$ep}->{title};
				$id = $eps{$ep}->{thetvdb_id};
				#if ($verbose >= 1) {print ("$serie - $epNumber - $id\n");}
				if ($eps{$ep}->{user}->{downloaded} != 1)
				{
					if ($verbose >= 1) {print ("$serie - $epNumber - $title - $id\n");}
					push(@episodeToDownload, "$serie - $epNumber - $title - $id");
				}
			}
		}
	}
	return @episodeToDownload;
}

# Authentification
sub authentification
{
	my ($verbose, $betaSeriesKey, $betaSeriesLogin, $betaSeriesPassword) = @_;
	my $ua = LWP::UserAgent->new;
	my $server = "http://api.betaseries.com";
	my $token = "";
	my $auth = "$server/members/auth?login=$betaSeriesLogin&password=$betaSeriesPassword";
	
	my $req = HTTP::Request->new(POST => $auth);
	$req->header('X-BetaSeries-Version' => '2.2');
	$req->header('Accept' => 'application/json');
	$req->header('X-BetaSeries-Key' => $betaSeriesKey);

	my $message = sendRequest($ua, $req);
	if ($message ne 0)
	{	
		if ($message =~ /token\": \"(.*)\"/){$token = $1;}
		if ($verbose >= 1) {print "Token: $token\n";}
		return $token
	}
	else {return 0;}
}

sub setDownloaded
{
	my ($verbose, $token, $betaSeriesKey, $id) = @_;
	
	my $ua = LWP::UserAgent->new;

	# Set episode as downloaded
	my $downloaded = "http://api.betaseries.com/episodes/downloaded?token=$token&thetvdb_id=$id";
	my $req = HTTP::Request->new(POST => "$downloaded");
	$req->header('X-BetaSeries-Version' => '2.2');
	$req->header('Accept' => 'text/xml');
	$req->header('X-BetaSeries-Key' => $betaSeriesKey);

	my $message = sendRequest($ua, $req);
	#print Dumper $message;
}

sub getEpisodesToSee
{
	my ($verbose, $token, $betaSeriesKey) = @_;
	my @episodeToSee;
	my $ua = LWP::UserAgent->new;

	# Get list of unseen episodes
	my $unseen = "http://api.betaseries.com/episodes/list?token=$token";
	my $req = HTTP::Request->new(GET => "$unseen");
	$req->header('X-BetaSeries-Version' => '2.2');
	$req->header('Accept' => 'text/xml');
	$req->header('X-BetaSeries-Key' => $betaSeriesKey);

	my $message = sendRequest($ua, $req);
	if ($message eq "0") {return 0;}
	# open my $DUMP, '>', "log.txt";
	
	my $parser = XML::Simple->new( KeepRoot => 0 );
	my $episodes = $parser->XMLin($message);
	if (keys(%{$episodes->{shows}}) == 0){return @episodeToSee;}
	my %shows = %{$episodes->{shows}->{show}};
	if (exists $shows{"thetvdb_id"})
	{
		%shows = %{$episodes->{shows}};
	}
	# print $DUMP Dumper %shows;
	# Get episodes than require a download
	foreach my $show (keys (%shows))
	{	
		my $serie = $shows{$show}->{title};
		my %keys = %{$shows{$show}->{unseen}->{episode}};
		my $numberOfEps = 1;
		if (!exists $keys{"thetvdb_id"})
		{
			my @epNumbers = keys(%keys);
			$numberOfEps = scalar @epNumbers;
		}
		my $epNumber = "";
		my $title = "";
		my $id = "";
		my %eps;
		if ($numberOfEps == 1){%eps = %{$shows{$show}->{unseen}};}
		else {%eps = %{$shows{$show}->{unseen}->{episode}};}
		foreach my $ep (keys (%eps))
		{
			if (ref $eps{$ep} eq ref {})
			{
				$epNumber = $eps{$ep}->{code};
				$title = $eps{$ep}->{title};
				$id = $eps{$ep}->{thetvdb_id};
				if ($verbose >= 1) {print ("$serie - $epNumber - $title - $id\n");}
				push(@episodeToSee, "$serie - $epNumber - $title - $id");
			}
		}
	}
	# close $DUMP;
	return @episodeToSee;
}

sub setEpisodeSeen
{
	my ($verbose, $token, $betaSeriesKey, $epId) = @_;
	my $ua = LWP::UserAgent->new;

	# Set episode as seen
	my $seen = "http://api.betaseries.com/episodes/watched?token=$token&thetvdb_id=$epId";
	my $req = HTTP::Request->new(POST => "$seen");
	$req->header('X-BetaSeries-Version' => '2.2');
	$req->header('Accept' => 'text/xml');
	$req->header('X-BetaSeries-Key' => $betaSeriesKey);

	my $message = sendRequest($ua, $req);
	#print Dumper $message;
}

sub searchSerie
{
	my ($verbose, $token, $betaSeriesKey, $title) = @_;
	my $ua = LWP::UserAgent->new;
	# search for a specific serie
	my $shows = "http://api.betaseries.com/shows/search?title=$title&summary=true&token=$token";
	my $req = HTTP::Request->new(GET => "$shows");
	$req->header('X-BetaSeries-Version' => '2.2');
	$req->header('Accept' => 'text/xml');
	$req->header('X-BetaSeries-Key' => $betaSeriesKey);

	my $message = sendRequest($ua, $req);
	# print Dumper $message;
	
	my $parser = XML::Simple->new( KeepRoot => 0 );
	my $result = $parser->XMLin($message);
	# print Dumper ($result);
	my %shows = %{$result->{shows}->{show}};
	if ($verbose >= 1) {print Dumper %shows;}
	my $serieId = 0;
	my $titleLength = 100;
	if (exists $shows{"thetvdb_id"}){
		$serieId = $shows{"id"};
	}
	else
	{
		foreach my $show (keys (%shows))
		{	
			my $serieTitle = $shows{$show}->{title};
			$serieTitle =~ s/\'s//;
			# print "$serieTitle - $title\n";
			if ($serieTitle eq $title){$serieId = $show;last;}
			if ($serieTitle =~ /$title/i)
			{
				if (length($serieTitle) - length($title) < $titleLength)
				{
					$titleLength = length($serieTitle) - length($title);
					$serieId = $show;
				}
			}
			else {next;}
		}
	}	
	return $serieId;
}

sub addShow
{
	my ($verbose, $token, $betaSeriesKey, $showId) = @_;
	my $ua = LWP::UserAgent->new;

	# Set episode as seen
	my $show = "http://api.betaseries.com/shows/show?token=$token&id=$showId";
	my $req = HTTP::Request->new(POST => "$show");
	$req->header('X-BetaSeries-Version' => '2.2');
	$req->header('Accept' => 'text/xml');
	$req->header('X-BetaSeries-Key' => $betaSeriesKey);

	my $message = sendRequest($ua, $req);
	# print Dumper $message;
}

sub getSubtitles
{
	my ($verbose, $token, $betaSeriesKey, $epId, $filename, $downloadDir) = @_;
	
	my $subFound = 0;
	
	# Get the right ID for this 
	my $ua = LWP::UserAgent->new;
	my $request = "http://api.betaseries.com/episodes/display?thetvdb_id=$epId&token=$token";
	my $req = HTTP::Request->new(GET => "$request");
	$req->header('X-BetaSeries-Version' => '2.2');
	$req->header('Accept' => 'text/xml');
	$req->header('X-BetaSeries-Key' => $betaSeriesKey);

	my $message = sendRequest($ua, $req);
	my $parser = XML::Simple->new( KeepRoot => 0 );
	my $episode = $parser->XMLin($message);
	my $id = $episode->{'episode'}{'id'};
	
	# Get available subtitles
	$request = "http://api.betaseries.com/subtitles/episode?id=$id&token=$token&language=vo";
	my $req = HTTP::Request->new(GET => "$request");
	$req->header('X-BetaSeries-Version' => '2.2');
	$req->header('Accept' => 'text/xml');
	$req->header('X-BetaSeries-Key' => $betaSeriesKey);

	my $message = sendRequest($ua, $req);
	my $parser = XML::Simple->new( KeepRoot => 0 );
	my $subtitles = $parser->XMLin($message);
	
	my %subs = ();
	if (defined ($subtitles->{'subtitles'}->{'subtitle'}))
	{
		%subs = %{$subtitles->{'subtitles'}->{'subtitle'}};
	}
	foreach my $sub (keys (%subs))
	{
		if ($subs{$sub}->{'source'} ne "addic7ed"){next;}
		my $subFile = $subs{$sub}->{'file'};
		if ($subFile =~ /.*\.(.*)\.English.*/)
		{
			my @versions = split('-', $1);
			foreach (@versions)
			{
				if ($filename =~ /$_/i) 
				{
					# Get redirection
					my $response = $ua->get("$subs{$sub}->{'url'}");
					# open log file
					open my $SUB, '>', "$downloadDir\/$subs{$sub}->{'file'}";
					print $SUB ($response->decoded_content);
					close $SUB;
					$subFound = 1;
					last;
				}
			}
		}
		if ($subFound == 1){last;}
	}
	return "";
}

1;