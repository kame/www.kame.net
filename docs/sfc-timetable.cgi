#! /usr/bin/perl

print "Content-type: text/plain\n\n";

if (open(IN, "/usr/local/v6/bin/fetch -o - http://www.sfc.keio.ac.jp/SFCInformation/guide/access/timetable_bus.html 2>/dev/null | /usr/local/bin/nkf -e |") < 0) {
	print STDOUT <<EOF;
failed to get the source file,
http://www.sfc.keio.ac.jp/SFCInformation/guide/access/timetable_bus.html.
EOF
	exit 0;
}
select(IN);

$i = 0;

BIG:
while (1) {
	# skip preamble
	while (<IN>) {
		last BIG if (/<\/HTML>/i);
		last if (/<H3>/i);
	}
	$title[$i] = &gettitle($_);

	while (<IN>) {
		last BIG if (/<\/HTML>/i);
		last if (/<\/table>/i);
		next if (!/^<TD/i);
		if (/<TD\s+CLASS="time">(\d+)<\/TD>/i && $t != $1) {
			$t = $1;
			next;
		}
		if (/<TD\s+CLASS="holiday">(.*)<\/TD>/i) {
			$holiday{"${i}H$t"} = $1;
#			print "$i H$t $_";
			next;
		}
		if (/<TD\s+CLASS="weekday">(.*)<\/TD>/i) {
			$weekday{"${i}W$t"} = $1;
#			print "$i W$t $_";
			next;
		}
		if (/<TD\s+CLASS="saturday">(.*)<\/TD>/i) {
			$saturday{"${i}S$t"} = $1;
#			print "$i S$t $_";
			next;
		}
		if (/<TD>(.*)<\/TD>/i) {
			$weekday{"${i}W$t"} = $1;
#			print "$i W$t $_";
			next;
		}
	}

	$i++;
}
close(IN);

select(STDOUT);
foreach $i (keys %weekday) {
	$weekday{$i} = &rewrite($weekday{$i});
#	print ">>$i: $weekday{$i}\n";
}
foreach $i (keys %saturday) {
	$saturday{$i} = &rewrite($saturday{$i});
#	print ">>$i: $saturday{$i}\n";
}
foreach $i (keys %holiday) {
	$holiday{$i} = &rewrite($holiday{$i});
#	print ">>$i: $holiday{$i}\n";
}

for ($i = 0; $i < 4; $i++) {
	foreach $var ('$weekday', '$saturday', '$holiday') {
		print "---\n";
		$sw = substr($var, 1, 1);
		$sw =~ tr/a-z/A-Z/;

		$value = eval "$var\{\"$i$sw\"\}";
		print "$title[$i] ";
		if ($sw eq 'W') {
			print "Ê¿Æü\n";
		} elsif  ($sw eq 'S') {
			print "ÅÚÍË\n";
		} elsif ($sw eq 'H') {
			print "µÙÆü\n";
		} else {
			print "\n";
		}
		for ($t = 7; $t <= 23; $t++) {
			$value = eval "$var\{\"$i$sw$t\"\}";
			printf("%02d ", $t);
			print "$value\n";
		}
		if ($title[$i] =~ /¾ÅÆîÂæ/) {
			print "# ¥µ: ºûµ×ÊÝ·ÐÍ³\n";
		}
		print "\n\n\n";
	}
}

sub gettitle {
	local($line) = @_;
	while ($line !~ /<\/H3>/i) {
		$line .= <IN>;
	}
	$line =~ s/\n//g;
	$line =~ s/<H3>//gi;
	$line =~ s/<\/H3>//gi;
	$line =~ s/<A NAME=[^>]*>//gi;
	$line =~ s/<\/A[^>]*>//gi;
	return $line;
}

sub rewrite {
	local($in) = @_;
	local($out) = ('');
	local($flag) = ('');

	while (length $in) {
		if ($in =~ /^(·îÍË¡Á¶âÍË|ÅÚÍËÆü|µÙÆü)/) {
			$in = $';
			next;
		}
		if ($in =~ /^(\s+|<br>|¡Ê¿¼Ìë¥Ð¥¹¡Ë)/i) {
			$in = $';
			next;
		}
		if ($in =~ /^(\d+)\s*/) {
			$out .= "$1$flag ";
			$in = $';
			next;
		}
		if ($in =~ /^<span[^>]*>/i) {
			$flag = "¥µ";
			$in = $';
			next;
		}
		if ($in =~ /^<\/span[^>]*>/i) {
			$flag = "";
			$in = $';
			next;
		}
		print $in;
		exit 0;
	}

	return $out;
}
