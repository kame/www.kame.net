###
### Utilities for stat-it
###
### Copyright (c) 1998 IMG SRC, Inc.
### Copyright (c) 1998 hayato.
### All rights reserved.
### 
### Redistribution and use in source and binary forms, with or without
### modification, are permitted provided that the following conditions
### are met:
### 
### 1. Redistributions of source code must retain the above copyright
###    notice, this list of conditions and the following disclaimer.
### 
### 2. Redistributions in binary form must reproduce the above
###    copyright notice, this list of conditions and the following
###    disclaimer in the documentation and/or other materials provided
###    with the distribution.
### 
### 3. All advertising materials mentioning features or use of this
###    software must displays the following acknowledgment:
###    "This product includes software developed by hayato and
###    IMG SRC, Inc."
### 
### 4. The names "stat-it" must not be used to endorse or promote
###    products derived from this software without prior written
###    permission. For written permission, please contact
###    stat-it@imgsrc.co.jp.
### 
### 5. Products derived from this software may not be called "stat-it"
###    nor may "stat-it" appear in their names without prior written
###    permission of hayato and IMG SRC, Inc.
### 
### THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS''
### AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
### TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
### PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHORS
### OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
### SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
### LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF
### USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
### AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
### LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
### ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
### POSSIBILITY OF SUCH DAMAGE.
###
### $Id: view.pl,v 1.1 2001/04/17 03:41:54 itojun Exp $

$htmlTitle="Stat-it $version";
$copyright=     "Copyright (c) 1998 IMG SRC,Inc.";
$copyright.="<BR>Copyright (c) 1998 hayato.";
$copyright.="<BR>All rights reserved.";

$HTMLMonthMode=0;
$HTMLCgiError=0;
$HTMLDateInvalid=0;

$HTMLMultiCol=0;
$HTMLStatTable=0;
$HTMLTimeTable=0;
$HTMLUrlTable=0;
$HTMLHostTable=0;
$HTMLTitleDisplay=1;
$HTMLAccessListMax=100;


$htmlBodyBgColor="#ffffff";
$htmlBodyText="#333333";
$htmlBodyLink="#003333";
$htmlBodyAlink="#003333";
$htmlBodyVlink="#003333";

$htmlBody="<BODY BGCOLOR=\"$htmlBodyBgColor\" TEXT=\"$htmlBodyText\" LINK=\"$htmlBodyLink\" ALINK=\"$htmlBodyAlink\" VLINK=\"$htmlBodyVlink\">";

$htmlTableBgColor="#EEEEEE";
$htmlFontColor1="#666666";    # access bytes color

$fontFace="Helvetica,Arial,Verdana";
$fontSize="2";

$htmlFont="<FONT FACE=\"$fontFace\" SIZE=\"$fontSize\">";
$htmlFont2="<FONT FACE=\"$fontFace\" SIZE=\"3\">";
$htmlFontEnd="</FONT>";

$imgDir="";
$imgAccess="${imgDir}accessBox2.gif";
$imgByte="${imgDir}byteBox2.gif";
$imgSpace="${imgDir}clear.gif";

$htmlCgiOption="";
$htmlCgiMethod="GET";

$graphScale=250;


#####################
#
# print default HTML
#    called if 'get' is not defined.
#    usually, display title page 
#
sub printHTMLdefault {

&printHttpHeader();
&printHtmlHeader();

print<<"HTMLBODY";
$htmlBody

<CENTER>
<br><br><br><br><br><br>
<TABLE BORDER=0 cellspacing="0" cellpaddingh="0" WIDTH="430" HEIGHT="250">
<TR><TD ALIGN="center" VALIGN="top" WIDTH=205>

<IMG SRC="${imgDir}stat-it.gif" WIDTH="200" HEIGHT="99" BORDER="0"><BR>

<BR>

<BR>
<FONT FACE="$fontFace">
<FORM METHOD="$htmlCgiMethod" ACTION="$thisUrl">
<INPUT TYPE="hidden" NAME="get" VALUE="yes">
<INPUT TYPE="hidden" NAME="multicol" VALUE="on">
<INPUT TYPE="hidden" NAME="stat" VALUE="on">
<INPUT TYPE="hidden" NAME="time" VALUE="on">
<INPUT TYPE="hidden" NAME="url" VALUE="on">
<INPUT TYPE="hidden" NAME="host" VALUE="on">
<INPUT TYPE="text" NAME="year" SIZE=4 VALUE="$nowYear">/
<INPUT TYPE="text" NAME="month" SIZE=2 VALUE="$nowMon">/
<INPUT TYPE="text" NAME="day" SIZE=2 VALUE="$nowDay">
<BR>
<INPUT TYPE="checkbox" NAME="tsv">TSV download

<BR>
<INPUT TYPE="submit" VALUE="Stat-it">

</FORM>
</TD>
<TD ALIGN="CENTER" VALIGN="top" WIDTH="225">
<IMG SRC="${imgDir}stat_text.gif" WIDTH="220" HEIGHT="178" BORDER="0">
</TD>
</TR>
</TABLE>
<BR>

$copyright


</FONT>

</CENTER>


</BODY>
</HTML>
HTMLBODY

}

