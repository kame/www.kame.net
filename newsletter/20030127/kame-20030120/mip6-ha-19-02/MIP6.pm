#!/usr/bin/perl
#
# $Copyright$
#
# $TAHI: ct/mip6-ha-19/MIP6.pm,v 1.19 2003/01/14 09:47:44 akisada Exp $
#
################################################################

my $vrecv_wait = 1;
my $vrecv_loop = 3;

package MIP6;

use Exporter;
@ISA = qw(Exporter);

@EXPORT = qw(
	%pktdesc
	%nd
	MIP6_CheckReachability
	MIP6_Registration
	MIP6_RegistrationNotHomeSubnet
	MIP6_InvalidDeRegistration
	MIP6_DeRegistration
	MIP6_DeRegistrationHome
	MIP6_CheckBindingCache
	MIP6_CheckNoBindingCacheNotHomeSubnet
	MIP6_CheckNoBindingCacheHomeSubnet
	MIP6_DAD
	MIP6_DAD_Failed
	MIP6_GetSiteLocalAddr
	MIP6_ReverseTunneling
	MIP6_MulticastNA
	MIP6_Initialize
	MIP6_DHAAD
	MIP6_SendRA_HA1
	MIP6_SendRA_HA1_HA2
	MIP6_ProxyND
	MIP6_SendRecv
);

use V6evalTool;

################################################################
%pktdesc = (
	'ereq_from_tn_to_nut_global'			=> '    Send Echo Request: TN (LinkX) -&gt; NUT (Link0) (global)',
	'erep_from_nut_to_tn_global'			=> '    Recv Echo Reply: NUT (Link0) -&gt; TN (LinkX) (global)',
	'ereq_from_tn_to_hoa_global'			=> '    Send Echo Request: TN (LinkX) -&gt; MN (Link0) (global)',
	'ereq_from_tn_to_hoa_global_encapsulated'	=> '    Recv Echo Request (encapsulated): TN (LinkX) -&gt; MN (Link0) (global)',
	'ereq_from_mn_to_tn_global_encapsulated'	=> '    Send Echo Request (encapsulated): MN (Link0) -&gt; TN (LinkX) (global)',
	'ereq_from_mn_to_tn_global'			=> '    Recv Echo Request: MN (Link0) -&gt; TN (LinkX) (global)',
	'ereq_from_tn_to_hoa_y_global'			=> '    Send Echo Request (forwarded): TN (LinkX) -&gt; MN (LinkY) (global)',
	'ereq_from_tn_to_hoa_0_global'			=> '    Send Echo Request (forwarded): TN (LinkX) -&gt; MN (Link0) (global)',
	'ns_from_nut_to_r0_multicast_global'		=> '    Recv NS: NUT (Link0) -&gt; R0 (Link0) (multicast, global)',
	'ns_from_nut_to_r0_unicast_global'		=> '    Recv NS w/o SLL: NUT (Link0) -&gt; R0 (Link0) (unicast, global)',
	'ns_from_nut_to_r0_unicast_sll_global'		=> '    Recv NS w/ SLL: NUT (Link0) -&gt; R0 (Link0) (unicast, global)',
	'na_from_r0_to_nut_global'			=> '    Send NA: R0 (Link0) -&gt; NUT (Link0) (global)',
	'ns_from_nut_to_mn_multicast_global'		=> '    Recv NS: NUT (Link0) -&gt; MN (Link0) (multicast, global)',
	'ns_from_nut_to_mn_unicast_global'		=> '    Recv NS w/o SLL: NUT (Link0) -&gt; MN (Link0) (unicast, global)',
	'ns_from_nut_to_mn_unicast_sll_global'		=> '    Recv NS w/ SLL: NUT (Link0) -&gt; MN (Link0) (unicast, global)',
	'na_from_mn_to_nut_global'			=> '    Send NA: MN (Link0) -&gt; NUT (Link0) (global)',
	'ra_from_nut'					=> '    Recv RA: NUT (Link0) -&gt; all-nodes multicast address (Link0)',
	'ra_from_ha1'					=> '    Send RA: HA1 (Link0) -&gt; all-nodes multicast address (Link0)',
	'ra_from_ha2'					=> '    Send RA: HA2 (Link0) -&gt; all-nodes multicast address (Link0)',
	'BU'						=> '    Send BU: MN\' (LinkX) -&gt; NUT (Link0) (global)',
	'BU_Home'					=> '    Send BU: MN (Link0) -&gt; NUT (Link0) (global)',
	'BA'						=> '    Recv BA: NUT (Link0) -&gt; MN\' (LinkX) (global)',
	'BA_DeReg'					=> '    Recv BA (De-Registration): NUT (Link0) -&gt; MN\' (LinkX) (global)',
	'BA_Home_DeReg'					=> '    Recv BA (De-Registration): NUT (Link0) -&gt; MN (Link0) (global)',
	'dad_linklocal'					=> '    Recv DAD: unspecified address -&gt; MN (link-local) solicited-node multicast address',
	'dad_sitelocal'					=> '    Recv DAD: unspecified address -&gt; MN (site-local) solicited-node multicast address',
	'dad_global'					=> '    Recv DAD: unspecified address -&gt; MN (global) solicited-node multicast address',
	'get_sitelocal'					=> '    Send dummy packet for calculating NUT site-local address: NUT (Link0) -&gt; NUT (Link0) (site-local)',
	'na_dad_global'					=> '    Send NA (global): MN (Link0) -&gt; all-nodes multicast address (Link0)',
	'na_dad_sitelocal'				=> '    Send NA (site-local): MN (Link0) -&gt; all-nodes multicast address (Link0)',
	'na_dad_linklocal'				=> '    Send NA (link-local): MN (Link0) -&gt; all-nodes multicast address (Link0)',
	'multicast_na_global'				=> '    Recv NA (global): NUT (Link0) -&gt; all-nodes multicast address (Link0)',
	'multicast_na_sitelocal'			=> '    Recv NA (site-local): NUT (Link0) -&gt; all-nodes multicast address (Link0)',
	'multicast_na_linklocal'			=> '    Recv NA (link-local): NUT (Link0) -&gt; all-nodes multicast address (Link0)',
	'HAADReq'					=> '    Send HAAD Request: MN\' (LinkX) -&gt; MIP6 HAs anycast address',
	'HAADRep'					=> '    Recv HAAD Reply: HA (Link0) -&gt; MN\' (LinkX)',
	'HAADRepDelete'					=> '    Recv HAAD Reply: HA (Link0) -&gt; MN\' (LinkX)',
	'rs_from_mn'					=> '    Send RS: unspecified address -&gt; all-routers multicast address',
	'proxy_global_ns_dad'				=> '    Send NS: unspecified address -&gt; MN (global) solicited-node multicast address',
	'proxy_global_ns_multi'				=> '    Send NS: TN0 (Link0) -&gt; MN (Link0) (multicast, global)',
	'proxy_global_ns_uni'				=> '    Send NS: TN0 (Link0) -&gt; MN (Link0) (unicast, global)',
	'proxy_site_ns_dad'				=> '    Send NS: unspecified address -&gt; MN (site-local) solicited-node multicast address',
	'proxy_site_ns_multi'				=> '    Send NS: TN0 (Link0) -&gt; MN (Link0) (multicast, site-local)',
	'proxy_site_ns_uni'				=> '    Send NS: TN0 (Link0) -&gt; MN (Link0) (unicast, site-local)',
	'proxy_link_ns_dad'				=> '    Send NS: unspecified address -&gt; MN (link-local) solicited-node multicast address',
	'proxy_link_ns_multi'				=> '    Send NS: TN0 (Link0) -&gt; MN (Link0) (multicast, link-local)',
	'proxy_link_ns_uni'				=> '    Send NS: TN0 (Link0) -&gt; MN (Link0) (unicast, link-local)',
	'proxy_global_na'				=> '    Recv NA w/ TLL: MN (Link0) -&gt; TN0 (Link0) (global)',
	'proxy_global_na_tll'				=> '    Recv NA w/o TLL: MN (Link0) -&gt; TN0 (Link0) (global)',
	'proxy_site_na'					=> '    Recv NA w/ TLL: MN (Link0) -&gt; TN0 (Link0) (site-local)',
	'proxy_site_na_tll'				=> '    Recv NA w/o TLL: MN (Link0) -&gt; TN0 (Link0) (site-local)',
	'proxy_link_na'					=> '    Recv NA w/ TLL: MN (Link0) -&gt; TN0 (Link0) (link-local)',
	'proxy_link_na_tll'				=> '    Recv NA w/o TLL: MN (Link0) -&gt; TN0 (Link0) (link-local)',
	'proxy_global_na_dad'				=> '    Recv NA (global): MN (Link0) -&gt; all-nodes multicast address (Link0)',
	'proxy_site_na_dad'				=> '    Recv NA (site-local): MN (Link0) -&gt; all-nodes multicast address (Link0)',
	'proxy_link_na_dad'				=> '    Recv NA (link-local): MN (Link0) -&gt; all-nodes multicast address (Link0)',
);

