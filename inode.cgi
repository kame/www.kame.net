#!/usr/pkg/bin/perl

$url = 'http://inode-srv.kame.net/';
#$fetch = '/usr/bin/fetch -q -o -';	# FreeBSD
$fetch = '/usr/bin/ftp -V -o -';	# NetBSD

print "Content-type: text/html\n\n";

$r = 0;
$t = 0;
open(IN, "$fetch $url |");
while (<IN>) {
	if (/^現在値:/) {
		$r = 1;
		next;
	} elsif (/^更新時刻:/) {
		$t = 1;
		next;
	}

	if ($r && $r++ == 5) {
		s/<[^>]+>//g;
		tr/\r\n//d;
		$temp = $_;
		$r = 0;
	}
	if ($t && $t++ == 5) {
		tr/\r\n//d;
		($date, $time) = split(/\s/, $_);
		$t = 0;
	}
}
close(IN);

if ($temp > 30) {
	$temp = "<FONT COLOR=\"RED\">$temp</FONT>";
} else {
	$temp = "<FONT COLOR=\"GREEN\">$temp</FONT>";
}
print "the server room's temperature is ${temp}C&deg;at ${time} on ${date}GMT.";
print "&nbsp;&nbsp;&nbsp;&nbsp;";
print "Powered by <A HREF=\"http://www.i-node.co.jp/e/index.html\">Internet node</A>.\n";

exit 0;
