#! /usr/bin/perl

$id = '$Id: 6bone-connect.cgi,v 1.1 2001/04/17 03:42:19 itojun Exp $';

@lines = split(/\n/, <<EOF);
IIJ	Japan	mail	6bone-connect\@iijlab.net	http://playground.iijlab.net/6bone/6bone-policy.html	
WIDE	Japan	mail	registry\@v6.sfc.wide.ad.jp	http://www.v6.sfc.wide.ad.jp/
NTT	Japan	mail	query\@nttv6.net	http://www.nttv6.net/
IMASY	Japan	mail	ichiro\@ichiro.org	http://www.v6.imasy.or.jp/6bone.html
G6	France	mail	Alain.Durand\@imag.fr	http://phoebe.urec.fr/G6/
NRL	US-eastcoast	mail	cmetz\@inner.net	mailto:cmetz\@inner.net	
EOF

foreach $i (@lines) {
	@t = split(/\t/, $i);
	$countries{$t[1]}++;
	$country{$t[0]} = $t[1];
	$method{$t[0]} = $t[2];
	$contact{$t[0]} = $t[3];
	$policy{$t[0]} = $t[4];
}

$query = '';
if ($ENV{'REQUEST_METHOD'} eq 'GET') {
	$query = $ENV{'QUERY_STRING'};
}

$query0 = $query;
while ($query ne '') {
	if ($query =~ /^([a-z0-9]+)=([^\&]*)/) {
		eval '$var_' . $1 . '=\'' . $2 . '\'';
		$query = $';
	} else {
		&header;
		print "malformed options. /$query/\n";
		&trailer;
		exit 0;
	}
	$query = substr($query, 1) if (length($query));
}
$query = $query0;

$descr{'KAME'} = <<EOF;
Let us assume the following:
<UL>
<LI>IPv4 address of 6bone connection provider is <TT>aa.bb.cc.dd</TT> (*)
<LI>IPv6 subnet assigned to your site is <TT>3ffe:gggg:gggg::/48</TT> (*)
<LI>Ethernet interface on your router is <TT>eth0</TT>
</UL>
Items marked with (*) will be included in the reply from 6bone connection
provider.
<P>

You will need to configure your IPv6-over-IPv4 tunnel by the following
commands (put them into <TT>rc.net6</TT>):
<PRE>
# /usr/local/v6/sbin/gifconfig gif0 $var_userv4 aa.bb.cc.dd
# /usr/local/v6/sbin/prefix eth0 3ffe:gggg:gggg:: prefixlen 64
# /usr/local/v6/sbin/route6d -A 3ffe:gggg:gggg::/48,gif0 -O 3ffe:gggg:gggg::/48,gif0
</PRE>
Also, it is good to advertise information about IPv6 address prefix to
your network, by using <TT>rtadvd</TT>.
EOF

# error trap for 0 < step
if (0 < $var_step && !defined $countries{$var_country}) {
	&header;
	print <<EOF;
We have no 6bone connection provider listed for the region you have specified
(that is, "$var_country").
You may want to contact the following points for 6bone connection:
<UL>
<LI>Japan: 6bone-jp (6bone-jp\@v6.sfc.wide.ad.jp)
<LI>France: G6 ($contact{'G6'})
<LI>last resort: world 6bone (6bone\@isi.edu)
</UL>
EOF
	&trailer;
	exit 0;
}

# error traps for 2 <= step
if (2 <= $var_step) {
	$errmsg = '';
	if ($var_sitename eq '') {
		$errmsg = "no site name provided.";
		$var_step = 1;
	} elsif ($var_mailaddr eq '') {
		$errmsg = "no email address provided.";
		$var_step = 1;
	} elsif ($var_mailaddr !~ /^\w+\@[\w\.]+$/) {
		$errmsg = "malformed email address.";
		$var_step = 1;
	} elsif ($var_userv4 eq '') {
		$errmsg = "no ipv4 address provided provided.";
		$var_step = 1;
	} elsif ($var_userv4 !~ /^\d+\.\d+\.\d+\.\d+$/) {
		$errmsg = "malformed ipv4 address.";
		$var_step = 1;
	} elsif ($var_provider eq '') {
		$errmsg = "provider must be selected.";
		$var_step = 1;
	}
}