################################################################
%nd = (
	'ns_from_nut_to_r0_multicast_global'	=> 'na_from_r0_to_nut_global',
	'ns_from_nut_to_r0_unicast_global'	=> 'na_from_r0_to_nut_global',
	'ns_from_nut_to_r0_unicast_sll_global'	=> 'na_from_r0_to_nut_global',
	'ra_from_nut'				=> 'ignore',
);

#
# MIP6_CheckReachability()
#
#	chek global reachability
#	chek default router
#
################################################################

sub MIP6_CheckReachability($) {
	my ($Link) = @_;

	my %ret = ();

	vClear($Link);
	vSend($Link, 'ereq_from_tn_to_nut_global');

	for(my $d = 0; $d < $vrecv_loop; $d ++) {
		my $recv = '';
		my $send = '';

		%ret = vRecv($Link, $vrecv_wait, 0, 0, sort(keys(%nd)), 'erep_from_nut_to_tn_global');

		while(($recv, $send) = each(%nd)) {
			if($ret{'recvFrame'} eq $recv) {
				if($send ne 'ignore') {
					vSend($Link, $send);
				}

				$d --;
				last;
			}
		}

		if($ret{'recvFrame'} eq 'erep_from_nut_to_tn_global') {
			return(0);
		}
	}

	return(-1);
}

#
# MIP6_Registration()
#
################################################################

