#!/usr/bin/perl
#
# $Copyright$
#
# $TAHI: ct/mip6-cn-19/MIP6.pm,v 1.26 2003/01/13 06:45:51 akisada Exp $
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
	MIP6_CoT
	MIP6_HoT
	MIP6_NoResponse
	MIP6_ReturnRoutability
	MIP6_RR_Home
	MIP6_ProcessingBindings
	MIP6_ProcessingBindingsNoAck
	MIP6_DeleteBindingHome
	MIP6_CheckBindingCache
	MIP6_CheckNoBindingCache
	MIP6_BE_UnknownType
	MIP6_UpdateCoA
	MIP6_BU_NoResponse
	MIP6_InvalidSequence
	MIP6_NotHA
);

use V6evalTool;

################################################################
%pktdesc = (
	'ereq_from_hoa_to_nut_global'			=> '    Send Echo Request: MN (LinkX) -&gt; NUT (Link0) (global)',
	'erep_from_nut_to_hoa_global'			=> '    Recv Echo Reply: NUT (Link0) -&gt; MN (LinkX) (global)',
	'ra_from_r0'					=> '    Send RA: R0 (Link0) -&gt; all-nodes multicast address (Link0)',
	'ra_from_nut'					=> '    Send RA: NUT (Link0) -&gt; all-nodes multicast address (Link0)',
	'rs_from_nut'					=> '    Recv RS w/o SLL: NUT -&gt; all-routers multicast address',
	'rs_from_nut_sll'				=> '    Recv RS w/ SLL: NUT -&gt; all-routers multicast address',
	'ns_from_nut_to_r0_multicast_linklocal'		=> '    Recv NS: NUT (Link0) -&gt; R0 (Link0) (multicast, link-local)',
	'ns_from_nut_to_r0_unicast_linklocal'		=> '    Recv NS w/o SLL: NUT (Link0) -&gt; R0 (Link0) (unicast, link-local)',
	'ns_from_nut_to_r0_unicast_sll_linklocal'	=> '    Recv NS w/ SLL: NUT (Link0) -&gt; R0 (Link0) (unicast, link-local)',
	'ns_from_nut_to_r0_multicast_global'		=> '    Recv NS: NUT (Link0) -&gt; R0 (Link0) (multicast, global)',
	'ns_from_nut_to_r0_unicast_global'		=> '    Recv NS w/o SLL: NUT (Link0) -&gt; R0 (Link0) (unicast, global)',
	'ns_from_nut_to_r0_unicast_sll_global'		=> '    Recv NS w/ SLL: NUT (Link0) -&gt; R0 (Link0) (unicast, global)',
	'na_from_r0_to_nut_linklocal'			=> '    Send NA: R0 (Link0) -&gt; NUT (Link0) (link-local)',
	'na_from_r0_to_nut_global'			=> '    Send NA: R0 (Link0) -&gt; NUT (Link0) (global)',
	'MH_ANY'					=> '    Send MH Type=255: MN (LinkX) -&gt; NUT (Link0) (global)',
	'BE_NoBinding'					=> '    Recv BE Status=1: NUT (Link0) -&gt; MN\' (LinkY) (global)',
	'BE_UnknownType'				=> '    Recv BE Status=2: NUT (Link0) -&gt; MN (LinkX) (global)',
	'CoTI'						=> '    Send CoTI: MN\' (LinkY) -&gt; NUT (Link0) (global)',
	'CoTI_Piggyback'				=> '    Send CoTI (piggybacking): MN\' (LinkY) -&gt; NUT (Link0) (global)',
	'CoTI_Invalid_Checksum'				=> '    Send CoTI (invalid checksum): MN\' (LinkY) -&gt; NUT (Link0) (global)',
	'CoTI_HaO'					=> '    Send CoTI (include HaO): MN\' (LinkY) -&gt; NUT (Link0) (global)',
	'CoT'						=> '    Recv CoT: NUT (Link0) -&gt; MN\' (LinkY) (global)',
	'HoTI'						=> '    Send HoTI: MN (LinkX) -&gt; NUT (Link0) (global)',
	'HoTI_Piggyback'				=> '    Send HoTI (piggybacking): MN (LinkX) -&gt; NUT (Link0) (global)',
	'HoTI_Invalid_Checksum'				=> '    Send HoTI (invalid checksum): MN (LinkX) -&gt; NUT (Link0) (global)',
	'HoTI_HaO'					=> '    Send HoTI (include HaO): MN\' (LinkY) -&gt; NUT (Link0) (global)',
	'HoT'						=> '    Recv HoT: NUT (Link0) -&gt; MN (LinkX) (global)',
	'BU'						=> '    Send BU: MN\' (LinkY) -&gt; NUT (Link0) (global)',
	'BU_Home'					=> '    Send BU: MN (LinkX) -&gt; NUT (Link0) (global)',
	'BU_Piggyback'					=> '    Send BU (piggybacking): MN\' (LinkY) -&gt; NUT (Link0) (global)',
	'BU_Invalid_Checksum'				=> '    Send BU (invalid checksum): MN\' (LinkY) -&gt; NUT (Link0) (global)',
	'BA'						=> '    Recv BA: NUT (Link0) -&gt; MN\' (LinkY) (global)',
	'BA_Home'					=> '    Recv BA: NUT (Link0) -&gt; MN (LinkX) (global)',
	'echorequest_hao'				=> '    Send Echo Request w/ HaO: MN\' (LinkY) -&gt; NUT (Link0) (global)',
	'echoreply_rh'					=> '    Recv Echo Reply w/ RH: NUT (Link0) -&gt; MN\' (LinkY) (global)',
);