# step 0
if ($var_step == 0) {
	&header;
	print <<EOF;
This webpage helps you connect your site to
<A HREF=http://www.6bone.net/>6bone</A>, worldwide experimental IPv6 network.
<STRONG>Please understand that 6bone is an experimental effort.</STRONG>
6bone may not give you what you want, but should be really fun and encouraging
if you are "geek"!

<HR>

You will be connected to 6bone by using IPv6-over-IPv4 tunnel.
<P>

You will need the following items:
<UL>
<LI>IPv4 permanent connection to your site<BR>
	Note that your IPv4 address must be <STRONG>FIXED</STRONG>, i.e.
	your address must not change day-to-day.
	Some of cablemodem-based connection may not qualify.
<LI>IPv4/v6 dual stack router capable of doing IPv6-over-IPv4 tunnel<BR>
	The following would be just fine:
	<UL>
	<LI>PC UNIX box with <A HREF="http://www.kame.net/">KAME</A>,
		<A HREF="http://www.inria.fr/">INRIA</A>,
		<A HREF="http://www.inner.net/">NRL</A>, or
		<A HREF="http://www.bsdi.com/">BSDI BSD/OS 4.0</A>
	<LI>CISCO router with IPv6 EAK (Early Adaptation Kit)
	</UL>
</UL>

IPv6 traffic will be transmitted to your router by encapsulated
into IPv4 packet, and your router must decapsulate that and transmit to
your network.
<PRE>
   | <I>IPv6 traffic to your site,</I>
   | <I>encapsulated into IPv4 packet</I>
   v
dual stack router	<I>must decapsulate and send</I>
   |			<I>IPv6 packet to your network</I>
===+================= your network
   |
IPv6 endhost
</PRE>

In IPv4 point of view, "dual stack router"
can be either the router for your site, or just a host.
<PRE>
  | <I>v4 connection</I>	  | <I>v4 connection</I>
dual stack router	v4 router
  |			  |
==+============		==+=======================+====
  |			  |			  |
endhost			dual stack router	endhost
</PRE>

<HR>
<FORM ACTION="$ENV{'REQUEST_URI'}" METHOD="GET">
<INPUT TYPE="hidden" NAME="step" VALUE="1">
<STRONG>Which region are you in?</STRONG>
<SELECT NAME="country">
EOF
	foreach $i (keys %countries) {
		print "<OPTION>$i</OPTION>\n";
	}
	print "<OPTION>others</OPTION>\n";

	print <<EOF;
</SELECT>
<P>

<STRONG>Which IPv6 stack are you willing to use as your router?</STRONG>
<SELECT NAME="stack">
<OPTION>KAME</OPTION>
<OPTION>INRIA</OPTION>
<OPTION>NRL</OPTION>
<OPTION VALUE="NRL">BSDI BSD/OS 4.0</OPTION>
<OPTION>CISCO</OPTION>
</SELECT>
<P>
<INPUT TYPE="submit" VALUE="submit">
<INPUT TYPE="reset" VALUE="reset">
</FORM>
EOF
	exit 0;
	&trailer;
}