sub MIP6_Registration($$$$$$$$) {
	my ($Link, $sn, $a, $h, $s, $d, $l, $lt) = @_;

	my %ret = ();

	my $cpp = '';

	if($sn) {
		$cpp .= "-DSEQ=$sn ";
	}

	if($a) {
		$cpp .= "-DACKNOWLEDGE=$a ";
	}

	if($h) {
		$cpp .= "-DHOMEREGISTRATION=$h ";
	}

	if($s) {
		$cpp .= "-DSINGLEADDR=$s ";
	}

	if($d) {
		$cpp .= "-DDAD=$d ";
	}

	if($l) {
		$cpp .= "-DLINKLOCAL=$l ";
	}

	if($lt) {
		$cpp .= "-DLIFETIME=$lt ";
	}

	vCPP($cpp);

	vClear($Link);
	vSend($Link, 'BU');

	for(my $d = 0; $d < $vrecv_loop; $d ++) {
		my $recv = '';
		my $send = '';

		%ret = vRecv($Link, $vrecv_wait, 0, 0, sort(keys(%nd)), 'BA');

		while(($recv, $send) = each(%nd)) {
			if($ret{'recvFrame'} eq $recv) {
				if($send ne 'ignore') {
					vSend($Link, $send);
				}

				$d --;
				last;
			}
		}

		if($ret{'recvFrame'} eq 'BA') {
			return(0);
		}
	}

	return(-1);
}

#
# MIP6_DeRegistration()
#
################################################################

sub MIP6_DeRegistration($$$$$$$$) {
	my ($Link, $sn, $a, $h, $s, $d, $l, $lt) = @_;

	my %ret = ();

	my $cpp = '';

	if($sn) {
		$cpp .= "-DSEQ=$sn ";
	}

	if($a) {
		$cpp .= "-DACKNOWLEDGE=$a ";
	}

	if($h) {
		$cpp .= "-DHOMEREGISTRATION=$h ";
	}

	if($s) {
		$cpp .= "-DSINGLEADDR=$s ";
	}

	if($d) {
		$cpp .= "-DDAD=$d ";
	}

	if($l) {
		$cpp .= "-DLINKLOCAL=$l ";
	}

	if($lt) {
		$cpp .= "-DLIFETIME=$lt ";
	}

	vCPP($cpp);

	vClear($Link);
	vSend($Link, 'BU');

	for(my $d = 0; $d < $vrecv_loop; $d ++) {
		my $recv = '';
		my $send = '';

		%ret = vRecv($Link, $vrecv_wait, 0, 0, sort(keys(%nd)), 'BA_DeReg');

		while(($recv, $send) = each(%nd)) {
			if($ret{'recvFrame'} eq $recv) {
				if($send ne 'ignore') {
					vSend($Link, $send);
				}

				$d --;
				last;
			}
		}

		if($ret{'recvFrame'} eq 'BA_DeReg') {
			return(0);
		}
	}

	return(-1);
}

#
# MIP6_DeRegistrationHome()
#
################################################################

sub MIP6_DeRegistrationHome($$$$$$$$) {
	my ($Link, $sn, $a, $h, $s, $d, $l, $lt) = @_;

	my %ret = ();

	$nd{'ns_from_nut_to_mn_multicast_global'}	= 'na_from_mn_to_nut_global';
	$nd{'ns_from_nut_to_mn_unicast_global'}		= 'na_from_mn_to_nut_global';
	$nd{'ns_from_nut_to_mn_unicast_sll_global'}	= 'na_from_mn_to_nut_global';

	my $cpp = '';

	if($sn) {
		$cpp .= "-DSEQ=$sn ";
	}

	if($a) {
		$cpp .= "-DACKNOWLEDGE=$a ";
	}

	if($h) {
		$cpp .= "-DHOMEREGISTRATION=$h ";
	}

	if($s) {
		$cpp .= "-DSINGLEADDR=$s ";
	}

	if($d) {
		$cpp .= "-DDAD=$d ";
	}

	if($l) {
		$cpp .= "-DLINKLOCAL=$l ";
	}

	if($lt) {
		$cpp .= "-DLIFETIME=$lt ";
	}

	vCPP($cpp);

	vClear($Link);
	vSend($Link, 'BU_Home');

	for(my $d = 0; $d < $vrecv_loop; $d ++) {
		my $recv = '';
		my $send = '';

		%ret = vRecv($Link, $vrecv_wait, 0, 0, sort(keys(%nd)), 'BA_Home_DeReg');

		while(($recv, $send) = each(%nd)) {
			if($ret{'recvFrame'} eq $recv) {
				if($send ne 'ignore') {
					vSend($Link, $send);
				}

				$d --;
				last;
			}
		}

		if($ret{'recvFrame'} eq 'BA_Home_DeReg') {
			return(0);
		}
	}

	return(-1);
}

#
# MIP6_RegistrationNotHomeSubnet()
#
################################################################

