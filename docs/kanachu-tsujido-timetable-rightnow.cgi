#! /usr/bin/perl
#
# $Id: kanachu-tsujido-timetable-rightnow.cgi,v 1.1 2001/04/17 03:41:51 itojun Exp $
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
#%linecolors = ('tsuji34', '000000', 'tsuji33', 'ff0000');
%linecolors = ('tsuji34', '', 'tsuji33', '��');
@modes = ('Weekday', 'Saturday', 'Sunday');

%jname = ('tsujido', '��Ʋ', 'karigome', '����',
	'Weekday', 'ʿ��', 'Saturday', '����', 'Sunday', '����'
);

print <<EOF;
<UL>
<LI>sjis����¸���ơ�
<LI>��Ƭ��<TT>---</TT>�Τ���Ȥ���Ƕ��ڤäơ�
<LI>memo pad�Υ��ƥ���Timetable��<TT>install-memo</TT>��ž�����롣
�������ᥳ�ޥ�ɥ饤�󥪥ץ�����:
% install-memo -c Timetable /dev/pilot hoge fuga monya
<LI><A HREF=http://direct.sgs.co.jp/visavis/software/timetable.html>RightNow!</A>�Ǥ����Ȥ��ޤ���
</UL>
<HR>
EOF
if (1 < scalar(@stations)) {
	foreach $i (@stations) {
		print <<EOF;
<A HREF=http://$ENV{'HTTP_HOST'}$ENV{'SCRIPT_NAME'}?$i>$jname{$i}����ɽ��</A>
EOF
	}
	print "<HR>\n";
}

foreach $i (@stations) {
	foreach $j (@lines) {
		next if ($i eq 'tsujido' && $j eq 'tsuji33');
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
##<FONT COLOR=#FF0000>�Ƶ٤ߥ���������!</FONT>
##�Ƶ٤ߴ�����(9/10�ޤǤϥХ����ܿ��������˾��ʤ��ʤäƤޤ����ä˸�塣
##EOF

foreach $i (sort @stations) {
	print $comment{$i};
}
print "<HR>\n";
foreach $i (sort @stations) {
#	print $comment{$i};
#	if (defined $comment2) {
#		print "\n" . $comment2 . "\n";
#	}
	foreach $j (@modes) {
		print "$jname{$i} $jname{$j}\n";
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
				print sprintf("%02d", $hour) . " ";
				print join(' ', @min) . "\n";
			} else {
				print sprintf("%02d", $h) . "\n";
			}
		}
		$t = '';
		foreach $h (@lines) {
			next if ($i eq 'tsujido' && $h eq 'tsuji33');
			if ($linecolors{$h}) {
				$t .= "$linecolors{$h}: $linename{$h}  ";
			}
		}
		if ($t) {
			print "# $t\n";
		}
		print "\n\n----\n";
	}
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
		if (!$linename{$line}) {
			$linename{$line} = $_;
			$linename{$line} =~ s/^[^ ]* //;
		}
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
				.= sprintf("%02d%s\n",
					$i, $linecolors{$line});
		}
	}
	close(IN);
}
