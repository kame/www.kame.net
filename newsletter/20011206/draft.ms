.\"
.ds LF draft-keiichi-mobileip-kame-implementation-00.txt
.ds CF
.ds RF [Page %]
.\"
.ds LH DRAFT
.ds CH KAME Mobile IPv6 Implementation
.ds RH Dec. 7, 2001
.\"
.hy 0			\" don't hyphenate I-Ds
.ad l
.nf
DRAFT                                                      Keiichi Shima
                                           Internet Initiative Japan Inc.
                                                        December 7, 2001
.sp 2
.ce 2
KAME Mobile IPv6 Implementation notes
.fi
.sp 2
.SH
Abstract
.LP
The KAME Project is now developping Mobile IPv6 stack on its IPv6
stack.  We will describe our implementation design and some
comments about the spec.
.SH
Status of this Memo
.LP
This document is a supplemental reference for those implementing MIP6.
.bp\"foo
.\" --------------------------------------------------------------------
.SH
Table of Contents
.LP
.nf
.ta 7.0i
.so draft.toc
.fi
.bp\"foo
.\" --------------------------------------------------------------------
.N1 "Overview"
.LP
KAME/MIP6 is based on the three implementations (Ericsson, NEC, Keio
Univ.) those have been built on the KAME IPv6 protocol stack before.
We are trying to utilize the merits of those implementations and
provide one concrete MIP6 stack for the KAME IPv6 stack.  Since the
code is under developing, the information written in this document may
be outdated, but I think this is still useful to understand our
implementation.

The KAME/MIP6 supports CN, HA and MN functions.  The base
specification is the current one.  At this point, the specification is
draft-ietf-mobileip-ipv6-15.txt.
.\" --------------------------------------------------------------------
.N1 "KAME/MIP6 implementation note"
.LP
.\" --------------------------------------------------------------------
.N2 "Subnet in KAME/MIP6"
.LP
MIP6 is designed for the node that is moving from one subnet to
another subnet without closing existing connections.  When the node
moves from one subnet to other subnet, we think the node has moved.
MIP6 spec doesn't define the notation of subnet.  KAME/MIP6 defines
the word subnet as 'the group of prefixes and routers those have some
relationships with each other'.  See the following example.
.LP
.DS 0
Router R1 announcing Prefix P1, Prefix P2
Router R2 announcing Prefix P3, Prefix P4
Router R3 announcing Prefix P1, Prefix P5
Router R4 announcing Prefix P4, Prefix P6
Router R5 announcing Prefix P7
.DE
.LP
In this case, we have 5 routers (R1...R5) and 7 prefixes (P1...P7).
By our definition of subnet, we can group them into 3 subnets.
.LP
.DS 0
Subnet S1 (Router R1, R3) (Prefix P1, P2, P4)
Subnet S2 (Router R2, R4) (Prefix P3, P4, P6)
Subnet S3 (Router R5) (Prefix P7)
.DE
.LP
Router R1 and R3 are in the same subnet because those routers share
the prefix P1.  Similarly, Router R2 and R4 are the same subnet.
Router R5 is only router in the subnet S3 because it doesn't share any
information with other router.  KAME/MIP6 treats these 3 subnet as
different ones, even if they are physically on the same wire.
.\" --------------------------------------------------------------------
.N2 "CoA selection in KAME/MIP6"
.LP
The KAME/MIP6 stack re-selects the CoA when the states of prefixes
have changed.  The KAME IPv6 stack maintain all the received prefixes.
The point is that the KAME stack has one more additional state
information of the prefix than the specification defines.  The
stateless address auto-configuration specification defines some states
of IPv6 addresses.  In this paper, we focus two states, one is
PREFERRED and the other is DEPRECATED.  These states are derived from
the prefix states.  If the prefix has the preferred lifetime left, the
address derived from the prefix is also PREFERRED.  If the prefix has
only the valid lifetime left and the preferred lifetime expired, the
address is DEPRECATED.  In addition to those states, the KAME IPv6
stack has a DETACHED address state.  If the prefix has the valid
lifetime left but the advertising router of the prefix seems
unreachable, the prefix is marked as detached.  The address derived
from the detached prefix is also marked as DETACHED.  Following are
the algorithm of KAME/MIP6 CoA selection.
.LP
1. find addresses those are not ANYCAST, DUPLICATED, DEPRECATED and
DETACHED.
.LP
2. if the previous CoA is one of addresses found during the procedure
1, continue using the same address as the CoA.
.LP
3. if the previous CoA is not found, select one address from addresses
found during the procedure 1.
.LP
Current implementation pick the last found address as a new CoA.  We
can introduce some policy based address selection mechanism in the
selection procedure.  For example, we may want to mark the Ethernet
interfaces as perferrable than the cellular interfaces.
.LP
This CoA selection algorithm is the key of the movement detection
algorithm of the KAME/MIP6.  The movement detection is described in
the next section.
.\" --------------------------------------------------------------------
.N3 "Comment about the spec"
.LP
We have no mechanism to invalidate the old prefix.  'Old' means, it
has preferred lifetime left but, no advertising router on the current
subnet.  This happens when we change the network.  We have no way to
determine if we can use the old (in KAME sense, detached) address.
Should the autoconf spec note about this?
.\" --------------------------------------------------------------------
.N2 "Movement detaction in KAME/MIP6"
.LP
While many implementations check advertised prefixes and default
router change to detect the node movement, KAME/MIP6 only checks the
change of its CoA.  As already described, KAME/MIP6 CoA re-selection
is done whenever the states of prefixes change.  Therefore, the change
of the CoA in our implementation means the old prefix of the old CoA
is no longer usable.  It is not important whether the node moves from
one wire to another wire.  The point is the node always selects its
CoA based on the states of the current usable prefixes and routers
those are advertising prefixes. Once the CoA has changed, we must
update binding regardless of moving from one real wire to another.
.LP
When KAME/MIP6 detects movement (this means that KAME/MIP6 detects CoA
change), KAME/MIP6 start movement processing.  For example, sending
binding updates to each destination node of binding update list.
.\" --------------------------------------------------------------------
.N2 "One more note about CoA selection"
.LP
Our algorithm may detect wrong location in the following case.
.DS 0
    ----+--------                   ----+-------
        |                               |
      +-+--+                          +-+--+
      | R1 |                          | R2 |
      +-+--+ Prefix P1                +-+--+ Prefix P2
        |                               |
    ----+---------------+---------------+---- home wire
                        |
                      +----+ home prefix == P1
                      | MN |
                      +----+
