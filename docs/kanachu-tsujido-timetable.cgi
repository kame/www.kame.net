#! /usr/bin/perl
#
# $Id: kanachu-tsujido-timetable.cgi,v 1.1 2001/04/17 03:41:51 itojun Exp $
#

chdir('/usr/local/www/www.kame.net/docs');
$nkf = '/usr/local/bin/nkf';

print "Content-type: text/html; charset=x-euc-jp\n\n";
print "<HTML><BODY><PRE>\n";

$targetstation = '';
if ($ENV{'QUERY_STRING'}) {
	@stations = ($ENV{'QUERY_STRING'});
} else {
	@stations = ('tsujido', 'karigome');
}

@lines = ('tsuji34', 'tsuji33');
%linecolors = ('tsuji34', '000000', 'tsuji33', 'ff0000');
@modes = ('Weekday', 'Saturday', 'Sunday');

%jname = ('tsujido', '辻堂', 'karigome', '刈込',
	'Weekday', '平日', 'Saturday', '土曜', 'Sunday', '日曜'
);

if (1 < scalar(@stations)) {
	foreach $i (@stations) {
		print <<EOF;
<A HREF=http://$ENV{'HTTP_HOST'}$ENV{'SCRIPT_NAME'}?$i>$jname{$i}だけ表示</A>
EOF
	}
	print "<HR>\n";
}

foreach $i (@stations) {
	foreach $j (@lines) {
		&readit($j, $i, "bus/$j-$i.txt") if (-f "bus/$j-$i.txt");
	}
}
foreach $j (@lines) {
	if (-f "bus/$j-comment.txt") {
		open(IN, "$nkf -e bus/$j-comment.txt |") || die;
		while (<IN>) {
			$comment2 .= $_;
		}
		close(IN);
	}
}
##$comment2 .= <<EOF;
##<FONT COLOR=#FF0000>夏休みダイヤに注意!</FONT>
##夏休み期間中(9/10まではバスの本数が大幅に少なくなってます。特に午後。
##EOF

foreach $i (sort @stations) {
	print $comment{$i};
	if (defined $comment2) {
		print "\n" . $comment2 . "\n";
	}
	foreach $j (@modes) {
		print "$jname{$i} $jname{$j}:\n";
		for ($h = 5; $h < 24; $h++) {
			$k = sprintf("%s\n%s\n%02d", $i, $j, $h);
			if (defined $table{$k}) {
				($station, $mode, $hour) = split(/\n/, $k);
				next if ($station ne $i);
				next if ($mode ne $j);
				@min = split(/\n/, $table{$k});
				foreach $l (@min) {
					$rawmin{$l} = $l;
					$rawmin{$l} =~ s/<[^>]*>//g;
				}
				@min = sort {$rawmin{$a} <=> $rawmin{$b}} @min;
				print "\t" . sprintf("%02d", $hour) . "\t";
				print join(' ', @min) . "\n";
			} else {
				print "\t" . sprintf("%02d", $h) . "\n";
			}
		}
	}
	print "\n\n";
}

print "</PRE></BODY></HTML>\n";
exit 0;

sub readit {
	local($line, $station, $fname) = @_;
	local($mode);
	local($hour, @min);
	local($i);

	open(IN, "$nkf -e $fname|") || die;
	$comment{$station} .= "<FONT COLOR=\"#$linecolors{$line}\">";
	while (<IN>) {
		$_ =~ s/\n$//;
		last if ($_ eq '');
		$comment{"$station"} .= $_ . "\n";
	}
	$comment{$station} .= "</FONT>";
	while (<IN>) {
		$_ =~ s/\n$//;
		$_ =~ s/^\s+//;
		$_ =~ s/\s+$//;
		next if ($_ eq '');
		if ($_ =~ /^(Weekday|Saturday|Sunday)$/) {
			$mode = $_;
			next;
		}
		($hour, @min) = split(/\s+/, $_);
		next if (scalar(@min) == 0);
		foreach $i (@min) {
			$table{sprintf("%s\n%s\n%02d", $station, $mode, $hour)}
				.= sprintf("<FONT COLOR=\"#%s\">%02d</FONT>\n",
					$linecolors{$line}, $i);
		}
	}
	close(IN);
}