# step 1
if ($var_step == 1) {
	&header;
	if ($errmsg) {
		print <<EOF;
<STRONG>ERROR: $errmsg</STRONG>
<HR>
EOF
	}
	if ($var_userv4 eq '') {
		$var_userv4 = $ENV{'REMOTE_ADDR'};
	}

	print <<EOF;
<FORM ACTION="$ENV{'REQUEST_URI'}" METHOD="GET">
<INPUT TYPE="hidden" NAME="step" VALUE="2">
<INPUT TYPE="hidden" NAME="stack" VALUE="$var_stack">
<INPUT TYPE="hidden" NAME="country" VALUE="$var_country">
<STRONG>Name of your site:</STRONG>
<INPUT TYPE="text" NAME="sitename" VALUE="$var_sitename">
<P>

<STRONG>Your email address:</STRONG>
<INPUT TYPE="text" NAME="mailaddr" VALUE="$var_mailaddr">

<HR>

<STRONG>IPv4 address for your 6bone router?</STRONG>
Note that this has to be permanent IPv4 address assigned by provider.
You cannot use dialup link, or some of cablemodem link,
to connect to 6bone at this moment.
<INPUT TYPE="text" NAME="userv4" VALUE="$var_userv4">
<P>

<STRONG>How many IPv6 subnets do you plan to connect to your 6bone router?</STRONG>
<SELECT NAME="subnetbits">
<OPTION VALUE="0">1</OPTION>
<OPTION VALUE="1">1 or 2</OPTION>
<OPTION VALUE="2">no more than 4</OPTION>
<OPTION VALUE="3">no more than 8 (3bits)</OPTION>
<OPTION VALUE="4">no more than 16 (4bits)</OPTION>
<OPTION VALUE="8">no more than 256 (8bits)</OPTION>
<OPTION VALUE="16" SELECTED>no more than 65536 (16bits)</OPTION>
</SELECT>

<HR>

<STRONG>Which 6bone connection provider do you want to contact?</STRONG>
Note: It is always better to select nearest (by IPv4 topology)
provider to your site.
<DL>
EOF
	foreach $i (keys %policy) {
		next if ($country{$i} ne $var_country);
		print <<EOF;
<DT><INPUT TYPE="radio" NAME="provider" value="$i">$i
<DD>	contact: <A HREF="mailto:$contact{$i}">$contact{$i}</A>
<DD>	policy: <A HREF="$policy{$i}" TARGET="_blank">$policy{$i}</A>
EOF
	}
	print <<EOF;
</DL>
<INPUT TYPE="submit" VALUE="submit">
<INPUT TYPE="reset" VALUE="reset">
<BR>
(feel free to tap Submit button for testing, it will send emails to nobody!)
</FORM>
EOF
	&trailer;
	exit 0;
}

if ($var_step == 2) {
	&header;
	print <<EOF;

Send the following part by email to $var_provider
(<A HREF="mailto:$contact{$var_provider}">$contact{$var_provider}</A>),
and wait till IPv6 address for your site is allocated.
<STRONG>Note: email is not automatically sent to protect everybody
from malicious emails.</STRONG>
<HR>
<PRE>
To: $contact{$var_provider}
From: $var_mailaddr
Subject: 6bone connection request for $var_sitename

Please allocate our site, $var_sitename, IPv6 address prefix for 6bone
and connect to your site by IPv6-over-IPv4 tunnel, to $var_userv4.
We understand experimental nature of 6bone and your connection policy.
We will be using no more than 2^$var_subnetbits IPv6 subnets.
Contact person will be $var_mailaddr.

In summary:
- name of site: $var_sitename
- max # of v6 subnets: 2^$var_subnetbits
- tunnel endpoint: $var_userv4
- contact person: $var_mailaddr
- v6 router implementation: $var_stack

Thanks,

$var_mailaddr, from $var_sitename
</PRE>
<HR>
When the reply comes back, configure your dual stack router
(which is $var_stack).<P>
EOF

	if ($descr{$var_stack}) {
		print $descr{$var_stack};
	} else {
		print "sorry no description, please do it by your own\n";
	}

print <<EOF;
<P>
If you are willing to setup multiple IPv6 subnet into your site,
configuration will be more complex.
We leave it for your exercise.

<HR>
Now you are all set!
Hope you enjoy 6bone activities.
EOF
	&trailer;
	exit 0;
}

&header;
print "unexpected step $var_step.\n";
&trailer;
exit 0;

sub header {
	print <<EOF;
Content-type: text/html

<HTML>
<BODY>
6bone connection request
<PRE>$id</PRE>
<HR>
EOF
}

sub trailer {
	print <<EOF;
</BODY>
</HTML>
EOF
}