#
# print HTML daily log
#
sub printHTMLday {
local($day,$mon,$year);
local($rc,$i,$a,$a1,$b,$b1,$a0);
local($w,$n,$i2,$rc2);
local($loopBegin,$loopEnd,$timeLoopEnd);
local($wholeAccess,$wholeBytes);

$day = "";
$mon = $nowMon;
$year = $nowYear;
$day = $cgiParams{'day'} if ($cgiParams{'day'} =~ /^[0-9]+$/);
$mon = $cgiParams{'month'} if ($cgiParams{'month'} =~ /^[0-9]+$/);
$year = $cgiParams{'year'} if ($cgiParams{'year'} =~ /^[0-9]+$/);

$HTMLMonthMode=1 if ($day eq "");



#
# check cgi parameters
#
if ($cgiParams{'multicol'} eq 'on') {
  $HTMLMultiCol = 1;
  $htmlCgiOption .= 'multicol=on&';
}
if ($cgiParams{'stat'} eq 'on') {
  $HTMLStatTable = 1;
  $htmlCgiOption .= 'stat=on&';
}
if ($cgiParams{'time'} eq 'on') {
  $HTMLTimeTable = 1;
  $htmlCgiOption .= 'time=on&';
}
if ($cgiParams{'url'} eq 'on') {
  $HTMLUrlTable = 1;
  $htmlCgiOption .= 'url=on&';
}
if ($cgiParams{'host'} eq 'on') {
  $HTMLHostTable = 1;
  $htmlCgiOption .= 'host=on&';
}
if ($cgiParams{'title'} eq 'off') {
  $HTMLTitleDisplay = 0;
}
if ($cgiParams{'accessmax'} =~ /^[0-9]+$/) {
  $HTMLAccessListMax = $cgiParams{'accessmax'};
  $htmlCgiOption .= "accessmax=$HTMLAccessListMax&";
}




&printHttpHeader();
&printHtmlHeader();
print "$htmlBody\n";


#
# pre process for time table
# 
if (&isDateValid($day,$mon,$year) == 0) {
  $HTMLCgiError = 1;
  $HTMLDateInvalid = 1;
}

if ($HTMLMonthMode) {
  if (($rc = &isExistCollection('',$mon,$year)) > 0) {
    &getMonthCollection($mon,$year);
  } elsif ($year < $nowYear || ($mon <= $nowMon && $year == $nowYear)) {
      &makeCollection();
      &getMonthCollection($mon,$year);
  } else {
      $dayAccessMax = $dayBytesMax = 1;
  }
} else {
  if (($rc = &isExistCollection($day,$mon,$year)) > 1) {
    &getDayCollection($day,$mon,$year);
  } elsif ($year < $nowYear || ($mon < $nowMon && $year == $nowYear) ||
    ($day <= $nowDay && $mon == $nowMon && $year == $nowYear)) {
    &makeCollection();
    &getDayCollection($day,$mon,$year);
  } else {
    $hourAccessMax = $hourBytesMax = 1;
  }
}

if ($HTMLMonthMode) {
  $dayBytesMax /= 1000;
  $loopBegin = 1;
  $loopEnd = $dayOfMonth[$mon - 1] + 1;
  if ($mon == 2) {
    $loopEnd++ if (&isLeapYear($year));
  }
  $loopEnd = 0 if ($dayCnt == 0);
} else {
  $hourBytesMax /= 1000;
  $loopBegin = 0;
  $loopEnd = 24;
  $loopEnd = 0 if ($hourCnt == 0);
}
$timeLoopEnd = $loopEnd;

  #
  # main content start
  #
  if ($HTMLMultiCol) {
    print "<TABLE BORDER=0 CELLPADDING=4 CELLSPACING=4>\n\n";
    print "<TR><TD VALIGN=top>\n";
  }

  if ($HTMLTitleDisplay) {
    print "<A HREF=\"$thisUrl\"><IMG SRC=\"${imgDir}stat-it2.gif\" WIDTH=180 HEIGHT=80 BORDER=0></A><BR>\n";
    print "<BR>\n";
    print "${htmlFont}$copyright$htmlFontEnd<BR><BR>\n";
  }

  # sub title
  if ($HTMLMonthMode) {
    print "${htmlFont2}monthly access statistics";
    print "<BR>" if ($HTMLMultiCol);
    print "&nbsp;($year/$mon)<BR><BR>$htmlFontEnd\n";
  } else {
    print "${htmlFont2}daily access statistics";
    print "<BR>" if ($HTMLMultiCol);
    print "&nbsp;(<A HREF=\"$thisUrl?${htmlCgiOption}get=yes&year=$year&month=$mon\">$year/$mon</A>/$day)<BR><BR>$htmlFontEnd\n";
}

  #
  # stat table
  #
  if (!$HTMLCgiError && $HTMLStatTable) {
    $wholeAccess = $wholeBytes = 0;
    if ($HTMLMultiCol) {
      print "<TABLE BORDER=0 CELLPADDING=0 CELLSPACING=1>\n";
    } else {
      print "<TABLE BGCOLOR=$htmlTableBgColor BORDER=0 CELLPADDING=0 CELLSPACING=1>\n";
    }
  print "<TR><TD WIDTH=80 NOWRAP>${htmlFont}condition$htmlFontEnd</TD><TD COLSPAN=2 ALIGN=center WIDTH=110>${htmlFont}access$htmlFontEnd</TD></TR>\n";
  for ($i = 0; $i < $statCnt; $i++) {
    $wholeAccess += $statAccess[$i];
    $wholeBytes += $statBytes[$i];
    $b1 = &getBytePostfix($statBytes[$i]);
    $rc2 = 0;
    if ($statCode[$i] > 99 && $statCode[$i] < 200) {
      $n = "($statCode[$i])"; $rc2 = 1;
    } elsif ($statCode[$i] == 200) {
      $n = "Success"; $rc2 = 1;
    } elsif ($statCode[$i] == 201) {
      $n = "Created"; $rc2 = 1;
    } elsif ($statCode[$i] == 202) {
      $n = "Accepted"; $rc2 = 1;
    } elsif ($statCode[$i] == 203) {
      $n = "Non-Authoritative Information"; $rc2 = 1;
    } elsif ($statCode[$i] == 204) {
      $n = "No Content"; $rc2 = 1;
    } elsif ($statCode[$i] == 205) {
      $n = "Reset Content"; $rc2 = 1;
    } elsif ($statCode[$i] == 206) {
      $n = "Partial Content"; $rc2 = 1;
    } elsif ($statCode[$i] > 199 && $statCode[$i] < 300) {
      $n = "($statCode[$i])"; $rc2 = 1;
    } elsif ($statCode[$i] == 300) {
      $n = "Multiple Choices"; $rc2 = 1;
    } elsif ($statCode[$i] == 301) {
      $n = "Moved Permanently"; $rc2 = 1;
    } elsif ($statCode[$i] == 302) {
      $n = "Moved Temporarily"; $rc2 = 1;
    } elsif ($statCode[$i] == 303) {
      $n = "See Other"; $rc2 = 1;
    } elsif ($statCode[$i] == 304) {
      $n = "Not Modified"; $rc2 = 1;
    } elsif ($statCode[$i] == 305) {
      $n = "Use Proxy"; $rc2 = 1;
    } elsif ($statCode[$i] > 299 && $statCode[$i] < 400) {
      $n = "($statCode[$i])"; $rc2 = 1;
    } elsif ($statCode[$i] == 400) {
      $n = "Bad Request"; $rc2 = 1;
    } elsif ($statCode[$i] == 401) {
      $n = "Unauthorized"; $rc2 = 1;
    } elsif ($statCode[$i] == 402) {
      $n = "Payment Required"; $rc2 = 1;
    } elsif ($statCode[$i] == 403) {
      $n = "Forbidden"; $rc2 = 1;
    } elsif ($statCode[$i] == 404) {
      $n = "Not Found"; $rc2 = 1;
    } elsif ($statCode[$i] == 405) {
      $n = "Method Not Allowed"; $rc2 = 1;
    } elsif ($statCode[$i] == 406) {
      $n = "Not Acceptable"; $rc2 = 1;
    } elsif ($statCode[$i] == 407) {
      $n = "Proxy Authentication Required"; $rc2 = 1;
    } elsif ($statCode[$i] == 408) {
      $n = "Request Time-out"; $rc2 = 1;
    } elsif ($statCode[$i] == 409) {
      $n = "Conflict"; $rc2 = 1;
    } elsif ($statCode[$i] == 413) {
      $n = "Request Entity Too Large"; $rc2 = 1;
    } elsif ($statCode[$i] == 414) {
      $n = "Request Too Long"; $rc2 = 1;
    } elsif ($statCode[$i] == 415) {
      $n = "Unsupported Media Type"; $rc2 = 1;
    } elsif ($statCode[$i] > 399 && $statCode[$i] < 500) {
      $n = "($statCode[$i])"; $rc2 = 1;
    } elsif ($statCode[$i] == 500) {
      $n = "Server Error"; $rc2 = 1;
    } elsif ($statCode[$i] == 501) {
      $n = "Not Implemented"; $rc2 = 1;
    } elsif ($statCode[$i] == 502) {
      $n = "Bad Gateway"; $rc2 = 1;
    } elsif ($statCode[$i] == 503) {
      $n = "Service Unavailable"; $rc2 = 1;
    } elsif ($statCode[$i] == 504) {
      $n = "Gateway Time-out"; $rc2 = 1;
    } elsif ($statCode[$i] == 505) {
      $n = "HTTP Version Not Supported"; $rc2 = 1;
    } elsif ($statCode[$i] > 499 && $statCode[$i] < 600) {
      $n = "($statCode[$i])"; $rc2 = 1;
    }
 
    if ($rc2) {
      print "<TR><TD WIDTH=80 NOWRAP>$htmlFont$n$htmlFontEnd</TD>";
      print "<TD ALIGN=right WIDTH=40>$htmlFont$statAccess[$i]$htmlFontEnd</TD>";
      print "<TD ALIGN=left WIDTH=70>$htmlFont&nbsp;<FONT COLOR=$htmlFontColor1>($b1)</FONT>$htmlFontEnd</TD></TR>\n";
    }
  } # end of for loop


  if ($statCnt == 0) {
    print "<TR><TD WIDTH=80 NOWRAP><BR></TD><TD COLSPAN=2 ALIGN=center WIDTH=110>${htmlFont}no data$htmlFontEnd</TD></TR>\n";
  } else {
    #
    # totally access count
    print "<TR><TD WIDTH=80 NOWRAP>${htmlFont}<BR>$htmlFontEnd</TD><TD COLSPAN=2 ALIGN=center WIDTH=110>${htmlFont}<BR>$htmlFontEnd</TD></TR>\n";

    $b1 = &getBytePostfix($wholeBytes);
    print "<TR><TD WIDTH=80 NOWRAP>${htmlFont}Total Access$htmlFontEnd</TD>";
    print "<TD ALIGN=right WIDTH=40>$htmlFont$wholeAccess$htmlFontEnd</TD>";
    print "<TD ALIGN=left WIDTH=70>$htmlFont&nbsp;<FONT COLOR=$htmlFontColor1>($b1)</FONT>$htmlFontEnd</TD></TR>\n";

    if ($HTMLMonthMode) {
      $n = "Access Rate";
      $a = int($wholeAccess / ($timeLoopEnd - 1));
      $a1 = int($wholeAccess / ($timeLoopEnd - 1) * 10);
      $b = int($wholeBytes / ($timeLoopEnd - 1));
      $b1 = &getBytePostfix($b) . '/d';
    } else {
      $n = "Access Rate";
      $a = int($wholeAccess / $timeLoopEnd);
      $a1 = int($wholeAccess / $timeLoopEnd * 10);
      $b = int($wholeBytes / $timeLoopEnd);
      $b1 = &getBytePostfix($b) . '/h';
    }
    $a = $a . '.' . ($a1 - $a * 10);

    print "<TR><TD WIDTH=80 NOWRAP>${htmlFont}$n$htmlFontEnd</TD>";
    print "<TD ALIGN=right WIDTH=40>$htmlFont$a$htmlFontEnd</TD>";
    print "<TD ALIGN=left WIDTH=70>$htmlFont&nbsp;<FONT COLOR=$htmlFontColor1>($b1)</FONT>$htmlFontEnd</TD></TR>\n";

    print "<TR><TD WIDTH=80 NOWRAP>${htmlFont}Page View$htmlFontEnd</TD>";
    print "<TD ALIGN=right WIDTH=40>$htmlFont$pageAccess$htmlFontEnd</TD>";
    print "<TD ALIGN=left WIDTH=70>$htmlFont&nbsp;<FONT COLOR=$htmlFontColor1>(-)</FONT>$htmlFontEnd</TD></TR>\n";

  }
  print "</TABLE>\n<BR><BR><BR>";
 
  } # end if $HTMLStatTable

  #
  # Error Message
  #
  if ($HTMLCgiError) {
    print "<TABLE BORDER=0 CELLPADDING=0 CELLSPACING=1>\n";

    print "<TR><TD WIDTH=190 NOWRAP>${htmlFont}";
    if ($HTMLDateInvalid) {
      print "inputted date is invalid.";
    }
    print "$htmlFontEnd</TD></TR>\n";

    print "</TABLE>\n<BR><BR><BR>";
  }

  # 
  # cgi form
  #
  if ($HTMLMultiCol) {
    print "$htmlFont";
    print "<FORM METHOD=\"$htmlCgiMethod\" ACTION=\"$thisUrl\">";
    print "<INPUT TYPE=\"hidden\" NAME=\"get\" VALUE=\"yes\">";
    print "<INPUT TYPE=\"hidden\" NAME=\"multicol\" VALUE=\"on\">";
    print "<INPUT TYPE=\"hidden\" NAME=\"time\" VALUE=\"on\">";
    print "<INPUT TYPE=\"hidden\" NAME=\"stat\" VALUE=\"on\">";
    print "<INPUT TYPE=\"text\" NAME=\"year\" SIZE=4 VALUE=\"$year\">/";
    print "<INPUT TYPE=\"text\" NAME=\"month\" SIZE=2 VALUE=\"$mon\">/";
    print "<INPUT TYPE=\"text\" NAME=\"day\" SIZE=2 VALUE=\"$day\"><BR>";
    print "<INPUT TYPE=\"checkbox\" NAME=\"url\" CHECKED>Url&nbsp;";
    print "<INPUT TYPE=\"checkbox\" NAME=\"host\" CHECKED>Host&nbsp;";
    print "&nbsp;<INPUT TYPE=\"checkbox\" NAME=\"tsv\">TSV download&nbsp;";
    print "<BR><INPUT TYPE=\"submit\" VALUE=\"Stat-it\">";
    print "</FORM>$htmlFontEnd\n";
  }

  print "</TD><TD VALIGN=top>\n\n" if ($HTMLMultiCol);



  #
  # time table 
  #
  if ($HTMLTimeTable) {
  print "<TABLE BGCOLOR=$htmlTableBgColor BORDER=0 CELLPADDING=0 CELLSPACING=1>\n";
  if ($HTMLMonthMode) {
    print "<TR><TD ALIGN=right VALIGN=bottom WIDTH=20>${htmlFont}day$htmlFontEnd</TD>";
  } else {
    print "<TR><TD ALIGN=right VALIGN=bottom WIDTH=20>${htmlFont}hour$htmlFontEnd</TD>";
  }
  print "<TD WIDTH=5><BR></TD><TD ALIGN=center VALIGN=bottom WIDTH=$graphScale>${htmlFont}graph$htmlFontEnd</TD><TD COLSPAN=2 ALIGN=center VALIGN=bottom WIDTH=110>${htmlFont}access$htmlFontEnd</TD></TR>\n"; 

  for ($i = $loopBegin; $i < $loopEnd; $i++) {
    $a = $HTMLMonthMode ? $dayAccess[$i] : $hourAccess[$i];
    $a0 = $a;
    $b1 = $HTMLMonthMode ? $dayBytes[$i] : $hourBytes[$i];
    $b = $b1 / 1000;
    if (($HTMLMonthMode ? $dayAccessMax : $hourAccessMax) > $graphScale) {
      $a = ($a * $graphScale) / ($HTMLMonthMode ? $dayAccessMax : $hourAccessMax);
      $a = int($a);
      $a = 1 if ($a < 1);
    }
    if (($HTMLMonthMode ? $dayBytesMax : $hourBytesMax) > $graphScale) {
      $b = ($b * $graphScale) / ($HTMLMonthMode ? $dayBytesMax : $hourBytesMax);
      $b = int($b);
      $b = 1 if ($b < 1);
    }

    # print day or hour number
    if ($HTMLMonthMode && $a0 > 0) {  # with link 
      print "<TR><TD ALIGN=right VALIGN=bottom WIDTH=20>$htmlFont<A HREF=\"$thisUrl?${htmlCgiOption}get=yes&year=$year&month=$mon&day=$i\"><FONT COLOR=$htmlBodyText>$i</FONT></A>$htmlFontEnd</TD>";
    } else {
      print "<TR><TD ALIGN=right VALIGN=bottom WIDTH=20>$htmlFont$i$htmlFontEnd</TD>";
    }
    print "<TD VALIGN=bottom><IMG SRC=\"$imgSpace\" WIDTH=5 HEIGHT=1></TD>";

    # draw graph bar
    print "<TD ALIGN=left VALIGN=bottom WIDTH=$graphScale>";
    if (($HTMLMonthMode ? $dayAccess[$i] : $hourAccess[$i]) ne "") {
      print "<IMG SRC=\"$imgAccess\" WIDTH=$a HEIGHT=8><BR>";
    } else {
      print "<BR>";
    }
    if (($HTMLMonthMode ? $dayBytes[$i] : $hourBytes[$i]) ne "") {
      print "<IMG SRC=\"$imgByte\" WIDTH=$b HEIGHT=4><BR>";
    } else {
    }
    print "</TD>";

    # print access count
    print "<TD ALIGN=right VALIGN=bottom WIDTH=40>";
    $b1 = &getBytePostfix($b1);
    if ($HTMLMonthMode) {
        if ($dayAccess[$i] ne "") {
        print "$htmlFont$dayAccess[$i]$htmlFontEnd</TD><TD ALIGN=left VALIGN=bottom WIDTH=70>$htmlFont&nbsp;<FONT COLOR=$htmlFontColor1>($b1)</FONT>$htmlFontEnd";
      } else {
        print "<BR></TD><TD VALIGN=bottom><BR>";
      }
    } else {
        if ($hourAccess[$i] ne "") {
        print "$htmlFont$hourAccess[$i]$htmlFontEnd</TD><TD ALIGN=left VALIGN=bottom WIDTH=70>$htmlFont&nbsp;<FONT COLOR=$htmlFontColor1>($b1)</FONT>$htmlFontEnd";
      } else {
        print "<BR></TD><TD VALIGN=bottom><BR>";
      }
    }
    print "</TD>";
    print "</TR>\n";
  } # end of for loop

  if ($loopEnd == 0) {
    print "<TR><TD ALIGN=right VALIGN=bottom WIDTH=20><BR></TD>";
    print "<TD WIDTH=5><BR></TD><TD ALIGN=center VALIGN=bottom WIDTH=$graphScale>${htmlFont}no time data$htmlFontEnd</TD><TD COLSPAN=2 ALIGN=center VALIGN=bottom WIDTH=110><BR></TD></TR>\n"; 
  }
  print "</TABLE>\n";

  } # end of if $HTMLTimeTable

  print "<BR><BR>\n";


  #
  # url table 
  #
  if ($HTMLUrlTable) {
  print "<TABLE BGCOLOR=$htmlTableBgColor BORDER=0 CELLPADDING=0 CELLSPACING=1>\n";
  print "<TR><TD ALIGN=right VALIGN=bottom WIDTH=20>${htmlFont}num$htmlFontEnd</TD>";
  print "<TD WIDTH=5><BR></TD><TD ALIGN=center VALIGN=bottom WIDTH=$graphScale>${htmlFont}url$htmlFontEnd</TD><TD COLSPAN=2 ALIGN=center VALIGN=bottom WIDTH=110>${htmlFont}access$htmlFontEnd</TD></TR>\n"; 

  $loopEnd = $urlCnt > $HTMLAccessListMax ? $HTMLAccessListMax : $urlCnt;
  for ($i = 0; $i < $loopEnd; $i++) {
    $w = $graphScale;
    $b1 = &getBytePostfix($urlBytes[$i]);
    $n = $urlName[$i];
    $n = length($n) > 40 ? (substr($n,0,40) . '...') : $n;
    $i2 = $i+1;
    print "<TR><TD ALIGN=right WIDTH=20>$htmlFont$i2$htmlFontEnd</TD>";
    print "<TD><IMG SRC=\"$imgSpace\" WIDTH=5 HEIGHT=1></TD>";

    print "<TD ALIGN=left WIDTH=$w>$htmlFont";
#####  if (($urlName[$i] =~ /(\/|\.htm|\.html)$/i) && ($urlBytes[$i] > 0)) {
    if (($urlName[$i] =~ /(\/|\.htm|\.html|\.txt)$/i)) {
      print "<A HREF=\"$urlName[$i]\"><FONT COLOR=$htmlBodyText>$n</FONT></A>";
    } else {
      print "<FONT COLOR=$htmlBodyText>$n</FONT>";
    }
    print "$htmlFontEnd</TD>";

    print "<TD ALIGN=right WIDTH=40>$htmlFont$urlAccess[$i]$htmlFontEnd</TD><TD ALIGN=left WIDTH=70>$htmlFont&nbsp;<FONT COLOR=$htmlFontColor1>($b1)</FONT>$htmlFontEnd</TD></TR>\n";
  }
  if ($loopEnd == 0) {
    print "<TR><TD ALIGN=right VALIGN=bottom WIDTH=20><BR></TD>";
    print "<TD WIDTH=5><BR></TD><TD ALIGN=center VALIGN=bottom WIDTH=$graphScale>${htmlFont}no url data$htmlFontEnd</TD><TD COLSPAN=2 ALIGN=center VALIGN=bottom WIDTH=110><BR></TD></TR>\n"; 
  }
  print "</TABLE>\n";

  } # end of if $HTMLUrlTable

  print "<BR><BR>\n";

  #
  # host table 
  #
  if ($HTMLHostTable) {
  print "<TABLE BGCOLOR=$htmlTableBgColor BORDER=0 CELLPADDING=0 CELLSPACING=1>\n";
  print "<TR><TD ALIGN=right VALIGN=bottom WIDTH=20>${htmlFont}num$htmlFontEnd</TD>";
  print "<TD WIDTH=5><BR></TD><TD ALIGN=center VALIGN=bottom WIDTH=$graphScale>${htmlFont}host$htmlFontEnd</TD><TD COLSPAN=2 ALIGN=center VALIGN=bottom WIDTH=110>${htmlFont}access$htmlFontEnd</TD></TR>\n"; 

  $loopEnd = $hostCnt > $HTMLAccessListMax ? $HTMLAccessListMax : $hostCnt;
  for ($i = 0; $i < $loopEnd; $i++) {
    $w = $graphScale;
    $b1 = &getBytePostfix($hostBytes[$i]);
    $n = $hostName[$i];
    $n = length($n) > 40 ? (substr($n,0,40) . '...') : $n;
    $i2 = $i+1;
    print "<TR><TD ALIGN=right WIDTH=20>$htmlFont$i2$htmlFontEnd</TD>";
    print "<TD><IMG SRC=\"$imgSpace\" WIDTH=5 HEIGHT=1></TD>";
    print "<TD ALIGN=left WIDTH=$w>$htmlFont$n$htmlFontEnd</TD>";
    print "<TD ALIGN=right WIDTH=40>$htmlFont$hostAccess[$i]$htmlFontEnd</TD><TD ALIGN=left WIDTH=70>$htmlFont&nbsp;<FONT COLOR=$htmlFontColor1>($b1)</FONT>$htmlFontEnd</TD></TR>\n";
  }
  if ($loopEnd == 0) {
    print "<TR><TD ALIGN=right VALIGN=bottom WIDTH=20><BR></TD>";
    print "<TD WIDTH=5><BR></TD><TD ALIGN=center VALIGN=bottom WIDTH=$graphScale>${htmlFont}no host data$htmlFontEnd</TD><TD COLSPAN=2 ALIGN=center VALIGN=bottom WIDTH=110><BR></TD></TR>\n"; 
  }
  print "</TABLE>\n";

  } # end of if $HTMLHostTable


print "\n</TD></TR></TABLE>\n" if ($HTMLMultiCol);


&printHtmlEnd();

}