################################################################
%nd = (
	'ns_from_nut_to_r0_multicast_global'		=> 'na_from_r0_to_nut_global',
	'ns_from_nut_to_r0_unicast_global'		=> 'na_from_r0_to_nut_global',
	'ns_from_nut_to_r0_unicast_sll_global'		=> 'na_from_r0_to_nut_global',
	'ns_from_nut_to_r0_multicast_linklocal'		=> 'na_from_r0_to_nut_linklocal',
	'ns_from_nut_to_r0_unicast_linklocal'		=> 'na_from_r0_to_nut_linklocal',
	'ns_from_nut_to_r0_unicast_sll_linklocal'	=> 'na_from_r0_to_nut_linklocal',
	'rs_from_nut'					=> 'ra_from_r0',
	'rs_from_nut_sll'				=> 'ra_from_r0',
	'ra_from_nut'					=> 'ignore',
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

	my $NutType = $V6evalTool::NutDef{'Type'};
	my %ret = ();

	if($NutType eq 'host') {
		vSend($Link, 'ra_from_r0');
		vSleep(3);
	}

	vClear($Link);
	vSend($Link, 'ereq_from_hoa_to_nut_global');

	for(my $d = 0; $d < $vrecv_loop; $d ++) {
		my $recv = '';
		my $send = '';

		%ret = vRecv($Link, $vrecv_wait, 0, 0, sort(keys(%nd)), 'erep_from_nut_to_hoa_global');

		while(($recv, $send) = each(%nd)) {
			if($ret{'recvFrame'} eq $recv) {
				if($send ne 'ignore') {
					vSend($Link, $send);
				}

				$d --;
				last;
			}
		}

		if($ret{'recvFrame'} eq 'erep_from_nut_to_hoa_global') {
			return(0);
		}
	}

	return(-1);
}

#
# MIP6_CoT()
#
################################################################
sub MIP6_CoT($) {
	my ($Link) = @_;

	my %ret = ();

	vClear($Link);

	vSend($Link, 'CoTI');

	for(my $d = 0; $d < $vrecv_loop; $d ++) {
		my $recv = '';
		my $send = '';

		%ret = vRecv($Link, $vrecv_wait, 0, 0, sort(keys(%nd)), 'CoT');

		while(($recv, $send) = each(%nd)) {
			if($ret{'recvFrame'} eq $recv) {
				if($send ne 'ignore') {
					vSend($Link, $send);
				}

				$d --;
				last;
			}
		}

		if($ret{'recvFrame'} eq 'CoT') {
			return(0);
		}
	}

	return(-1);
}

