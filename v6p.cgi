#! /usr/bin/perl

if ($ENV{'REMOTE_ADDR'} =~ /:/) {
	$v6p = 'yes';
}

if ($ENV{'REMOTE_HOST'} ne '') {
	$hostname = "$ENV{'REMOTE_HOST'} = $ENV{'REMOTE_ADDR'}";
} else {
	$hostname = $ENV{'REMOTE_ADDR'};
}

print "Content-type: text/plain\n\n";
if ($v6p) {
	print "you are using IPv6, from $hostname\n";
} else {
	print "you are using IPv4\n";
}