################
#
# print HTML monthly log
#
sub printHTMLmonth {

$HTMLMonthMode = 1;
$day = "";
&printHTMLday();

}

#################
#
# output TSV type log
#
sub getTSV {
local($day,$mon,$year);
local($rc,$i);
local($loopBegin,$loopEnd);

$day = "";
$mon = $nowMon;
$year = $nowYear;
$day = $cgiParams{'day'} if ($cgiParams{'day'} =~ /^[0-9]+$/);
$mon = $cgiParams{'month'} if ($cgiParams{'month'} =~ /^[0-9]+$/);
$year = $cgiParams{'year'} if ($cgiParams{'year'} =~ /^[0-9]+$/);

if ($day eq "") {
  $HTMLMonthMode=1;
} else {
  $HTMLMonthMode=0;
}

if ($cgiParams{'url'} eq 'on') {
  $HTMLUrlTable = 1;
  $htmlCgiOption .= 'url=on&';
}
if ($cgiParams{'host'} eq 'on') {
  $HTMLHostTable = 1;
  $htmlCgiOption .= 'host=on&';
}
if ($cgiParams{'accessmax'} =~ /^[0-9]+$/) {
  $HTMLAccessListMax = $cgiParams{'accessmax'};
  $htmlCgiOption .= "accessmax=$HTMLAccessListMax&";
}

$rc = 1;
if ($HTMLMonthMode) {
  if (&isExistCollection('',$mon,$year) > 0) {
    &getMonthCollection($mon,$year);
  } elsif ($year < $nowYear || ($mon <= $nowMon && $year == $nowYear)) {
      &makeCollection();
      &getMonthCollection($mon,$year);
  } else {
      $rc = 0;
  }
} else {
  if (&isExistCollection($day,$mon,$year) > 1) {
    &getDayCollection($day,$mon,$year);
  } elsif ($year < $nowYear || ($mon < $nowMon && $year == $nowYear) ||
    ($day <= $nowDay && $mon == $nowMon && $year == $nowYear)) {
    &makeCollection();
    &getDayCollection($day,$mon,$year);
  } else {
    $rc = 0;
  }
}

if ($rc > 0) {
  if ($HTMLMonthMode) {
    $loopBegin = 1;
    $loopEnd = $dayOfMonth[$mon - 1] + 1;
    if ($mon == 2) {
      $loopEnd ++ if (&isLeapYear($year));
    }
    $loopEnd = 0 if ($dayCnt == 0);
  } else {
    $loopBegin = 0;
    $loopEnd = 24;
    $loopEnd = 0 if ($hourCnt == 0);
  }

  print "Content-type: text/tab-separated-value\n\n";

  for ($i = $loopBegin; $i < $loopEnd; $i++) {
    $a = $HTMLMonthMode ? $dayAccess[$i] : $hourAccess[$i];
    $a = 0 if ($a eq "");
    $b = $HTMLMonthMode ? $dayBytes[$i] : $hourBytes[$i];
    $b = 0 if ($b eq "");

    if ($HTMLMonthMode) {
      print "${i}d\t$a\t$b\n";
    } else {
      print "${i}h\t$a\t$b\n";
    }      
  }

  if ($HTMLUrlTable) {
    $loopEnd = $urlCnt > $HTMLAccessListMax ? $HTMLAccessListMax : $urlCnt;
    for ($i = 0; $i < $loopEnd; $i++) {
      print "\"$urlName[$i]\"\t$urlAccess[$i]\t$urlBytes[$i]\n";
    }
  }

  if ($HTMLHostTable) {
    $loopEnd = $hostCnt > $HTMLAccessListMax ? $HTMLAccessListMax : $hostCnt;
    for ($i = 0; $i < $loopEnd; $i++) {
      print "\[$hostName[$i]\]\t$hostAccess[$i]\t$hostBytes[$i]\n";
    }
  }

} else {  # if $rc
  &printHTMLDefault();
}


}