sub MIP6_RegistrationNotHomeSubnet($$$$$$$$) {
	my ($Link, $sn, $a, $h, $s, $d, $l, $lt) = @_;

	my %ret = ();

	my $cpp .= "-DSTATUS=132 ";
	my $count = 0;

	$pktdesc{'BA'} = '    Recv BA Status=132: NUT (Link0) -&gt; MN\' (LinkX) (global)';

	if($sn) {
		$cpp .= "-DSEQ=$sn ";
	}

	if($a) {
		$cpp .= "-DACKNOWLEDGE=$a ";
	}

	if($h) {
		$cpp .= "-DHOMEREGISTRATION=$h ";
	}

	if($s) {
		$cpp .= "-DSINGLEADDR=$s ";
	}

	if($d) {
		$cpp .= "-DDAD=$d ";
	}

	if($l) {
		$cpp .= "-DLINKLOCAL=$l ";
	}

	if($lt) {
		$cpp .= "-DLIFETIME=$lt ";
	}

	vCPP($cpp);

	vClear($Link);
	vSend($Link, 'BU');

	for(my $d = 0; $d < $vrecv_loop; $d ++) {
		my $recv = '';
		my $send = '';

		%ret = vRecv($Link, $vrecv_wait, 0, 0, sort(keys(%nd)), 'BA');
		$count = $ret{'recvCount'};

		while(($recv, $send) = each(%nd)) {
			if($ret{'recvFrame'} eq $recv) {
				if($send ne 'ignore') {
					vSend($Link, $send);
				}

				$d --;
				$count --;
				last;
			}
		}

		if($ret{'recvFrame'} eq 'BA') {
			return(0);
		}

		if($count) {
			vLogHTML('<FONT COLOR="#FF0000">Recv unexpect packets</FONT><BR>');
			exit($V6evalTool::exitFail);
		}
	}

	return(-1);
}

#
# MIP6_InvalidDeRegistration()
#
################################################################

sub MIP6_InvalidDeRegistration($$$$$$$$) {
	my ($Link, $sn, $a, $h, $s, $d, $l, $lt) = @_;

	my %ret = ();

	my $cpp .= "-DSTATUS=133 ";

	$pktdesc{'BA'} = '    Recv BA Status=133: NUT (Link0) -&gt; MN\' (LinkX) (global)';

	if($sn) {
		$cpp .= "-DSEQ=$sn ";
	}

	if($a) {
		$cpp .= "-DACKNOWLEDGE=$a ";
	}

	if($h) {
		$cpp .= "-DHOMEREGISTRATION=$h ";
	}

	if($s) {
		$cpp .= "-DSINGLEADDR=$s ";
	}

	if($d) {
		$cpp .= "-DDAD=$d ";
	}

	if($l) {
		$cpp .= "-DLINKLOCAL=$l ";
	}

	if($lt) {
		$cpp .= "-DLIFETIME=$lt ";
	}

	vCPP($cpp);

	vClear($Link);
	vSend($Link, 'BU');

	for(my $d = 0; $d < $vrecv_loop; $d ++) {
		my $recv = '';
		my $send = '';

		%ret = vRecv($Link, $vrecv_wait, 0, 0, sort(keys(%nd)), 'BA');

		while(($recv, $send) = each(%nd)) {
			if($ret{'recvFrame'} eq $recv) {
				if($send ne 'ignore') {
					vSend($Link, $send);
				}

				$d --;
				last;
			}
		}

		if($ret{'recvFrame'} eq 'BA') {
			return(0);
		}
	}

	return(-1);
}

#
# MIP6_CheckBindingCache()
#
################################################################

sub MIP6_CheckBindingCache($) {
	my ($Link) = @_;

	my %ret = ();

	vClear($Link);
	vSend($Link, 'ereq_from_tn_to_hoa_global');

	for(my $d = 0; $d < $vrecv_loop; $d ++) {
		my $recv = '';
		my $send = '';

		%ret = vRecv($Link, $vrecv_wait, 0, 0, sort(keys(%nd)), 'ereq_from_tn_to_hoa_global_encapsulated');

		while(($recv, $send) = each(%nd)) {
			if($ret{'recvFrame'} eq $recv) {
				if($send ne 'ignore') {
					vSend($Link, $send);
				}

				$d --;
				last;
			}
		}

		if($ret{'recvFrame'} eq 'ereq_from_tn_to_hoa_global_encapsulated') {
			return(0);
		}
	}

	return(-1);
}

#
# MIP6_CheckNoBindingCacheNotHomeSubnet()
#
################################################################

sub MIP6_CheckNoBindingCacheNotHomeSubnet($) {
	my ($Link) = @_;

	my %ret = ();

	$pktdesc{'ereq_from_tn_to_hoa_global'} = '    Send Echo Request: TN (LinkX) -&gt; MN (LinkY) (global)';

	vClear($Link);
	vSend($Link, 'ereq_from_tn_to_hoa_global');

	for(my $d = 0; $d < $vrecv_loop; $d ++) {
		my $recv = '';
		my $send = '';

		%ret = vRecv($Link, $vrecv_wait, 0, 0, sort(keys(%nd)), 'ereq_from_tn_to_hoa_y_global');

		while(($recv, $send) = each(%nd)) {
			if($ret{'recvFrame'} eq $recv) {
				if($send ne 'ignore') {
					vSend($Link, $send);
				}

				$d --;
				last;
			}
		}

		if($ret{'recvFrame'} eq 'ereq_from_tn_to_hoa_y_global') {
			return(0);
		}
	}

	return(-1);
}

#
# MIP6_CheckNoBindingCacheHomeSubnet()
#
################################################################