#
# MIP6_HoT()
#
################################################################
sub MIP6_HoT($) {
	my ($Link) = @_;

	my %ret = ();

	vClear($Link);

	vSend($Link, 'HoTI');

	for(my $d = 0; $d < $vrecv_loop; $d ++) {
		my $recv = '';
		my $send = '';

		%ret = vRecv($Link, $vrecv_wait, 0, 0, sort(keys(%nd)), 'HoT');

		while(($recv, $send) = each(%nd)) {
			if($ret{'recvFrame'} eq $recv) {
				if($send ne 'ignore') {
					vSend($Link, $send);
				}

				$d --;
				last;
			}
		}

		if($ret{'recvFrame'} eq 'HoT') {
			return(0);
		}
	}

	return(-1);
}

#
# MIP6_NoResponse()
#
################################################################
sub MIP6_NoResponse($$) {
	my ($Link, $vsend) = @_;

	my %ret = ();
	my $count = 0;

	vClear($Link);

	vSend($Link, $vsend);

	for(my $d = 0; $d < $vrecv_loop; $d ++) {
		my $recv = '';
		my $send = '';

		%ret = vRecv($Link, $vrecv_wait, 0, 0, sort(keys(%nd)));
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

		if($count) {
			return(-1);
		}
	}

	return(0);
}

#
# MIP6_ReturnRoutability()
#
################################################################
sub MIP6_ReturnRoutability($) {
	my ($Link) = @_;

	my %rr = (
		'status'		=> 0,
		'HoT.Index'		=> '0',
		'HoT.KeygenNonce'	=> '0000000000000000',
		'CoT.Index'		=> '0',
		'CoT.KeygenNonce'	=> '0000000000000000',
	);

	my %ret = ();
	my %frames = ('HoT' => 'HoT', 'CoT' => 'CoT');

	vClear($Link);

	vSend($Link, 'HoTI', 'CoTI');

	for(my $d = 0; $d < $vrecv_loop; $d ++) {
		my $recv = '';
		my $send = '';

		%ret = vRecv($Link, $vrecv_wait, 0, 0, sort(keys(%nd)), sort(keys(%frames)));

		while(($recv, $send) = each(%nd)) {
			if($ret{'recvFrame'} eq $recv) {
				if($send ne 'ignore') {
					vSend($Link, $send);
				}

				$d --;
				last;
			}
		}

		if($ret{'recvFrame'} eq 'HoT') {
			delete($frames{'HoT'});
			$d --;

			my $base = 'Frame_Ether.Packet_IPv6.Hdr_MH_HoT';

			$rr{'HoT.Index'}	= $ret{"$base.Index"};
			$rr{'HoT.KeygenNonce'}	= $ret{"$base.KeygenNonce"};

			unless(defined($frames{'CoT'})) {
				last;
			}
		}

		if($ret{'recvFrame'} eq 'CoT') {
			delete($frames{'CoT'});
			$d --;

			my $base = 'Frame_Ether.Packet_IPv6.Hdr_MH_CoT';

			$rr{'CoT.Index'}	= $ret{"$base.Index"};
			$rr{'CoT.KeygenNonce'}	= $ret{"$base.KeygenNonce"};

			unless(defined($frames{'HoT'})) {
				last;
			}
		}
	}

	if(defined($frames{'HoT'}) || defined($frames{'CoT'})) {
		$rr{'status'} = -1;
	}

	return(%rr);
}

#
# MIP6_RR_Home()
#
################################################################
sub MIP6_RR_Home($) {
	my ($Link) = @_;

	my %rr = (
		'status'		=> 0,
		'HoT.Index'		=> '0',
		'HoT.KeygenNonce'	=> '0000000000000000',
		'CoT.Index'		=> '0',
		'CoT.KeygenNonce'	=> '0000000000000000',
	);

	my %ret = ();

	vClear($Link);

	vSend($Link, 'HoTI');

	for(my $d = 0; $d < $vrecv_loop; $d ++) {
		my $recv = '';
		my $send = '';

		%ret = vRecv($Link, $vrecv_wait, 0, 0, sort(keys(%nd)), 'HoT');

		while(($recv, $send) = each(%nd)) {
			if($ret{'recvFrame'} eq $recv) {
				if($send ne 'ignore') {
					vSend($Link, $send);
				}

				$d --;
				last;
			}
		}

		if($ret{'recvFrame'} eq 'HoT') {
			delete($frames{'HoT'});

			my $base = 'Frame_Ether.Packet_IPv6.Hdr_MH_HoT';

			$rr{'HoT.Index'}	= $ret{"$base.Index"};
			$rr{'HoT.KeygenNonce'}	= $ret{"$base.KeygenNonce"};
			$rr{'CoT.Index'}	= $ret{"$base.Index"};
			$rr{'CoT.KeygenNonce'}	= $ret{"$base.KeygenNonce"};

			return(%rr);
		}
	}

	$rr{'status'} = -1;
	return(%rr);
}

