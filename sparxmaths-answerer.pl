#!/bin/perl
# This script constantly gets questions wrong on sparxmaths.com
# It's meant to take the first question of your target section,
# I'd like to make it more dynamic in the future.

# The purpose of this is to make sparx think you're stupid, meaning
# it lowers the difficulty of the questions you get, saving you 
# brain power.

# You could theoretically modify this to answer questions correctly,
# by extracting the question from the `NEW`/`RESUMABLE` responses,
# calculating the answer (the hard part), then puttimng the answer
# into the `ANSWER` api call by setting the `value` and `hash` values
# (both should be set to the answer)
# You'd also have to add the size of the answer you're adding (* 2)
# to both `chr()` calls.


# I've only been able to test this for my school and my account,
# please open an issue if it doesn't work (it probably won't).
# A packet trace would probably help.

# Put your microsoft email and password here:
my $login = 'forename.surname@domain.org';
my $passwd = 'correct horse battery staple';


use LWP::UserAgent;
use POSIX qw(strftime);

# Print immediately
$| = 1;

sub ActivityAction {
	# Set state to ACTIVE
	new LWP::UserAgent(agent => '')->post(
		'https://swworker.api.sparxmaths.uk/sparx.messaging.worker.v1.Worker/SendLegacyClientRequest', 
		Content => "\x00\x00\x00\x00" .
			# Length of the message
			chr(183 + length(++$j) * 2) .
			"\n\$$sessionID\x12\x17sparxweb.ActivityAction\x1a" .
			chr(107 + length($j) * 2) .
			"{\"activityIndex\":$j,\"timestamp\":\"0001-01-01T01:00:00.000Z\",\"question\":{\"actionType\":\"VIEW\",\"questionIndex\":$j}} \xff\xff\xff\xff\xff\xff\xff\xff\xff\x01",
		'authorization' => $accesstoken,
		'content-type' => 'application/grpc-web'
	);

	# Submit the answer
	new LWP::UserAgent(agent => '')->post(
		'https://swworker.api.sparxmaths.uk/sparx.messaging.worker.v1.Worker/SendLegacyClientRequest',
		Content => "\x00\x00\x00\x00" .
			chr(246 + length($j) * 2) .
			"\n\$$sessionID\x12\x17sparxweb.ActivityAction\x1a" .
			chr(169 + length($j) * 2) .
			"\x01{\"activityIndex\":$j,\"timestamp\":\"0001-01-01T01:00:00.000Z\",\"question\":{\"actionType\":\"ANSWER\",\"answer\":{\"components\":[{\"key\":\"$_[0]\",\"value\":\"\"}],\"hash\":\"\"},\"questionIndex\":$j}} \xff\xff\xff\xff\xff\xff\xff\xff\xff\x01",
		'authorization' => $accesstoken,
		'content-type' => 'application/grpc-web'
	);

	print "\r" . $i++;
}


# Get ctx and flowToken from sparx
my $authorize = new LWP::UserAgent(agent => '')->get(
	'https://auth.sparxmaths.uk/oauth2/login?authurl=?client_id=sparx-maths-sw%26redirect_uri=https://studentapi.api.sparxmaths.uk/oauth/callback%26response_type=code%26scope=openid%26state=1OvtwoqRNtf5DW8HC6u6QFMaHNqnnqB1Pj8T1om8zfNUgiqyILSX4VnlCtmJgj0v4cHHHEJfAMAid3dWOnDbU_rpYlAGlQl0MBLAKyL83dgDSpSTHa90zUonrAvUOzYYbZUFdS-sG5-z8qfDKk75plS0nbZmZ3hYp718OfRUkENIQ1Jh6dBQZGvABAQ3a1IHq644n3Pbi8ECjIwRSxXBIIGgKMeUdaib-LiaWxtD18w3xikFniMeny5JW47r&client_id=sparx-maths-sw&provider_name=azure&school=436bf605-b327-49da-9fe3-8dd6008673a1'
)->content;

# Search for ctx
$authorize =~ m/(?<=ctx=).+?(?=\\)/;
my $ctx = $&;

