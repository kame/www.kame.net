#! /usr/bin/perl

$mlname = 'snap-users';
$url = "ftp://ftp.kame.net/pub/mail-list/$mlname";
$topdir = "/var/spool/mail-list/$mlname";
$dir = '';
$item = '';

if ($ENV{'REQUEST_METHOD'} ne 'GET') {
	exit 1;
}

#print "Content-type: text/plain\n\n";


opendir(DIR, $topdir);
@items = grep(/^\d+$/, readdir(DIR));
closedir(DIR);
$maxnum = (sort {$b <=> $a} @items)[0];

$query = $ENV{'QUERY_STRING'};
if ($query =~ /^(\d+)$/) {
	$start = $end = $1;
} elsif ($query =~ /^(\d+)-(\d+)$/) {
	$start = $1;
	$end = $2;
	if ($end < $start) {
		$t = $start;
		$start = $end;
		$end = $t;
	}
} else {
	$end = $maxnum;
	$start = $end - 99;
	if ($start < 1) {
		$start = 1;
	}
}

for ($i = $start; $i <= $end; $i++) {
	if (-f "$topdir/$i") {
		&grabheader("$topdir/$i", $i);
#		$subject{$i} = "pseudo subject $i";
	}
}

#if ($start == $end) {
#	print <<EOF;
#Content-type: text/plain
#Location: $url/$start
#
#The item moved to <A HREF=$url/$start>$url/$start</A>.
#EOF
#	exit 0;
#}

print "content-type: text/html\n\n";
print "<HEAD><TITLE>$mlname mailing list, $start - $end</TITLE></HEAD>\n";
print "<H1>$mlname mailing list, $start - $end</H1>\n";
$n = $end - $start;
if (0 < $start - 1) {
	$x = $start - $n - 1;
	if ($x < 1) {
		$x = 1;
	}
	$y = $end - $n - 1;
	print "<A HREF=$ENV{'SCRIPT_NAME'}?$x-$y>previous($x-$y)</A>\n";
}
$x = $end + 1;
if (-f "$topdir/$x") {
	$y = $x + $n;
	if ($maxnum < $y) {
		$y = $maxnum;
	}
	print "<A HREF=$ENV{'SCRIPT_NAME'}?$x-$y>next($x-$y)</A>\n";
}
print "<HR>\n";
print "<UL>\n";
for ($i = $start; $i <= $end; $i++) {
	next if (! defined($subject{$i}));
	print "<LI>$i: <A HREF=$url/$i>$subject{$i}</A> ($from{$i})\n"
}
print "</UL>\n";
exit 0;

sub grabheader {
	local($fname) = @_;
	local($header, @headers);

	$/ = "\n\n";
	open(IN, "< $fname") || return;
	$header = <IN>;
	close(IN);

	$header =~ s/\n(\s)/$1/g;
	@headers = split(/\n/, $header);
	$subject{$i} = join(' ', grep(/^subject:/i, @headers));
	$subject{$i} =~ s/^subject:\s+//i;
	$from{$i} = join(' ', grep(/^from:/i, @headers));
	$from{$i} =~ s/^from:\s+//i;
	$from{$i} =~ s/</\&lt;/i;
	$from{$i} =~ s/>/\&gt;/i;
}