#
# MIP6_ProcessingBindings()
#
################################################################
sub MIP6_ProcessingBindings($$$$%) {
	my ($Link, $sn, $a, $lt, %rr) = @_;

	my %ret = ();

	my $cpp  = "-DHOINDEX=$rr{'HoT.Index'} ";
	   $cpp .= "-DCOINDEX=$rr{'CoT.Index'} ";
	   $cpp .= "-DHOKEYGENTOKEN=\\\"$rr{'HoT.KeygenNonce'}\\\" ";
	   $cpp .= "-DCOKEYGENTOKEN=\\\"$rr{'CoT.KeygenNonce'}\\\" ";

	if($sn) {
		$cpp .= "-DSEQ_BU=$sn ";
		$cpp .= "-DSEQ_BA=$sn ";
	}

	if($a) {
		$cpp .= "-DACKNOWLEDGE=$a ";
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
			my $base = 'Frame_Ether.Packet_IPv6.Hdr_MH_BA';
			my $lifetime = $ret{"$base.Lifetime"};

			if(($lt) && (4 * $lifetime > 420)) {
				vLogHTML('<FONT COLOR="#FF0000">Lifetime is grater than MAX_RR_BINDING_LIFE</FONT><BR>');
				exit($V6evalTool::exitFail);
			}

			return(0);
		}
	}

	return(-1);
}

#
# MIP6_ProcessingBindingsNoAck()
#
################################################################
sub MIP6_ProcessingBindingsNoAck($$$$%) {
	my ($Link, $sn, $a, $lt, %rr) = @_;

	my %ret = ();
	my $count = 0;
	my $got_ba = 0;

	my $cpp  = "-DHOINDEX=$rr{'HoT.Index'} ";
	   $cpp .= "-DCOINDEX=$rr{'CoT.Index'} ";
	   $cpp .= "-DHOKEYGENTOKEN=\\\"$rr{'HoT.KeygenNonce'}\\\" ";
	   $cpp .= "-DCOKEYGENTOKEN=\\\"$rr{'CoT.KeygenNonce'}\\\" ";

	if($sn) {
		$cpp .= "-DSEQ_BU=$sn ";
		$cpp .= "-DSEQ_BA=$sn ";
	}

	if($a) {
		$cpp .= "-DACKNOWLEDGE=$a ";
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
			$got_ba ++;

			my $base = 'Frame_Ether.Packet_IPv6.Hdr_MH_BA';
			my $lifetime = $ret{"$base.Lifetime"};

			if(($lt) && (4 * $lifetime > 420)) {
				vLogHTML('<FONT COLOR="#FF0000">Lifetime is grater than MAX_RR_BINDING_LIFE</FONT><BR>');
				exit($V6evalTool::exitFail);
			}

			last;
		}

		if($count) {
			vLogHTML('<FONT COLOR="#FF0000">Recv unexpect packets</FONT><BR>');
			exit($V6evalTool::exitFail);
		}
	}

	if($got_ba) {
		return(-1);
	}

	return(0);
}