##############################################################
sub printHttpHeader {
  print "Content-type: text/html\n\n";
}

sub printHtmlHeader {
  print <<"HEADER";
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN"
   "http://www.w3.org/TR/REC-html40/loose.dtd">
<HTML>
<HEAD>
<TITLE>$htmlTitle</TITLE>
</HEAD>
HEADER

}

sub printHtmlEnd {
  if (!$HTMLTitleDisplay) {
    print "<BR><BR>${htmlFont}&lt;${htmlTitle}&gt; &nbsp;&nbsp; $copyright$htmlFontEnd<BR>\n";
  }
  print "<!-- $copyright -->\n";
  print "</BODY></HTML>\n";
}

#
#
sub getBytePostfix {
  local($val) = @_;
  local($s);

  $s = "";
  $val /= 1000;

  if ($val > 19999999) {         # Giga byte order
    $val /= 1000;
    $val = int($val / 100);
    $s = '.' . substr($val,-0,1) if ($val < 1000);
    $val = int($val / 10) . $s . 'GB';
  } elsif ($val > 1999) {        # Mega byte order
    $val = int($val / 100);
    $s = '.' . substr($val,-0,1) if ($val < 1000);
    $val = int($val / 10) . $s . 'MB';
  } else {                       # Kilo byte order
     if ($val < 0.1) {
       $val = int($val);
     } else {
       $val *= 10;
       $val = int($val);
       $s = '.' . substr($val,-0,1) if ($val < 1000);
       $val = int($val / 10) . $s;
     }
     $val = $val . 'KB';
  }

  $val;
}

#
#
sub isDateValid {
  local($day,$month,$year) = @_;
  local($rc);

  $rc = 0;

  if ($year > 1970) {
    if ($month > 0 && $month <= 12) {
      if ($day eq "" || ($day > 0 && $day <= $dayOfMonth[$month-1])) {
        $rc = 1;
      } elsif (&isLeapYear($year) && $month == 2) {
        if ($day > 0 && $day <= ($dayOfMonth[$month-1]+1)) {
          $rc = 1;
        }
      }
    }
  }

 $rc;
}

1;