sub MIP6_CheckNoBindingCacheHomeSubnet($) {
	my ($Link) = @_;

	my %ret = ();

	$nd{'ns_from_nut_to_mn_multicast_global'}	= 'na_from_mn_to_nut_global';
	$nd{'ns_from_nut_to_mn_unicast_global'}		= 'na_from_mn_to_nut_global';
	$nd{'ns_from_nut_to_mn_unicast_sll_global'}	= 'na_from_mn_to_nut_global';

	vClear($Link);
	vSend($Link, 'ereq_from_tn_to_hoa_global');

	for(my $d = 0; $d < $vrecv_loop; $d ++) {
		my $recv = '';
		my $send = '';

		%ret = vRecv($Link, $vrecv_wait, 0, 0, sort(keys(%nd)), 'ereq_from_tn_to_hoa_0_global');

		while(($recv, $send) = each(%nd)) {
			if($ret{'recvFrame'} eq $recv) {
				if($send ne 'ignore') {
					vSend($Link, $send);
				}

				$d --;
				last;
			}
		}

		if($ret{'recvFrame'} eq 'ereq_from_tn_to_hoa_0_global') {
			return(0);
		}
	}

	return(-1);
}

#
# MIP6_DAD()
#
################################################################

sub MIP6_DAD($$$$$$$$) {
	my ($Link, $sn, $a, $h, $s, $d, $l, $lt) = @_;

	my %ret = ();

	my $cpp = '';

	my $got_dad_linklocal = 0;
	my $got_dad_sitelocal = 0;
	my $got_dad_global = 0;

	if($sn) {
		$cpp .= "-DSEQ=$sn ";
	}

	if($a) {
		$cpp .= "-DACKNOWLEDGE=$a ";
	}

	if($h) {
		$cpp .= "-DHOMEREGISTRATION=$h ";
	}

	if($s) {
		$cpp .= "-DSINGLEADDR=$s ";
	}

	if($d) {
		$cpp .= "-DDAD=$d ";
	}

	if($l) {
		$cpp .= "-DLINKLOCAL=$l ";
	}

	if($lt) {
		$cpp .= "-DLIFETIME=$lt ";
	}

	vCPP($cpp);

	vClear($Link);
	vSend($Link, 'BU');

	for(my $d = 0; $d < $vrecv_loop; $d ++) {
		my $recv = '';
		my $send = '';

		%ret = vRecv($Link, $vrecv_wait, 0, 0, sort(keys(%nd)), 'BA', 'dad_linklocal', 'dad_sitelocal', 'dad_global');

		while(($recv, $send) = each(%nd)) {
			if($ret{'recvFrame'} eq $recv) {
				if($send ne 'ignore') {
					vSend($Link, $send);
				}

				$d --;
				last;
			}
		}

		if($ret{'recvFrame'} eq 'dad_global') {
			$got_dad_global ++;
			$d --;
			next;
		}

		if($ret{'recvFrame'} eq 'dad_sitelocal') {
			$got_dad_sitelocal ++;
			$d --;
			next;
		}

		if($ret{'recvFrame'} eq 'dad_linklocal') {
			$got_dad_linklocal ++;
			$d --;
			next;
		}

		if($ret{'recvFrame'} eq 'BA') {
			if(($got_dad_global == 0) &&
			   ($got_dad_sitelocal == 0) &&
			   ($got_dad_linklocal != 0)) {
				return(0);
			}

			if(($got_dad_global == 0) &&
			   ($got_dad_sitelocal == 0) &&
			   ($got_dad_linklocal == 0)) {
				vLogHTML('Can\'t get any DAD<BR>');
				exit($V6evalTool::exitFail);
			}

			if($l) {
				if($s) {
					if(($got_dad_global != 0) &&
					   ($got_dad_sitelocal == 0) &&
					   ($got_dad_linklocal != 0)) {
						return(0);
					}
				} else {
					if(($got_dad_global != 0) &&
					   ($got_dad_sitelocal != 0) &&
					   ($got_dad_linklocal != 0)) {
						return(0);
					}
				}
			} else {
				if(($got_dad_global != 0) &&
				   ($got_dad_sitelocal == 0) &&
				   ($got_dad_linklocal == 0)) {
					return(0);
				}
			}

			vLogHTML('Got DAD for unexpected scope<BR>');
			exit($V6evalTool::exitFail);
		}
	}

	return(-1);
}

#
# MIP6_DAD_Failed()
#
################################################################

