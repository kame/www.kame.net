#!/usr/bin/perl
#
# $Copyright$
#
# $TAHI: ct/mip6-mn-19/MIP6.pm,v 1.6 2003/01/17 04:07:56 akisada Exp $
#
################################################################

package MIP6;

use Exporter;

@ISA = qw(Exporter);

@EXPORT = qw(
	%pktdesc
	MIP6_CheckReachability
	MIP6_CheckReachabilityOnHomeLink
	MIP6_MovementDetection
);

use V6evalTool;

################################################################
%pktdesc = (
	'ereq_from_ha0_to_nut_linklocal'		=> '    Send Echo Request: HA0 (Link0) -&gt; NUT (Link0) (link-local)',
	'erep_from_nut_to_ha0_linklocal'		=> '    Recv Echo Reply: NUT (Link0) -&gt; HA0 (Link0) (link-local)',
	'ereq_from_r0_to_nut_global'			=> '    Send Echo Request: R0 (LinkX) -&gt; NUT (Link0) (global)',
	'erep_from_nut_to_r0_global'			=> '    Recv Echo Reply: NUT (Link0) -&gt; R0 (LinkX) (global)',
	'ns_from_nut_to_ha0_multicast_linklocal'	=> '    Recv NS: NUT (Link0) -&gt; HA0 (Link0) (multicast, link-local)',
	'ns_from_nut_to_ha0_unicast_linklocal'		=> '    Recv NS w/o SLL: NUT (Link0) -&gt; HA0 (Link0) (unicast, link-local)',
	'ns_from_nut_to_ha0_unicast_sll_linklocal'	=> '    Recv NS w/ SLL: NUT (Link0) -&gt; HA0 (Link0) (unicast, link-local)',
	'na_from_ha0_to_nut_linklocal'			=> '    Send NA: HA0 (Link0) -&gt; NUT (Link0) (link-local)',
	'ns_from_nut_to_ha0_multicast_global'		=> '    Recv NS: NUT (Link0) -&gt; HA0 (Link0) (multicast, global)',
	'ns_from_nut_to_ha0_unicast_global'		=> '    Recv NS w/o SLL: NUT (Link0) -&gt; HA0 (Link0) (unicast, global)',
	'ns_from_nut_to_ha0_unicast_sll_global'		=> '    Recv NS w/ SLL: NUT (Link0) -&gt; HA0 (Link0) (unicast, global)',
	'na_from_ha0_to_nut_global'			=> '    Send NA: HA0 (Link0) -&gt; NUT (Link0) (global)',
	'rs_from_nut'					=> '    Recv RS w/o SLL: NUT -&gt; all-routers multicast address',
	'rs_from_nut_sll'				=> '    Recv RS w/ SLL: NUT -&gt; all-routers multicast address',
	'ra_from_ha0'					=> '    Send RA: HA0 (Link0) -&gt; all-nodes multicast address (Link0)',
	'ns_from_nut_to_r0_multicast_linklocal'		=> '    Recv NS: NUT (LinkX) -&gt; R0 (LinkX) (multicast, link-local)',
	'ns_from_nut_to_r0_unicast_linklocal'		=> '    Recv NS w/o SLL: NUT (LinkX) -&gt; R0 (LinkX) (unicast, link-local)',
	'ns_from_nut_to_r0_unicast_sll_linklocal'	=> '    Recv NS w/ SLL: NUT (LinkX) -&gt; R0 (LinkX) (unicast, link-local)',
	'na_from_r0_to_nut_linklocal'			=> '    Send NA: R0 (LinkX) -&gt; NUT (LinkX) (link-local)',
	'ra_from_r0'					=> '    Send RA: R0 (LinkX) -&gt; all-nodes multicast address (LinkX)',
	'bu_from_nutx_to_ha0'				=> "    Recv BU: NUT (LinkX) -&gt; HA0 (Link0)",
	'ba_from_ha0_to_nutx'				=> "    Send BA: HA0 (Link0) -&gt; NUT (LinkX)",
);

#
# MIP6_CheckReachability()
#
#	chek link-local reachability at home link
#
################################################################

sub MIP6_CheckReachability($) {
	my ($Link) = @_;

	my %ret	= ();

	my %nd	= (
		'ns_from_nut_to_ha0_multicast_linklocal'	=> 'na_from_ha0_to_nut_linklocal',
		'ns_from_nut_to_ha0_unicast_linklocal'		=> 'na_from_ha0_to_nut_linklocal',
		'ns_from_nut_to_ha0_unicast_sll_linklocal'	=> 'na_from_ha0_to_nut_linklocal',
	);

	vClear($Link);

	vSend($Link, 'ereq_from_ha0_to_nut_linklocal');

	for(my $d = 0; $d < 3; $d ++) {
		%ret = vRecv($Link, 1, 0, 0, sort(keys(%nd)), 'erep_from_nut_to_ha0_linklocal');

		while(($recv, $send) = each(%nd)) {
			if($ret{'recvFrame'} eq $recv) {
				vSend($Link, $send);
				$d --;
				last;
			}
		}

		if($ret{'recvFrame'} eq 'erep_from_nut_to_ha0_linklocal') {
			return(0);
		}
	}

	return(-1);
}