.DE
There are two routers (R1, R2) in the home wire.  Router R1 announces
Prefix P1 and R2 announces P2.  By definition of our subnet, there are
two subnets on the wire.
.DS 0
Subnet S1 (Router R1) (Prefix P1)
Subnet S2 (Router R2) (Prefix P2)
.DE
Under this condition, if we specify only one prefix as a home prefix,
we can't determine whether we are home or not.  In this network, both
P1 and P2 are valid.  We can use both addresses derived from each
prefix.
.LP
Now, assume we select P1 as a home prefix.  If we select CoA derived
from P2, we determine that we are on the foreign network.  But in
fact, we are home too.  MN will start configuring addresses and get
two addresses.  One is from P1 and the other is from P2.  Next, MN
sends a binding update to make a home registration but it fails
because HA fails DAD for the MN home address.  In this case, MN should
determine that it is home.
.LP
This problem can be easily avoided by preferring the home address
in selecting a new CoA.  (Not implemented yet.)
.LP
(Current implementation have bugs in handing this situation, so, this
doesn't work with such a network described above.)
.\" --------------------------------------------------------------------
.N2 "Multiple homelinks"
.LP
The KAME/MIP6 try to support multiple homelinks.  We can specify both
office and home network as a home link.  We can use the best address
(if we are office, office home address, and vice versa).
.\" --------------------------------------------------------------------
.N2 "Router Identifier Problem"
.LP
As many folks have said already, our implementation also have a router
identifier problem.  If different two routers have same link-local
address, we think those two routers are the same router.  This problem
can be avoided by using router global address.  But, since the global
address is included in the prefix infomation option of the router
advertisement, we must process the prefix information option twice.
First time for finding a global address, second time for grouping
received prefixes into subnet groups (and also, ordinally prefix
information option processing).
.\" --------------------------------------------------------------------
.N3 "Comment about the spec"
.LP
Do we need another identifier other than the link-local address?  Or
this is only the operational problem?
.\" --------------------------------------------------------------------
.N2 "The wrong source address in the ICMP error payload"
.LP
In our implementation, the home address and the CoA is exchanged in
the destination options header processing routine.  If we encounter
some errors after this point, it produces the ICMP error packet with a
payload that include the original IPv6 packet with a wrong (excnanged)
source address.  To avoid this problem, we consider two different
mechanisms.  One is to recover a correct source address at all the
points the process are needed.  The other is not to exchange the home
address and the CoA in the destination options header processing and
remain the CoA in a IPv6 source address field.  We implemented both
mechanisms and decided to adopt the former.  In the former mechanism,
the point to recover the original source address is only the function
which generates ICMP error packet.  Other parts of the code seems to
have no need to restore the source address.  While, the latter
mechanism requires tens to a hundred code fixes those refer the IPv6
source address field.
.N3 "Comments"
.LP
We select the former mechanism because it require only a small fix of
the existing code.  But we should reconsider if the former mechanism
is better than the latter mechanism later.  It is natural to keep the
IPv6 packet not modified.  If we meet some other situations like ICMP6
error in the future, we must make a code that recover the original
source address again as we have done in the current icmp6error
routine.  Is it really ad-hoc isn't it?
.\" --------------------------------------------------------------------
.N2 "Security mechanism is not implemented yet"
.LP
We plan to implement some weak authentication mechanisms.  Currently
we are investigating which one is the best.
.\" --------------------------------------------------------------------
.N1 "References"
.IP "[MIP6]"
David B. Johnson, Charles Perkins, Mobility Support in IPv6,
draft-ietf-mobileip-ipv6-15.txt, Nov 2001
.IP "[RFC2462]
S. Thomson, T. Narten, IPv6 Stateless Address Autoconfiguration,
RFC2462, Dec 1998
.\" --------------------------------------------------------------------
.N1 "Current status"
.LP
Followings are the todo list and the current status for each functions
(MN, HA, CN).  You can always get the latest information from the KAME
Project (http://www.kame.net/).
.IP "  -" 4
todo
.IP "    -" 6
merge nd_prefix/nd_defrouter structure and mip6_prefix/mip6_ha structure.
merge home address configuration and stateless auto-configuration.
.IP "" 6
current our implementation defines special prefix and home agent
structures for MIP6 code.  These structures are essentially identical
to nd_prfix and nd_defrouter structures.  should merge them.
.IP "    -" 6
define the behavior of the socket API for home addresses.
.IP "" 6
we do not implement any MIP6 related socket APIs yet.
.IP "    -" 6
security mechanism.
.IP "" 6
There are many candidates now to secure MIP6 processing.  we are now
comparing them.
.IP "    -" 6
mobile prefix advertisement.
.IP "    -" 6
complete dynamic home agent discovery. (implement user-land daemon?)
.IP "    -" 6
rate limit (many places).
.IP "    -" 6
homeagent info handling.
.IP "    -" 6
ICMP against tunneled packet handling.
.IP "    -" 6
registration to the old AR.
.IP "    -" 6
path mtu discovery when triangle routing.
.IP "    -" 6
some timeout routines.
.IP "    -" 6
other OSes support.
.IP "    -" 6
draft-13/draft-15 (or newer) full support.
.IP "    -" 6
may be others.
.IP "  -" 4
MN part implemented functions
.IP "    -" 6
movement detection by the CoA change.
.IP "    -" 6
binding update/home registration.
.IP "    -" 6
dynamic home agent discovery.
.IP "    -" 6
NA when returning to home.
.IP "  -" 4
CN part implemented functions
.IP "    -" 6
receiving binding update.
.IP "    -" 6
insertion of a routing header.
.IP "    -" 6
sending binding requests.
.IP "  -" 4
HA part implemented functions
.IP "    -" 6
home registration.
.IP "    -" 6
encapsulate packets destined to MNs.
.IP "    -" 6
dynamic home agent discovery (partial).
.IP "    -" 6
dad for the MNs.
.\" --------------------------------------------------------------------
.N1 "Author's Address"
.DS
Keiichi Shima
Internet Initiative Japan Inc.
Edobori Center Bldg. 19F
2-1-1 Edobori, Nishi-ku, Osaka 550-0002, Japan
Email: keiichi@iij.ad.jp
.DE