sub MIP6_DAD_Failed($$$$$$$$) {
	my ($Link, $sn, $a, $h, $s, $d, $l, $lt) = @_;

	my %ret = ();

	my $cpp .= "-DSTATUS=134 ";

	$pktdesc{'BA'} = '    Recv BA Status=134: NUT (Link0) -&gt; MN\' (LinkX) (global)';

	my $got_dad = 0;
	my $got_ba = 0;

	my %dad = (
		'dad_global'	=> 'na_dad_global',
		'dad_sitelocal'	=> 'na_dad_sitelocal',
		'dad_linklocal'	=> 'na_dad_linklocal',
	);

	if($sn) {
		$cpp .= "-DSEQ=$sn ";
	}

	if($a) {
		$cpp .= "-DACKNOWLEDGE=$a ";
	}

	if($h) {
		$cpp .= "-DHOMEREGISTRATION=$h ";
	}

	if($s) {
		$cpp .= "-DSINGLEADDR=$s ";
	}

	if($d) {
		$cpp .= "-DDAD=$d ";
	}

	if($l) {
		$cpp .= "-DLINKLOCAL=$l ";
	}

	if($lt) {
		$cpp .= "-DLIFETIME=$lt ";
	}

	vCPP($cpp);

	vClear($Link);
	vSend($Link, 'BU');

	for(my $d = 0; $d < $vrecv_loop; $d ++) {
		my $recv = '';
		my $send = '';

		%ret = vRecv($Link, $vrecv_wait, 0, 0, sort(keys(%nd)), sort(keys(%dad)), 'BA');

		while(($recv, $send) = each(%nd)) {
			if($ret{'recvFrame'} eq $recv) {
				if($send ne 'ignore') {
					vSend($Link, $send);
				}

				$d --;
				last;
			}
		}

		while(($recv, $send) = each(%dad)) {
			if($ret{'recvFrame'} eq $recv) {
				vSend($Link, $send);

				$got_dad ++;

				$d --;
				last;
			}
		}

		if($ret{'recvFrame'} eq 'BA') {
			$got_ba ++;
			last;
		}
	}

	unless($got_dad) {
		vLogHTML('Can\'t get any DAD<BR>');
		exit($V6evalTool::exitFail);
	}

	unless($got_ba) {
		return(-1);
	}

	return(0);
}

#
# MIP6_GetSiteLocalAddr()
#
################################################################

sub MIP6_GetSiteLocalAddr($) {
	my ($Link) = @_;

	my %ret = vSend($Link, 'get_sitelocal');

	return($ret{'Frame_Ether.Packet_IPv6.Hdr_IPv6.DestinationAddress'});
}

#
# MIP6_ReverseTunneling()
#
################################################################

sub MIP6_ReverseTunneling($) {
	my ($Link) = @_;

	my %ret = ();

	vClear($Link);
	vSend($Link, 'ereq_from_mn_to_tn_global_encapsulated');

	for(my $d = 0; $d < $vrecv_loop; $d ++) {
		my $recv = '';
		my $send = '';

		%ret = vRecv($Link, $vrecv_wait, 0, 0, sort(keys(%nd)), 'ereq_from_mn_to_tn_global');

		while(($recv, $send) = each(%nd)) {
			if($ret{'recvFrame'} eq $recv) {
				if($send ne 'ignore') {
					vSend($Link, $send);
				}

				$d --;
				last;
			}
		}

		if($ret{'recvFrame'} eq 'ereq_from_mn_to_tn_global') {
			return(0);
		}
	}

	return(-1);
}

#
# MIP6_MulticastNA()
#
################################################################

sub MIP6_MulticastNA($$$$$$$$) {
	my ($Link, $sn, $a, $h, $s, $d, $l, $lt) = @_;

	my %ret = ();

	my $cpp = '';

	my $got_na_linklocal = 0;
	my $got_na_sitelocal = 0;
	my $got_na_global = 0;
	my $got_ba = 0;

	if($sn) {
		$cpp .= "-DSEQ=$sn ";
	}

	if($a) {
		$cpp .= "-DACKNOWLEDGE=$a ";
	}

	if($h) {
		$cpp .= "-DHOMEREGISTRATION=$h ";
	}

	if($s) {
		$cpp .= "-DSINGLEADDR=$s ";
	}

	if($d) {
		$cpp .= "-DDAD=$d ";
	}

	if($l) {
		$cpp .= "-DLINKLOCAL=$l ";
	}

	if($lt) {
		$cpp .= "-DLIFETIME=$lt ";
	}

	vCPP($cpp);

	vClear($Link);
	vSend($Link, 'BU');

	for(my $d = 0; $d < $vrecv_loop; $d ++) {
		my $recv = '';
		my $send = '';

		%ret = vRecv($Link, $vrecv_wait, 0, 0, sort(keys(%nd)), 'BA', 'multicast_na_linklocal', 'multicast_na_sitelocal', 'multicast_na_global');

		while(($recv, $send) = each(%nd)) {
			if($ret{'recvFrame'} eq $recv) {
				if($send ne 'ignore') {
					vSend($Link, $send);
				}

				$d --;
				last;
			}
		}

		if($ret{'recvFrame'} eq 'multicast_na_global') {
			$got_na_global ++;
			$d --;
			next;
		}

		if($ret{'recvFrame'} eq 'multicast_na_sitelocal') {
			$got_na_sitelocal ++;
			$d --;
			next;
		}

		if($ret{'recvFrame'} eq 'multicast_na_linklocal') {
			$got_na_linklocal ++;
			$d --;
			next;
		}

		if($ret{'recvFrame'} eq 'BA') {
			$got_ba ++;
			last;
		}
	}

	if(($got_na_global == 0) &&
	   ($got_na_sitelocal == 0) &&
	   ($got_na_linklocal == 0)) {
		vLogHTML('Can\'t get any multicast NA<BR>');
		exit($V6evalTool::exitFail);
	}

	if($got_ba) {
		if($l) {
			if($s) {
				if(($got_na_global != 0) &&
				   ($got_na_sitelocal == 0) &&
				   ($got_na_linklocal != 0)) {
					return(0);
				}
			} else {
				if(($got_na_global != 0) &&
				   ($got_na_sitelocal != 0) &&
				   ($got_na_linklocal != 0)) {
					return(0);
				}
			}
		} else {
			if(($got_na_global != 0) &&
			   ($got_na_sitelocal == 0) &&
			   ($got_na_linklocal == 0)) {
				return(0);
			}
		}

		vLogHTML('Got multicast NA for unexpected scope<BR>');
		exit($V6evalTool::exitFail);
	}

	return(-1);
}