print "ctx: $ctx\n\n";

# Search for flowToken
$authorize =~ m/(?<=T":").{590}/;

print "flowToken: $&\n\n";

# Sign in with microsoft
my $login = new LWP::UserAgent()->post(
	'https://login.microsoftonline.com/common/login',
	[
		login => $login, 
		passwd => $passwd,
		ctx => $ctx,
		flowToken => $&
	],
	# It needs a referer for some reason, this works though
	'Referer' => 'AA://A'
)->content;

# Search for new ctx
$login =~ m/(?<=x":").+?(?=")/;
$ctx = $&;

print "new ctx: $ctx\n\n";

# Search for new flowToken
$login =~ m/(?<=T":").+?(?=")/;

print "new flowToken: $&\n\n";

# Get cookies from microsoft (redirects to sparx)
my @redirects = new LWP::UserAgent(
	agent => '',
	# Needs to be able to redirect from a POST
	requests_redirectable => ['GET', 'POST']
)->post(
	'https://login.microsoftonline.com/kmsi',
	[
		ctx => $ctx,
		flowToken => $&
	]
)->redirects;
# Array of cookies
my @Set_Cookie = $redirects[2]->header('Set-Cookie');

print "Cookies:\n" . join("\n", @Set_Cookie) . "\n\n";

# Get accesstoken from sparx
$accesstoken = new LWP::UserAgent(agent => '')->get(
	'https://studentapi.api.sparxmaths.uk/accesstoken',
	'Cookie' => substr($Set_Cookie[1], 0, 552)
)->content;

print "accesstoken: $accesstoken\n\n";

for ($i = 1;;) {
	# Get sessionID from sparx
	$sessionID = substr(
		new LWP::UserAgent(agent => '')->get(
			'https://studentapi.api.sparxmaths.uk/clientsession',
			'X-CSRF-Token' => substr($Set_Cookie[0], 14, 36),
			'Cookie' => substr($Set_Cookie[0], 0, 51) . substr($Set_Cookie[1], 0, 552)
		)->content,
		15,
		36
	);

	print "sessionID: $sessionID\n\n\nQuestions answered:\n";


	# Answer 98 questions, then we need to create a new session
	for ($j = 0; $j < 98;) {
		# Get the task ref and set state to READY
		my $NEW = new LWP::UserAgent(agent => '')->post(
			'https://swworker.api.sparxmaths.uk/sparx.messaging.worker.v1.Worker/SendLegacyClientRequest',
			Content => "\x00\x00\x00\x00\xe8\n\$$sessionID\x12\x1bsparxweb.GetActivityRequest\x1a\x97\x01{\"taskItem\":{\"packageID\":\"62a6f317-a739-4971-a5b1-156d206d7b72\",\"taskIndex\":1,\"taskItemIndex\":1},\"method\":\"NEW\",\"timestamp\":\"0000-01-01T00:00:00.000Z\"} \xff\xff\xff\xff\xff\xff\xff\xff\xff\x01",
			'authorization' => $accesstoken,
			'content-type' => 'application/grpc-web'
		)->content;

		# Search for the ref
		$NEW =~ m/(?<= \\")..(?=\\)/;

		ActivityAction($&);


		# Set state to READY
		new LWP::UserAgent(agent => '')->post(
			'https://swworker.api.sparxmaths.uk/sparx.messaging.worker.v1.Worker/SendLegacyClientRequest',
			Content => "\x00\x00\x00\x00\xe3\n\$$sessionID\x12\x1bsparxweb.GetActivityRequest\x1a\x9d\x01{\"taskItem\":{\"packageID\":\"62a6f317-a739-4971-a5b1-156d206d7b72\",\"taskIndex\":1,\"taskItemIndex\":1},\"method\":\"RESUMABLE\",\"timestamp\":\"0000-01-01T00:00:00.000Z\"}",
			'authorization' => $accesstoken,
			'content-type' => 'application/grpc-web'
		);

		ActivityAction($&);
	}

	print "\n\nCreating a new session\n\nnew ";
}