#
# MIP6_CheckReachabilityOnHomeLink()
#
#	chek global reachability at home link
#	chek default router
#
################################################################

sub MIP6_CheckReachabilityOnHomeLink($) {
	my ($Link) = @_;

	my %ret	= ();

	my %nd	= (
		'ns_from_nut_to_ha0_multicast_linklocal'	=> 'na_from_ha0_to_nut_linklocal',
		'ns_from_nut_to_ha0_unicast_linklocal'		=> 'na_from_ha0_to_nut_linklocal',
		'ns_from_nut_to_ha0_unicast_sll_linklocal'	=> 'na_from_ha0_to_nut_linklocal',
		'ns_from_nut_to_ha0_multicast_global'		=> 'na_from_ha0_to_nut_global',
		'ns_from_nut_to_ha0_unicast_global'		=> 'na_from_ha0_to_nut_global',
		'ns_from_nut_to_ha0_unicast_sll_global'		=> 'na_from_ha0_to_nut_global',
		'rs_from_nut'					=> 'ra_from_ha0',
		'rs_from_nut_sll'				=> 'ra_from_ha0',
	);

	vSend($Link, 'ra_from_ha0');

	vSleep(3);

	vClear($Link);
	vSend($Link, 'ereq_from_r0_to_nut_global');

	for(my $d = 0; $d < 3; $d ++) {
		%ret = vRecv($Link, 1, 0, 0, sort(keys(%nd)), 'erep_from_nut_to_r0_global');

		while(($recv, $send) = each(%nd)) {
			if($ret{'recvFrame'} eq $recv) {
				vSend($Link, $send);
				$d --;
				last;
			}
		}

		if($ret{'recvFrame'} eq 'erep_from_nut_to_r0_global') {
			return(0);
		}

		vSend($Link, 'ra_from_ha0');
	}

	return(-1);
}

#
# MIP6_MovementDetection()
#
#	Recv BU
#	Send BA
#
################################################################

sub MIP6_MovementDetection($) {
	my ($Link) = @_;

	my %ret	= ();

	my %nd	= (
		'ns_from_nut_to_r0_multicast_linklocal'		=>	'na_from_r0_to_nut_linklocal',
		'ns_from_nut_to_r0_unicast_linklocal'		=>	'na_from_r0_to_nut_linklocal',
		'ns_from_nut_to_r0_unicast_sll_linklocal'	=>	'na_from_r0_to_nut_linklocal',
		'rs_from_nut'					=>	'ra_from_r0',
		'rs_from_nut_sll'				=>	'ra_from_r0',
	);

	my @nd_without_reply	= (
		'ns_from_nut_to_ha0_multicast_linklocal',
		'ns_from_nut_to_ha0_unicast_linklocal',
		'ns_from_nut_to_ha0_unicast_sll_linklocal',
		'ns_from_nut_to_ha0_multicast_global',
		'ns_from_nut_to_ha0_unicast_global',
		'ns_from_nut_to_ha0_unicast_sll_global',
	);

	vClear($Link);

	vSend($Link, 'ra_from_r0');

	for(my $d = 0; $d < 3; $d ++) {
		%ret = vRecv($Link, 1, 0, 0, sort(keys(%nd)), sort(@nd_without_reply), 'bu_from_nutx_to_ha0');

		for(my $x = 0; $x <= $#nd_without_reply; $x ++) {
			if($ret{'recvFrame'} eq $nd_without_reply[$x]) {
				vLogHTML('<FONT SIZE="-1"><B>Got Neighbor Unreachability Detection</B></FONT><BR>');
				$d --;
				last;
			}
		}

		while(($recv, $send) = each(%nd)) {
			if($ret{'recvFrame'} eq $recv) {
				vSend($Link, $send);
				$d --;
				last;
			}
		}

		if($ret{'recvFrame'} eq 'bu_from_nutx_to_ha0') {
			my $base = 'Frame_Ether.Packet_IPv6.Hdr_MH_BU';

			my $seq = $ret{"$base.SequenceNumber"};
			my $lifetime = $ret{"$base.Lifetime"};

			my $cpp  = "-DSEQ=$seq ";
			   $cpp .= "-DLIFETIME=$lifetime ";

			vCPP($cpp);

			vSend($Link, 'ba_from_ha0_to_nutx');

			return(0);
		}

		vSend($Link, 'ra_from_r0');
	}

	return(-1);
}