#
# MIP6_Initialize()
#
################################################################

sub MIP6_Initialize($$) {
	my ($Link, $Device) = @_;

	vClear($Link);

	vLogHTML('<FONT SIZE="4"><U><B>Calculate NUT site-local address</B></U></FONT><BR>');
	my $addr = MIP6_GetSiteLocalAddr($Link);

	vLogHTML('<FONT SIZE="4"><U><B>Initialize target</B></U></FONT><BR>');
	if(vRemote('reboot.rmt', '')) {
		vLogHTML('<FONT COLOR="#FF0000">reboot.rmt: Can\'t reboot</FONT><BR>');
		exit($V6evalTool::exitFatal);
	}

	if(vRemote('manualaddrconf.rmt', "if=$Device addr=$addr len=64 type=unicast", '')) {
		vLogHTML('<FONT COLOR="#FF0000">manualaddrconf.rmt: Can\'t configure address</FONT><BR>');
		exit($V6evalTool::exitFatal);
	}

	if(vRemote('mip6EnableHA.rmt', "device=$Device", '')) {
		vLogHTML('<FONT COLOR="#FF0000">mip6EnableHA.rmt: Can\'t enable CN function</FONT><BR>');
		exit($V6evalTool::exitFatal);
	}

	if(vRemote('route.rmt', 'cmd=add', 'prefix=default', 'gateway=3ffe:501:ffff:100::a0a0')) {
		vLogHTML('<FONT COLOR="#FF0000">route.rmt: Can\'t configure routing table</FONT><BR>');
		exit($V6evalTool::exitFatal);
	}

	vSleep(3);

	return(0);
}

#
# MIP6_DHAAD()
#
################################################################

sub MIP6_DHAAD($$$) {
	my ($Link, $vsend, $vrecv) = @_;

	my %ret = ();

	vClear($Link);
	vSend($Link, $vsend);

	for(my $d = 0; $d < $vrecv_loop; $d ++) {
		my $recv = '';
		my $send = '';

		%ret = vRecv($Link, $vrecv_wait, 0, 0, sort(keys(%nd)), $vrecv);

		while(($recv, $send) = each(%nd)) {
			if($ret{'recvFrame'} eq $recv) {
				if($send ne 'ignore') {
					vSend($Link, $send);
				}

				$d --;
				last;
			}
		}

		if($ret{'recvFrame'} eq $vrecv) {
			return(0);
		}
	}

	return(-1);
}

#
# MIP6_SendRA_HA1()
#
################################################################

sub MIP6_SendRA_HA1($$$) {
	my ($Link, $preference, $lifetime) = @_;

	my $cpp = '';

	if($preference != 0) {
		$cpp .= "-DHA1_PREF=$preference ";
	}

	if($lifetime != 0) {
		$cpp .= "-DHA1_LIFETIME=$lifetime ";
	}

	vCPP($cpp);

	vClear($Link);

	for(my $d = 0; $d < $vrecv_loop; $d ++) {
		vSend($Link, 'rs_from_mn', 'ra_from_ha1');

		my $recv = '';
		my $send = '';

		%ret = vRecv($Link, $vrecv_wait, 0, 0, sort(keys(%nd)));

		while(($recv, $send) = each(%nd)) {
			if($ret{'recvFrame'} eq $recv) {
				if($send ne 'ignore') {
					vSend($Link, $send);
					$d --;
				}

				last;
			}
		}
	}

	return;
}

#
# MIP6_SendRA_HA1_HA2()
#
################################################################

sub MIP6_SendRA_HA1_HA2($$$$$) {
	my ($Link, $preference1, $lifetime1, $preference2, $lifetime2) = @_;

	my $cpp = '';

	if($preference1 != 0) {
		$cpp .= "-DHA1_PREF=$preference1 ";
	}

	if($lifetime1 != 0) {
		$cpp .= "-DHA1_LIFETIME=$lifetime1 ";
	}

	if($preference2 != 0) {
		$cpp .= "-DHA2_PREF=$preference2 ";
	}

	if($lifetime2 != 0) {
		$cpp .= "-DHA2_LIFETIME=$lifetime2 ";
	}

	vCPP($cpp);

	vClear($Link);

	for(my $d = 0; $d < $vrecv_loop; $d ++) {
		vSend($Link, 'rs_from_mn', 'ra_from_ha1', 'ra_from_ha2');

		my $recv = '';
		my $send = '';

		%ret = vRecv($Link, $vrecv_wait, 0, 0, sort(keys(%nd)));

		while(($recv, $send) = each(%nd)) {
			if($ret{'recvFrame'} eq $recv) {
				if($send ne 'ignore') {
					vSend($Link, $send);
					$d --;
				}

				last;
			}
		}
	}

	return;
}

