#! /usr/pkg/bin/perl

if ($ENV{'REMOTE_ADDR'} =~ /:/) {
	$v6p = 'yes';
}

print "Content-type: text/html\n\n";

$| = 1;
if (0) {
	print <<EOF;
<IMG SRC=/img/kame-anime-small.gif><BR>
<FONT COLOR=#ff0000>
sorry www.kame.net is IPv4 only due to trouble, and dancing kame service is suspended...
EOF
} elsif ($v6p) {
	print <<EOF;
<IMG SRC=/img/kame-anime-small.gif><BR>
<FONT COLOR=#ff0000>
dancing kame by <A HREF="http://www.momonga.org/">atelier momonga</A></FONT>
EOF
} else {
	print <<EOF;
<IMG SRC=/img/kame-noanime-small.gif><BR>
<FONT COLOR=#ff0000>If you migrate to IPv6 HTTP,
you'll be able to view 
<A HREF=/kame-mosaic.html>the dancing kame</A>
</FONT>
EOF
}
exit 0;
