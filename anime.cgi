#! /usr/bin/env perl

if ($ENV{'REMOTE_ADDR'} !~ /2001:200:d00:100::/) {
	$v6p = 'yes';
}

print "Content-type: text/html\n\n";

$| = 1;
if (0) {
	print <<EOF;
<img src="/img/kame-noanime-small.gif" alt="Non-dancing kame" /><br />
sorry www.kame.net is IPv4 only due to trouble, and dancing kame service is suspended...
EOF
} elsif ($v6p) {
	print <<EOF;
<img src="/img/kame-anime-small.gif" alt="Dancing kame" /><br />
Dancing kame by <a href="http://www.momonga.org/">atelier momonga</a>
EOF
} else {
	print <<EOF;
<img src="/img/kame-noanime-small.gif" alt="Non-dancing kame" /><br />
Use IPv6 HTTP and you will watch
<a href="/kame-mosaic.html">the dancing kame</a>
EOF
}
exit 0;
