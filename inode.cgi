#!/usr/pkg/bin/perl

$url = 'http://inode-srv.kame.net/';
#$fetch = '/usr/bin/fetch -q -o -';	# FreeBSD
$fetch = '/usr/bin/ftp -V -o -';	# NetBSD

print "Content-type: text/html\n\n";

$r = 0;
$t = 0;
open(IN, "$fetch $url |");
while (<IN>) {
	if (/^åªç›íl:/) {
		$r = 1;
		next;
	} elsif (/^çXêVéûçè:/) {
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
		$date = $_;
		$t = 0;
	}
}
close(IN);

if ($temp > 30) {
	$temp = "<FONT COLOR=\"RED\">$temp</FONT>";
} else {
	$temp = "<FONT COLOR=\"GREEN\">$temp</FONT>";
}
print "the server room's temperature is ${temp}C&deg;on ${date}.  ";
print "Powered by <A HREF=\"http://www.i-node.co.jp/e/index.html/\">Internet node</A>\n";

exit 0;