#
# MIP6_DeleteBindingHome()
#
################################################################
sub MIP6_DeleteBindingHome($$$$%) {
	my ($Link, $sn, $a, $lt, %rr) = @_;

	my %ret = ();

	my $cpp  = "-DHOINDEX=$rr{'HoT.Index'} ";
	   $cpp .= "-DCOINDEX=$rr{'CoT.Index'} ";
	   $cpp .= "-DHOKEYGENTOKEN=\\\"$rr{'HoT.KeygenNonce'}\\\" ";
	   $cpp .= "-DCOKEYGENTOKEN=\\\"$rr{'CoT.KeygenNonce'}\\\" ";

	if($sn) {
		$cpp .= "-DSEQ_BU=$sn ";
		$cpp .= "-DSEQ_BA=$sn ";
	}

	if($a) {
		$cpp .= "-DACKNOWLEDGE=$a ";
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

		%ret = vRecv($Link, $vrecv_wait, 0, 0, sort(keys(%nd)), 'BA_Home');

		while(($recv, $send) = each(%nd)) {
			if($ret{'recvFrame'} eq $recv) {
				if($send ne 'ignore') {
					vSend($Link, $send);
				}

				$d --;
				last;
			}
		}

		if($ret{'recvFrame'} eq 'BA_Home') {
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

	vSend($Link, 'echorequest_hao');

	for(my $d = 0; $d < $vrecv_loop; $d ++) {
		my $recv = '';
		my $send = '';

		%ret = vRecv($Link, $vrecv_wait, 0, 0, sort(keys(%nd)), 'echoreply_rh');

		while(($recv, $send) = each(%nd)) {
			if($ret{'recvFrame'} eq $recv) {
				if($send ne 'ignore') {
					vSend($Link, $send);
				}

				$d --;
				last;
			}
		}

		if($ret{'recvFrame'} eq 'echoreply_rh') {
			return(0);
		}
	}

	return(-1);
}

#
# MIP6_CheckNoBindingCache()
#
################################################################
sub MIP6_CheckNoBindingCache($) {
	my ($Link) = @_;

	my %ret = ();
	my $got_be = 0;
	my $count = 0;

	vClear($Link);

	vSend($Link, 'echorequest_hao');

	for(my $d = 0; $d < $vrecv_loop; $d ++) {
		my $recv = '';
		my $send = '';

		%ret = vRecv($Link, $vrecv_wait, 0, 0, sort(keys(%nd)), 'BE_NoBinding');
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

		if($ret{'recvFrame'} eq 'BE_NoBinding') {
			$got_be ++;
			$count --;
		}

		if($count) {
			vLogHTML('<FONT COLOR="#FF0000">Recv unexpect packets</FONT><BR>');
			exit($V6evalTool::exitFail);
		}

		if($got_be) {
			last;
		}
	}

	unless($got_be) {
		return(-1);
	}

	for(my $d = 0; $d < $vrecv_loop; $d ++) {
		my $recv = '';
		my $send = '';

		%ret = vRecv($Link, $vrecv_wait, 0, 0, sort(keys(%nd)));
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

		if($count) {
			vLogHTML('<FONT COLOR="#FF0000">Recv unexpect packets</FONT><BR>');
			exit($V6evalTool::exitFail);
		}
	}

	return(0);
}

#
# MIP6_BE_UnknownType()
#
################################################################
sub MIP6_BE_UnknownType($) {
	my ($Link) = @_;

	my %ret = ();
	my $got_be = 0;
	my $count = 0;

	vClear($Link);

	vSend($Link, 'MH_ANY');

	for(my $d = 0; $d < $vrecv_loop; $d ++) {
		my $recv = '';
		my $send = '';

		%ret = vRecv($Link, $vrecv_wait, 0, 0, sort(keys(%nd)), 'BE_UnknownType');
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

		if($ret{'recvFrame'} eq 'BE_UnknownType') {
			$got_be ++;
			$count --;
		}

		if($count) {
			vLogHTML('<FONT COLOR="#FF0000">Recv unexpect packets</FONT><BR>');
			exit($V6evalTool::exitFail);
		}

		if($got_be) {
			last;
		}
	}

	unless($got_be) {
		return(-1);
	}

	for(my $d = 0; $d < $vrecv_loop; $d ++) {
		my $recv = '';
		my $send = '';

		%ret = vRecv($Link, $vrecv_wait, 0, 0, sort(keys(%nd)));
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

		if($count) {
			vLogHTML('<FONT COLOR="#FF0000">Recv unexpect packets</FONT><BR>');
			exit($V6evalTool::exitFail);
		}
	}

	return(0);
}

#
# MIP6_UpdateCoA()
#
################################################################
sub MIP6_UpdateCoA($$) {
	my ($file, $define) = @_;

	unless(defined(open(WORK, ">$file"))) {
		vLogHTML('<FONT COLOR="#FF0000">Can\'t update CoA</FONT><BR>');
		exit($V6evalTool::exitFatal);
	}

	print WORK "#define CAREOFADDR\t$define\n";

	close(WORK);

	vCPP('');

	return;
}

#
# MIP6_BU_NoResponse()
#
################################################################
sub MIP6_BU_NoResponse($$$$$%) {
	my ($Link, $vsend, $sn, $a, $lt, %rr) = @_;

	my %ret = ();

	my $cpp  = "-DHOINDEX=$rr{'HoT.Index'} ";
	   $cpp .= "-DCOINDEX=$rr{'CoT.Index'} ";
	   $cpp .= "-DHOKEYGENTOKEN=\\\"$rr{'HoT.KeygenNonce'}\\\" ";
	   $cpp .= "-DCOKEYGENTOKEN=\\\"$rr{'CoT.KeygenNonce'}\\\" ";

	if($sn) {
		$cpp .= "-DSEQ_BU=$sn ";
		$cpp .= "-DSEQ_BA=$sn ";
	}

	if($a) {
		$cpp .= "-DACKNOWLEDGE=$a ";
	}

	if($lt) {
		$cpp .= "-DLIFETIME=$lt ";
	}

	vCPP($cpp);

	vClear($Link);

	vSend($Link, $vsend);

	for(my $d = 0; $d < $vrecv_loop; $d ++) {
		my $recv = '';
		my $send = '';

		%ret = vRecv($Link, $vrecv_wait, 0, 0, sort(keys(%nd)));
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

		if($count) {
			return(-1);
		}
	}

        return(0);
}

#
# MIP6_InvalidSequence()
#
################################################################
sub MIP6_InvalidSequence($$$$$%) {
	my ($Link, $sn0, $sn1, $a, $lt, %rr) = @_;

	my %ret = ();

	$pktdesc{'BA'} = '    Recv BA Status=135: NUT (Link0) -&gt; MN\'\' (LinkZ) (global)';

	my $cpp  = "-DHOINDEX=$rr{'HoT.Index'} ";
	   $cpp .= "-DCOINDEX=$rr{'CoT.Index'} ";
	   $cpp .= "-DHOKEYGENTOKEN=\\\"$rr{'HoT.KeygenNonce'}\\\" ";
	   $cpp .= "-DCOKEYGENTOKEN=\\\"$rr{'CoT.KeygenNonce'}\\\" ";
	   $cpp .= "-DSTATUS_BA=135 ";

	if($sn0) {
		$cpp .= "-DSEQ_BU=$sn1 ";
	}

	if($sn1) {
		$cpp .= "-DSEQ_BA=$sn0 ";
	}

	if($a) {
		$cpp .= "-DACKNOWLEDGE=$a ";
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
# MIP6_NotHA()
#
################################################################
sub MIP6_NotHA($$$$%) {
	my ($Link, $sn, $a, $lt, %rr) = @_;

	my %ret = ();

	$pktdesc{'BA'} = '    Recv BA Status=131: NUT (Link0) -&gt; MN\' (LinkY) (global)';

	my $cpp  = "-DHOINDEX=$rr{'HoT.Index'} ";
	   $cpp .= "-DCOINDEX=$rr{'CoT.Index'} ";
	   $cpp .= "-DHOKEYGENTOKEN=\\\"$rr{'HoT.KeygenNonce'}\\\" ";
	   $cpp .= "-DCOKEYGENTOKEN=\\\"$rr{'CoT.KeygenNonce'}\\\" ";
	   $cpp .= "-DHOMEREGISTRATION=1 ";
	   $cpp .= "-DSTATUS_BA=131 ";

	if($sn) {
		$cpp .= "-DSEQ_BU=$sn ";
		$cpp .= "-DSEQ_BA=$sn ";
	}

	if($a) {
		$cpp .= "-DACKNOWLEDGE=$a ";
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