#
# MIP6_ProxyND()
#
################################################################

sub MIP6_ProxyND($$$) {
	my ($Link, $s, $l) = @_;

	my %result = ();
	my $got_fail = 0;

	my $bool_sitelocal = 0;
	my $bool_linklocal = 0;

	if($l) {
		$bool_linklocal ++;

		unless($s) {
			$bool_sitelocal ++;
		}
	}

	vLogHTML('<B><A NAME="SUBTEST1">1. Multicast NS (global)<B> <A HREF="#SUMMARY">summary</A><BR>');
	$result{'1. Multicast NS (global)'}	= MIP6_SendRecv($Link, 1,			'proxy_global_ns_multi',	'proxy_global_na_tll');

	vLogHTML('<B><A NAME="SUBTEST2">2. Multicast NS (site-local)<B> <A HREF="#SUMMARY">summary</A><BR>');
	$result{'2. Multicast NS (site-local)'}	= MIP6_SendRecv($Link, $bool_sitelocal,		'proxy_site_ns_multi',		'proxy_site_na_tll');

	vLogHTML('<B><A NAME="SUBTEST3">3. Multicast NS (link-local)<B> <A HREF="#SUMMARY">summary</A><BR>');
	$result{'3. Multicast NS (link-local)'}	= MIP6_SendRecv($Link, $bool_linklocal,		'proxy_link_ns_multi',		'proxy_link_na_tll');

	vLogHTML('<B><A NAME="SUBTEST4">4. Unicast NS (global)<B> <A HREF="#SUMMARY">summary</A><BR>');
	$result{'4. Unicast NS (global)'}	= MIP6_SendRecv($Link, 1,			'proxy_global_ns_uni',		'proxy_global_na', 'proxy_global_na_tll');

	vLogHTML('<B><A NAME="SUBTEST5">5. Unicast NS (site-local)<B> <A HREF="#SUMMARY">summary</A><BR>');
	$result{'5. Unicast NS (site-local)'}	= MIP6_SendRecv($Link, $bool_sitelocal,		'proxy_site_ns_uni',		'proxy_site_na', 'proxy_site_na_tll');

	vLogHTML('<B><A NAME="SUBTEST6">6. Unicast NS (link-local)<B> <A HREF="#SUMMARY">summary</A><BR>');
	$result{'6. Unicast NS (link-local)'}	= MIP6_SendRecv($Link, $bool_linklocal,		'proxy_link_ns_uni',		'proxy_link_na', 'proxy_link_na_tll');

	vLogHTML('<B><A NAME="SUBTEST7">7. DAD (global)<B> <A HREF="#SUMMARY">summary</A><BR>');
	$result{'7. DAD (global)'}		= MIP6_SendRecv($Link, 1,			'proxy_global_ns_dad',		'proxy_global_na_dad');

	vLogHTML('<B><A NAME="SUBTEST8">8. DAD (site-local)<B> <A HREF="#SUMMARY">summary</A><BR>');
	$result{'8. DAD (site-local)'}		= MIP6_SendRecv($Link, $bool_sitelocal,		'proxy_site_ns_dad',		'proxy_site_na_dad');

	vLogHTML('<B><A NAME="SUBTEST9">9. DAD (link-local)<B> <A HREF="#SUMMARY">summary</A><BR>');
	$result{'9. DAD (link-local)'}		= MIP6_SendRecv($Link, $bool_linklocal ,	'proxy_link_ns_dad',		'proxy_link_na_dad');

	my $step = 1;
	vLogHTML('<A NAME="SUMMARY">');
	vLogHTML('<TABLE BORDER>');
	for $title (sort(keys(%result))) {
		my $code = '<B>PASS</B>';

		if($result{$title} < 0) {
			$code = '<B><FONT COLOR="#FF0000">FAIL</FONT></B>';
			$got_fail ++;
		}

		vLogHTML('<TR>');
		vLogHTML("<TD ALIGN=\"left\">$title</TD>");
		vLogHTML("<TD ALIGN=\"right\">$code</TD>");
		vLogHTML("<TD ALIGN=\"center\"><A HREF=\"#SUBTEST$step\">reference</A></TD>");
		vLogHTML('</TR>');

		$step ++;
	}
	vLogHTML('</TABLE>');

	if($got_fail) {
		return(-1);
	}

	return(0);
}

#
# MIP6_SendRecv()
#
################################################################

sub MIP6_SendRecv($$$@) {
	my ($Link, $bool, $vsend, @vrecv) = @_;

	vClear($Link);
	vSend($Link, $vsend);

	for(my $d = 0; $d < $vrecv_loop; $d ++) {
		my $recv = '';
		my $send = '';

		%ret = vRecv($Link, $vrecv_wait, 0, 0, sort(keys(%nd)), @vrecv);

		while(($recv, $send) = each(%nd)) {
			if($ret{'recvFrame'} eq $recv) {
				if($send ne 'ignore') {
					vSend($Link, $send);
					$d --;
				}

				last;
			}
		}

		for(my $d = 0; $d <= $#vrecv; $d ++) {
			if($ret{'recvFrame'} eq $vrecv[$d]) {
				if($bool) {
					return(0);
				} else {
					return(-1);
				}
			}
		}
	}

	if($bool) {
		return(-1);
	} else {
		return(0);
	}
}
