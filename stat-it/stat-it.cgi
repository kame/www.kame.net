#!/usr/local/bin/perl
###
### Stat-it. The Web server access log analyzer
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
### $Id: stat-it.cgi,v 1.1 2001/04/17 03:41:53 itojun Exp $
###
### Informations about stat-it is obtained from
### <URL:http://www.imgsrc.co.jp/product/>.
### If you have comments, bug reports or patches, please send them to
### stat-it@imgsrc.co.jp.
###

# uncomment for SAICHTTP for WinNT 
#Win32::SetCwd($ENV{'PATH_TRANSLATED_DIR'});

$version="1.3";
#$thisUrl="/stat-it/stat-it.cgi";

$gzip="/usr/bin/gzip";
$gunzip="/usr/bin/gunzip";
$httpdLogDir="/var/log/httpd/www.kame.net";    # httpd access log directory
if ($httpdLogDir !~ /\/$/) {
    $httpdLogDir .= '/';
}
$httpdLogFile="access.log";       # httpd access log file name
$collectLogDir="/usr/local/www/data.kame/stat-it/data/";

$temporaryDir="/tmp/";
$collectLogFile="cl_%s.log";            # collected log file name format
$collectErrorFile="cl_error.log";       # collection error log file name
$errDir="err/";                         # collection error log directory
$lockFile="cl_lk%s";                    # lock file name format
$cacheIndexFile="cl_cache.idx";         # cache file name
$banFile="cl_banConcurrent";            # ban concurrent lock file name

# count specific urls 
$urlMatch="(\/|\.htm|\.html|\.shtml|\.cgi|\.pl|\.asp|\.exe|\.bat|\.lzh|\.zip|\.hqx|\.bin|\.pdf|\.tar|\.gz|\.Z|\.class|\.jar|\.java|\.txt|\.mov|\.dcr|\.swf)\$";

# count specific pages
$pageMatch="(\/|\.htm|\.html)\$";

$remakeToday=1;                     # remake if get date is today/this month
$banConcurrent=1;                   # ban concurrent collect log
$useCache=1;                        # use http log index cache
$;=':';                             # separator for multi array
$dirSp='/';                         # directory separator
$lockTimeOut=60;                    # locked file wait timeout


@monthOfYear=("Jan","Feb","Mar","Apr","May","Jun","Jul",
              "Aug","Sep","Oct","Nov","Dec");

@dayOfMonth=(31,28,31,30,31,30,31,31,30,31,30,31);

# load view.pl
require 'view.pl';

######################################################################
umask 000;

# prepare error log
$i = "$collectLogDir$errDir"; chop $i;
mkdir ($i,0777) if (! -e $i);
open(ERRLOG,">>$collectLogDir$errDir$collectErrorFile");
# $beforeErrHandle = select(ERRLOG);
# $| = 1;
# select($beforeErrHandle);


# get today information
($nowSec,$nowMin,$nowHour,$nowDay,$nowMon,$nowYear,$nowWeek,$nowYday,$nowIsdst) = localtime(time);
$nowYear += ($nowYear < 70) ? 2000 : 1900;
$nowMon++;
$dateString = sprintf("%02d/%02d/%02d %02d:%02d:%02d",$nowYear,$nowMon,$nowDay,$nowHour,$nowMin,$nowSec);


# check cgi or command line 
if ($ENV{'REQUEST_METHOD'} ne "") {
  &getCgiParameter();
  @cgiParams = %cgiParams;
  $thisUrl=$ENV{SCRIPT_NAME};
  $cgiMode = 1;

  # for maintain mode
  &toDie("supervise exit") if (-f "${collectLogDir}exit");
} else {
  $cgiMode = 0;
  eval("\$args{\$1}=\$2") while $ARGV[0] =~ /^-(\w+)=(.*)/ && shift;
}


if ($cgiMode > 0) {          # cgi mode
  # count cgiParams
  $cgiParam = @cgiParams;

  if ($cgiParam < 1) {
    &printHTMLdefault();          # no cgi parameters
  } else {
    if ($cgiParams{'tsv'} eq 'on') {  # TSV download mode
      &getTSV();
    } elsif ($cgiParams{'get'}) { # access log view mode
      if ($cgiParams{'day'}) {
        &printHTMLday();          # write HTML with day
      } elsif ($cgiParams{'month'}) {
        &printHTMLmonth();        # write HTML with month
      } else {
        &printHTMLdefault();
      }
    } elsif ($cgiParams{'logclear'}) {
 #     $a = $collectLogDir . '*';
 #     system("rm -rf $a");
    } else {
      &printHTMLdefault();
    }
  }

} else {  # command line

  # clear banConcurrent
  $lockFileName = $collectLogDir . $banFile;
  unlink($lockFileName) if (-f $lockFileName);

  #foreach $i (keys %args) {
  #  print "$i = $args{$i}\n";
  #}

  if ($args{'rotate'} eq 'on') {
    open(EXITFP,">>${collectLogDir}exit");
    close(EXITFP);

    &rotateHttpLog("./test/","httpd-access.log",".gz");

    unlink("${collectLogDir}exit");
    sleep(2);
  }

  if ($args{'build'} eq 'on') {
    print "make Collection\n";
    &makeCollection();
  } elsif ($args{'build'} eq 'remake') {
    print "rebuild Log\n";
    &rebuildLog("/var/log/","httpd-access",".gz");  # freeBSD
  }

}


close(ERRLOG);



#####################################################################

#
# get cgi paramters
#
sub getCgiParameter {
  local($name,$value,$pair);
  $funcString="getCgiParameter";

  if ($ENV{'REQUEST_METHOD'} eq "POST") {
    read(STDIN, $cgiBuffer, $ENV{'CONTENT_LENGTH'});
  } elsif ($ENV{'REQUEST_METHOD'} eq "GET") {
    $cgiBuffer = $ENV{'QUERY_STRING'};
  } else {
    $cgiBuffer = "";
  }

  if ($cgiBuffer ne "") {
    @cgiPairs = split(/&/,$cgiBuffer);
    foreach $pair (@cgiPairs) {
      ($name, $value) = split(/=/, $pair);
      $value =~ tr/+/ /;
      $value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
       # $value =~ s/\n//g;
       # $value =~ s/^//g;
       # &jcode'convert(*value,'euc'); # euc
      $cgiParams{$name} = $value;
    }
  }
  %cgiParams;
}

#
# get access log monthly collection
#
sub getMonthCollection {
  local($logMon,$logYear) = @_;
  local($mon,$year);
  local($day,$url,$host,$stat,$page,$access,$bytes);
  local($fileName,$lockFileName,$lc);
  $funcString="getMonthCollection";

  $year = $logYear;
  $mon = $monthOfYear[$logMon - 1];

  if ($remakeToday) {
    if ($year == $nowYear && $logMon == $nowMon) {
      &makeCollection();
    }
    $funcString="getMonthCollection";
  }

  # clear variables
  $dayCnt = $urlCnt = $hostCnt = $statCnt = 0;
  $dayAccessMax = $dayBytesMax = $urlAccessMax = $urlBytesMax = 0;
  $hostAccessMax = $hostBytesMax = $statAccessMax = $statBytesMax = 0;
  $dayAccessMin = $dayBytesMin = $urlAccessMin = $urlBytesMin = 1000000;
  $hostAccessMin = $hostBytesMin = $statAccessMin = $statBytesMin = 1000000;
  undef @dayAccess;
  undef @dayBytes;
  undef @urlName;
  undef @urlAccess;
  undef @urlBytes;
  undef @hostName;
  undef @hostAccess;
  undef @hostBytes;
  undef @statCode;
  undef @statAccess;
  undef @statBytes;

  # check file locking status
  $fileName = $collectLogDir . sprintf($collectLogFile, $mon.$year);
  $lockFileName = $collectLogDir . sprintf($lockFile,$mon.$year);
  $lc = 0;
  while (!&checkFileLock($lockFileName)) {
      &outError("file is locking ($lockFileName)($lc)");
      $lc++;
      last if ($lc > 2);
    };

  if (-e $fileName && -s _ && -r _) {
    if (open(FP,$fileName)) {
    } else {
      &outError("cannot open clog \"$fileName\"");
      return;
    }

    # read a file and set
    while (<FP>) {
      chop;
      next if (/^#/);
      if (
         ($day,$access,$bytes) =
         (/^([0-9]{2})d ([0-9]+) ([0-9]+).*/)) {
          $dayAccess[$day] = $access;
          $dayBytes[$day] = $bytes;
          $dayCnt++;
          $dayAccessMax = $access if ($access > $dayAccessMax);
          $dayBytesMax = $bytes if ($bytes > $dayBytesMax);
          $dayAccessMin = $access if ($access < $dayAccessMin);
          $dayBytesMin = $bytes if ($bytes < $dayBytesMin);
        }
        if (
         ($url,$access,$bytes) =
         (/^\"([^"]+)\" ([0-9]+) ([0-9]+).*/)) {
          $urlName[$urlCnt] = $url;
          $urlAccess[$urlCnt] = $access;
          $urlBytes[$urlCnt] = $bytes;
          $urlCnt++;
          $urlAccessMax = $access if ($access > $urlAccessMax);
          $urlBytesMax = $bytes if ($bytes > $urlBytesMax);
          $urlAccessMin = $access if ($access < $urlAccessMin);
          $urlBytesMin = $bytes if ($bytes < $urlBytesMin);
        }
        if (
         ($host,$access,$bytes) =
         (/^\[([^\]]+)\] ([0-9]+) ([0-9]+).*/)) {
          $hostName[$hostCnt] = $host;
          $hostAccess[$hostCnt] = $access;
          $hostBytes[$hostCnt] = $bytes;
          $hostCnt++;
          $hostAccessMax = $access if ($access > $hostAccessMax);
          $hostBytesMax = $bytes if ($bytes > $hostBytesMax);
          $hostAccessMin = $access if ($access < $hostAccessMin);
          $hostBytesMin = $bytes if ($bytes < $hostBytesMin);
        }
        if (
         ($stat,$access,$bytes) =
         (/^S([0-9]{3}) ([0-9]+) ([0-9]+).*/)) {
          $statCode[$statCnt] = $stat;
          $statAccess[$statCnt] = $access;
          $statBytes[$statCnt] = $bytes;
          $statCnt++;
          $statAccessMax = $access if ($access > $statAccessMax);
          $statBytesMax = $bytes if ($bytes > $statBytesMax);
          $statAccessMin = $access if ($access < $statAccessMin);
          $statBytesMin = $bytes if ($bytes < $statBytesMin);
        }
        if (
         ($page,$access,$bytes) =
         (/^(Page) ([0-9]+) ([0-9]+).*/)) {
          $pageAccess = $access;
        }
      } # end of while
      close(FP);
    } # end of if

}

#
# get access log daily collection
#
sub getDayCollection {
  local($logDay,$logMon,$logYear) = @_;
  local($day,$mon,$year,$monYear);
  local($hour,$url,$host,$stat,$page,$access,$bytes);
  local($fileName,$lockFileName,$lc);
  $funcString="getDayCollection";

  $year = $logYear;
  $mon = $logMon;
  $monYear = $monthOfYear[$logMon - 1] . $year;
  $day = $logDay;
  if (length($day) < 2) {
    $day = '0' . $day;
  }

  if ($remakeToday) {
    if ($year == $nowYear && $mon == $nowMon && $day == $nowDay) {
      &makeCollection();
    }
    $funcString="getDayCollection";
  }

  # clear variables
  $hourCnt = $urlCnt = $hostCnt = $statCnt = 0;
  $hourAccessMax = $hourBytesMax = $urlAccessMax = $urlBytesMax = 0;
  $hostAccessMax = $hostBytesMax = $statAccessMax = $statBytesMax = 0;
  $hourAccessMin = $hourBytesMin = $urlAccessMin = $urlBytesMin = 1000000;
  $hostAccessMin = $hostBytesMin = $statAccessMin = $statBytesMin = 1000000;
  undef @hourAccess;
  undef @hourBytes;
  undef @urlName;
  undef @urlAccess;
  undef @urlBytes;
  undef @hostName;
  undef @hostAccess;
  undef @hostBytes;
  undef @statCode;
  undef @statAccess;
  undef @statBytes;

  # check file locking status
  $fileName = $collectLogDir . $monYear . $dirSp . sprintf($collectLogFile,$day);
  $lockFileName = $collectLogDir . $monYear . $dirSp . sprintf($lockFile,$day);
  $lc = 0;
  while (!&checkFileLock($lockFileName)) {
      &outError("file is locking ($lockFileName)($lc)");
      $lc++;
      last if ($lc > 2);
    };

  if (-e $fileName && -s _ && -r _) {
    if (open(FP,$fileName)) {
    } else {
      &outError("cannot open clog \"$fileName\"");
      return;
    }

    # read a file and set
    while (<FP>) {
      chop;
      next if (/^#/);
      if (
         ($hour,$access,$bytes) =
         (/^([0-9]{2})h ([0-9]+) ([0-9]+).*/)) {
          $hourAccess[$hour] = $access;
          $hourBytes[$hour] = $bytes;
          $hourCnt++;
          $hourAccessMax = $access if ($access > $hourAccessMax);
          $hourBytesMax = $bytes if ($bytes > $hourBytesMax);
          $hourAccessMin = $access if ($access < $hourAccessMin);
          $hourBytesMin = $bytes if ($bytes < $hourBytesMin);
        }
        if (
         ($url,$access,$bytes) =
         (/^\"([^"]+)\" ([0-9]+) ([0-9]+).*/)) {
          $urlName[$urlCnt] = $url;
          $urlAccess[$urlCnt] = $access;
          $urlBytes[$urlCnt] = $bytes;
          $urlCnt++;
          $urlAccessMax = $access if ($access > $urlAccessMax);
          $urlBytesMax = $bytes if ($bytes > $urlBytesMax);
          $urlAccessMin = $access if ($access < $urlAccessMin);
          $urlBytesMin = $bytes if ($bytes < $urlBytesMin);
        }
        if (
         ($host,$access,$bytes) =
         (/^\[([^\]]+)\] ([0-9]+) ([0-9]+).*/)) {
          $hostName[$hostCnt] = $host;
          $hostAccess[$hostCnt] = $access;
          $hostBytes[$hostCnt] = $bytes;
          $hostCnt++;
          $hostAccessMax = $access if ($access > $hostAccessMax);
          $hostBytesMax = $bytes if ($bytes > $hostBytesMax);
          $hostAccessMin = $access if ($access < $hostAccessMin);
          $hostBytesMin = $bytes if ($bytes < $hostBytesMin);
        }
        if (
         ($stat,$access,$bytes) =
         (/^S([0-9]{3}) ([0-9]+) ([0-9]+).*/)) {
          $statCode[$statCnt] = $stat;
          $statAccess[$statCnt] = $access;
          $statBytes[$statCnt] = $bytes;
          $statCnt++;
          $statAccessMax = $access if ($access > $statAccessMax);
          $statBytesMax = $bytes if ($bytes > $statBytesMax);
          $statAccessMin = $access if ($access < $statAccessMin);
          $statBytesMin = $bytes if ($bytes < $statBytesMin);
        }
        if (
         ($page,$access,$bytes) =
         (/^(Page) ([0-9]+) ([0-9]+).*/)) {
          $pageAccess = $access;
        }
      } # end of while
      close(FP);
    } # end of if

}

#
# check existing or not  access log collection
#
sub isExistCollection {
  local($logDay,$logMon,$logYear) = @_;
  local($rc,$day,$mon,$year,$monYear,$fileName);
  $funcString="isExistCollection";

  $year = $logYear;
  $mon = $logMon;
  $monYear = $monthOfYear[$logMon - 1] . $year;
  $day = $logDay;
  if (length($day) < 2) {
    $day = '0' . $day;        # $day is '0' if $day was null
  }

  $rc = 0;    # default status

  if (($year > $nowYear) ||
      ($mon > $nowMon && $year == $nowYear) ||
      ($day > $nowDay && $mon == $nowMon && $year == $nowYear)) {
    $rc = -1;
  } elsif (
      ($day == $nowDay || $day == 0) &&
      $mon == $nowMon && $year == $nowYear) {
    $rc = 2;
  } else {
    if ($day == 0) {            # monthly file check   
      $fileName = $collectLogDir . sprintf($collectLogFile,$monYear);
      if (-e $fileName && -s _ && -r _) {
        $rc = 1;
      }
    } else {                    # daily file check
      $fileName = $collectLogDir . $monYear . $dirSp . sprintf($collectLogFile,$day);
      if (-e $fileName && -s _ && -r _) {
        $rc = 3;
      } else {
        $fileName = $collectLogDir . sprintf($collectLogFile,$monYear);
        if (-e $fileName && -s _ && -r _) {
          $rc = 1;
        }
      }
    }
  }

  # if 3, request date ok, if 2, today or this month,
  # if 1, request month ok, if 0, nothing.
  # if -1, feature date
  $rc;
}

#
# check the year is leap year, is not ?
#
sub isLeapYear {
  local($year) = @_;

  if ((!($year % 4) && ($year % 100)) || !($year % 400)) {
   1;
  } else {
   0;
  }
}

#
# output to errlog
#
sub outError {
  local($str) = @_;
  local($lockFileName,$locked);
  local($eSec,$eMin,$eHour,$eDay,$eMon,$eYear,$eWeek,$eYday,$eIsdst);
  local($dateString,$s1);

  # get current date
  ($eSec,$eMin,$eHour,$eDay,$eMon,$eYear,$eWeek,$eYday,$eIsdst) = localtime(time);
  $eYear += ($eYear < 70) ? 2000 : 1900;
  $eMon++;
  $dateString = sprintf("%02d/%02d/%02d %02d:%02d:%02d",$eYear,$eMon,$eDay,$eHour,$eMin,$eSec);

  # check file locking status. note: it cannot use checkFileLock
  $lockFileName = $collectLogDir . sprintf("$lockFile","Err");
  if (-f $lockFileName) {         # cannot use checkFileLock function
    for ($i = 0; $i < $lockTimeOut; $i++) {
      sleep(1);
      last unless -f $lockFileName;
    }
  }
  if (!-f $lockFileName) {  # no locking status
    open(ERRLOCKFP,">$lockFileName$$");
    close(ERRLOCKFP);
    $locked = link("$lockFileName$$","$lockFileName");
    unlink("$lockFileName$$");
    if ($locked) {
      print ERRLOG "[$dateString:$funcString:$$] $str\n";
    } else {
      $s1 = "$collectLogDir$errDir";
      chop $s1;
      mkdir ($s1,0777) if (! -e $s1);
      open(ERRLOG2,">>$collectLogDir$errDir$collectErrorFile.$$.err");
      print ERRLOG2 "[$dateString:$funcString:$$] $str\n";
      close(ERRLOG2);
      
      # should prepare to marge error log files
    }
    unlink($lockFileName) if (-f $lockFileName);
  }
}

#
# to die
#
sub toDie {
 local($str) = @_;
 local($l);
 local($cacheName);

  &outError("DYING..");

  # clear lock file
  foreach $l (sort keys %lockFiles) {
    if (-f $lockFiles{$l}) {
      &outError("FATAL:unlinking no removed lock file ($lockFiles{$l})");
      unlink($lockFiles{$l});
    }
  }
  
  # remove cache file
  $cacheName = $collectLogDir . $cacheIndexFile;
  link($cacheName,"$cacheName.$$");
  &outError("FATAL:unlinking cache file");
  unlink($cacheName) if (-f $cacheName);


  &outError("DEAD $str");

  # close ERRLOG
  close(ERRLOG);

  die;
}

###########################################################################
#
# processing httpd access log to collections
#
#

#
# make or rebuild access log collection
#
sub makeCollection {
  local($flag,$monYear,$dayMonYear);
  local($lockFileName,$locked);
  local($l);
  $funcString="makeCollection";

  # check the concurrent entrant and ban
  #&outError("enter makeCol");
  $lockFileName = $collectLogDir . $banFile;
  if ($banConcurrent) {
    #if (!checkFileLock($lockFileName)) {
    if (-f $lockFileName) {
      &outError("ban concurrent access to log");
      return;
    }
    open(BANFP,">$lockFileName$$");
    close(BANFP);
    $locked = link("$lockFileName$$","$lockFileName");
    unlink("$lockFileName$$");
    if (!$locked) {
      &outError("cannot create ban-file ($lockFileName)");
      unlink($lockFileName);
      return;
    }
  }

  # collect the httpd log and write
  #&outError("go collectLog");
  &collectLog();        # process httpd_access log

  # write the not yet log
  $flag = 0;
  foreach $monYear (sort keys %monYears) {
    $flag = 1 if ($monYears{$monYear} > 0);
  }
  foreach $dayMonYear (sort keys %dayMonYears) {
    $flag = 1 if ($dayMonYears{$dayMonYear} > 0);
  }
  if ($flag > 0) {
    &sortCollection();     # sort collections
    &outputCollection();   # output collections to files
  }
  $funcString="makeCollection";


  # clear lock file
  foreach $l (sort keys %lockFiles) {
    if (-f $lockFiles{$l}) {
      &outError("FATAL:unlinking no removed lock file ($lockFiles{$l})");
      unlink($lockFiles{$l});
    }
  }


  &clearArrays();        # clear arrays
  undef %dayMonYears;
  undef %monYears;
  undef %lockFiles;
  #&outError("exit makeCol");

  # clear ban file
  unlink($lockFileName) if (-f $lockFileName);

  # wait for writing disk
  sleep(5);
}

#
# check log file locking
#
sub checkFileLock {
  local($lockFileName) = @_;
  local($i);
  ###$funcString="checkFileLock";

  #&outError("check lock file ($lockFileName)");
  if (-f $lockFileName) {
    &outError("file is busy ($lockFileName)");
    for ($i = 0; $i < $lockTimeOut; $i++) {
      sleep(1);
      last unless -f $lockFileName;
    }
    #sleep(10) unless -f $lockFileName;
  }
  if (-f $lockFileName) {
    &outError("FATAL:lock file wait timeout ($lockFileName)");
    0;
  } else {
    1;
  }
}

#
# output access log collection
#
sub outputCollection {
  local($key,$monYear,$dayMonYear,$fileName);
  local($day,$mon,$day,$hour,$access,$bytes);
  local($url,$host,$stat);
  local($i,$orgHandle,$lockFileName,$l);
  $funcString="outputCollection";

  $i = $collectLogDir;
  chop $i;
  mkdir ($i,0777) if (! -e $i);


  foreach $monYear (sort keys %monYears) {

    last if ($monYears{$monYear} < 1);

    $fileName = $collectLogDir . sprintf($collectLogFile,$monYear);
    $lockFileName = $collectLogDir . sprintf($lockFile,$monYear);

    if (-e $fileName && -s _ && ($lockFiles{$monYear} ne $lockFileName)) {
      &outError("huh? lock file is not regstered ($lockFileName)");
    }

    if (!open(FP,">$fileName")) {
      &outError("cannot create clog \"$fileName\"");
    } else {

      $orgHandle = select(FP);
      $| = 1;

      print FP "#\n#last daytime [",$lastDaytime{$monYear},"]\n#\n";
      #&outError("last daytime [$lastDaytime{$monYear}]");

      print FP "#\n#order day\n#\n";
      for ($i = 0; $i < $hourCnt{$monYear}; $i++) {
        print FP $hourLines{$monYear,$i};
      }
      print FP "#\n#order url\n#\n";
      for ($i = 0; $i < $urlCnt{$monYear}; $i++) {
        print FP $urlLines{$monYear,$i};
      }
      print FP "#\n#order host\n#\n";
      for ($i = 0; $i < $hostCnt{$monYear}; $i++) {
        print FP $hostLines{$monYear,$i};
      }
      print FP "#\n#order stat\n#\n";
      for ($i = 0; $i < $statCnt{$monYear}; $i++) {
        print FP $statLines{$monYear,$i};
      }
      print FP "#\n#order page\n#\n";
      print FP "Page $pageAccess{$monYear} 0\n";

 #     print FP "#\n#order error\n#\n";
 #     for ($i = 0; $i < $eaCnt{$monYear}; $i++) {
 #       print FP "Error $errorAccess{$monYear,$i}\n";
 #     }

      close(FP);
      select($orgHandle);

    }
    #&outError("unlinking lock file ($lockFileName)");
    unlink($lockFileName) if (-e $lockFileName);
    $lockFiles{$monYear} = "";

  } # end of foreach monYears



  foreach $dayMonYear (sort keys %dayMonYears) {

    last if ($dayMonYears{$dayMonYear} < 1);

    ($day,$mon) = ($dayMonYear =~ /([0-9]{2})(.*)/);
    mkdir($collectLogDir . $mon,0777) if (! -e ($collectLogDir . $mon));
    if (!-w ($collectLogDir . $mon)) {
       &toDie("cannot write \"$collectLogDir$mon\"");
    }
    $fileName = $collectLogDir . $mon . $dirSp . sprintf($collectLogFile,$day);
    $lockFileName = $collectLogDir . $mon . $dirSp . sprintf($lockFile,$day);

    if (-e $fileName && -s _ && ($lockFiles{$dayMonYear} ne $lockFileName)) {
      &outError("huh? lock file is not regstered ($lockFileName)");
    }

    if (!open(FP,">$fileName")) {
      &outError("cannot create clog \"$fileName\"");
    } else {

      $orgHandle = select(FP);
      $| = 1;

      #print FP "#\n#last daytime [",$lastDaytime{$monYear},"]\n#\n";
      print FP "#\n#day [",$dayMonYear,"]\n#\n";

      print FP "#\n#order hour\n#\n";
      for ($i = 0; $i < $hourCnt{$dayMonYear}; $i++) {
        print FP $hourLines{$dayMonYear,$i};
      }
      print FP "#\n#order url\n#\n";
      for ($i = 0; $i < $urlCnt{$dayMonYear}; $i++) {
        print FP $urlLines{$dayMonYear,$i};
      }
      print FP "#\n#order host\n#\n";
      for ($i = 0; $i < $hostCnt{$dayMonYear}; $i++) {
        print FP $hostLines{$dayMonYear,$i};
      }
      print FP "#\n#order stat\n#\n";
      for ($i = 0; $i < $statCnt{$dayMonYear}; $i++) {
        print FP $statLines{$dayMonYear,$i};
      }
      print FP "#\n#order page\n#\n";
      print FP "Page $pageAccess{$dayMonYear} 0\n";

 #     print FP "#\n#order error\n#\n";
 #     for ($i = 0; $i < $eaCnt{$dayMonYear}; $i++) {
 #       print FP "Error $errorAccess{$dayMonYear,$i}\n";
 #     }


      close(FP);
      select($orgHandle);

    }
    #&outError("unlinking ($lockFileName)");
    unlink($lockFileName) if (-e $lockFileName);
    $lockFiles{$dayMonYear} = "";

  } # end of foreach dayMonYears


  #foreach $l (sort keys %lockFiles) {
  #  if ($lockFiles{$l} ne "") {
  #    &outError("didnot removed lockFile \"$lockFiles{$l}\"");
  #    unlink($lockFiles{$l});
  #    $lockFiles{$l} = "";
  #  }
  #}

}

#
# read http access log and collect log
#
sub collectLog {
  local($host,$rfc931,$user,$time,$request,$stat,$bytes);
  local($day,$mon,$year,$hour,$min,$sec,$tz);
  local($method,$url,$hver,$urlreq,$saveline);
  local($dayHour,$monYear,$dayMonYear,$lastMonYear,$lastDayMonYear);
  local($fileName);
  local($daytime,$daytimeLast,$daytimeCnt,$skipCnt);
  local($httpLogName);
  local($cacheName,$cacheLine,$cacheSeek,$cl,$httpLogTop,$ctop);
  local($cacheSeekOk);
  local($lockFileName,$locked,$lc,$orgHandle);
  $funcString="collectLog";

  #&outError("enter collectLog");

  # open httpd log
  $httpLogName = $httpdLogDir . $httpdLogFile;
  if (-e $httpLogName && -s _ && -r _) {
    if (open(HTTPLOG,$httpLogName)) {
    } else {
      &outError("cannot open httplog \"$httpLogName\"");
      return;
    }

    # check the cache file
    $cacheName = $collectLogDir . $cacheIndexFile;
    $ctop="";
    $cl=0;
    $cacheSeekOk=0;
    if ($useCache && (-e $cacheName && -s _ && -r _)) {
      $lockFileName = $collectLogDir . sprintf("$lockFile",$cacheIndexFile);
      $lc = 0;
      while (!&checkFileLock($lockFileName)) {
        &outError("file is locking ($lockFileName)($lc)");
        $lc++;
        if ($lc > 2) {
          close(HTTPLOG);
          return;
        }
      };
      if (open(CACHEFP,$cacheName)) { # open and get cache data
        while (<CACHEFP>) {
          chop;
          $cl = $_;
          if (($_) = ($cl =~ /^HttpLogTop (.+)$/)) {
            $cacheLine = $_;
          }
          if (($_) = ($cl =~ /^HttpSeekPoint ([0-9]+)$/)) {
            $cacheSeek = $_;
          }
        }
        close(CACHEFP);

        # check cache data
        if (($cacheLine ne "") && ($cacheSeek =~ /^[0-9]+$/)) {
          $httpLogTop = <HTTPLOG>;
          chop($httpLogTop);
          $ctop = $httpLogTop;
          if ($cacheLine eq $ctop) {  # cache data is okay
            # seek to cached line
            if (!seek(HTTPLOG,$cacheSeek,0)) {
              seek(HTTPLOG,0,1);
              &outError("cache match but,fail to seek $cacheSeek");
            } else {
              $cacheSeekOk = 1;
              # &outError("cache match ($cacheSeek)");
            }
          } else {
            seek(HTTPLOG,0,1);
            &outError("cache unmatched");
          }
        }
      }
    }

  $lastMonYear = "";
  $lastDayMonYear = "";

  # read httpd log and collect
  while (<HTTPLOG>) {
    chop;

    $saveline = $_;
    $ctop = $saveline if ($ctop eq "");
    # match a log line.
    #  format HOST RFC931 USER [TIME] "REQUEST" STAT BYTES
    #  ex.    xx.yy.jp - - [01/May/1998:22:30:30 +0900] "GET / HTTP/1.0" 200 123
    if (
     ($host,$rfc931,$user,$time,$request,$stat,$bytes) = 
     ($saveline =~ /^(\S+) (\S+) (\S+) \[([^\]]*)\] \"(.*)\" (\S+) (\S+)/)) {
   # ($saveline = /^(\S+) (\S+) (\S+) \[([^\]]*)\] \"([^"]*)\" (\S+) (\S+)/)) {
      $stat = "200" if ($stat eq '-');
      $bytes = "0" if ($bytes eq '-');
  
      # extract date and time
      #  format [DAY/MON/YEAR:HOUR:MIN:SEC TZOFFSET]
      #  ex.    [01/May/1998:22:30:30 +0900]
      ($day,$mon,$year,$hour,$min,$sec,$tz) = ($time =~ /^([0-9]+)\/([a-zA-Z]+)\/([0-9]+):([0-9]+):([0-9]+):([0-9]+) (.+)$/);
  
      # extract request
      #  format "METHOD URL HTTP"
      #  ex.    "GET /index.html HTTP/1.0"
      ($method,$url,$hver) = ($request =~ /^(\w+)\s+(\S+)\s*(\S*)$/);
      $urlreq="";
      if ($url =~ /.*\077.*/) {  # '?' mark
        ($url,$urlreq) = ($url =~ /([^\077]+)\077(.+)/);
      }
      #$url =~ s/%7E/~/g;
      $url =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
  
      # adjunct 
      $dayHour = $day . ' ' . $hour;
      $monYear = $mon . $year;                  # array index etc.
      $dayMonYear = $day . $monYear;            # araay index etc.

      $daytime = $day .' '. $hour .':'. $min .':'. $sec;
      if ($daytime ne $daytimeLast) {
        $daytimeCnt = 1;
        $daytimeLast = $daytime;
      } else {
        $daytimeCnt++;
      }
      $lastDaytime{$monYear} = $daytime .' #'.$daytimeCnt;


      # get previous data
      if (($lockFiles{$dayMonYear} eq "") && ($dayMonYear ne $lastDayMonYear)) {
        if ($dayMonYears{$lastDayMonYear} < 1) {
          #&outError("unlinking $lastDayMonYear, $lockFiles{$lastDayMonYear}");
          unlink($lockFiles{$lastDayMonYear}) if (-f $lockFiles{$lastDayMonYear});
          $lockFiles{$lastDayMonYear} = "";
        }
        $pageAccess{$dayMonYear} = 0;
        &collectLog3($dayMonYear,$monYear,$day);  # get currect collection data
        $funcString="collectLog";
      }
      if (($lockFiles{$monYear} eq "") && ($monYear ne $lastMonYear)) {
        if ($monYears{$lastMonYear} < 1) {
          #&outError("unlinking $lastMonYear, $lockFiles{$lastMonYear}");
          unlink($lockFiles{$lastMonYear}) if (-f $lockFiles{$lastMonYear});
          $lockFiles{$lastMonYear} = "";
        }

        # exporting
        if ($lastMonYear ne "") {
          &sortCollection();     # sort collections
          &outputCollection();   # output collections to files
          &clearArrays();        # clear arrays

          undef %dayMonYears;
          delete $monYears{$lastMonYear};
        }

        $skipCnt = 0;
        $pageAccess{$monYear} = 0;
        &collectLog3($monYear,"","");  # get currect collection data

        $funcString="collectLog";
      }

      $lastMonYear = $monYear;
      $lastDayMonYear = $dayMonYear;


      # skip collected line
      #if (!$useCache OR (!$cacheSeekOk ... it bad ?
      if (!$cacheSeekOk && ($logLastCheck{$monYear} > 0)) {
        next if ($day < $logLastDay{$monYear});
        if ($day <= $logLastDay{$monYear}) {
          next if ($hour < $logLastHour{$monYear});
          if ($hour <= $logLastHour{$monYear}) {
            next if ($min < $logLastMin{$monYear});
            if ($min <= $logLastMin{$monYear}) {
              next if ($sec < $logLastSec{$monYear});
              if ($sec == $logLastSec{$monYear}) {
                $skipCnt++;
                next if ($skipCnt <= $logLastCnt{$monYear});
              }
            }
          }
        }
      }

      # counting http log here!
      #  change if you got another data condition
      #  like status is good onlygood only.
      $hourAccess{$monYear,$day.'d'}++;
      $hourBytes{$monYear,$day.'d'} += $bytes;
      $hourAccess{$dayMonYear,$hour.'h'}++;
      $hourBytes{$dayMonYear,$hour.'h'} += $bytes;

      if ($url =~ /$urlMatch/i) {
        $urlAccess{$monYear,$url}++;
        $urlBytes{$monYear,$url} += $bytes;
        $urlAccess{$dayMonYear,$url}++;
        $urlBytes{$dayMonYear,$url} += $bytes;
      }
      $hostAccess{$monYear,$host}++;
      $hostBytes{$monYear,$host} += $bytes;
      $hostAccess{$dayMonYear,$host}++;
      $hostBytes{$dayMonYear,$host} += $bytes;

      $statAccess{$monYear,$stat}++;
      $statBytes{$monYear,$stat} += $bytes;
      $statAccess{$dayMonYear,$stat}++;
      $statBytes{$dayMonYear,$stat} += $bytes;

      if (($stat < 400) && ($url =~ /$pageMatch/i)) {
        $pageAccess{$monYear}++;
        $pageAccess{$dayMonYear}++;
      }

  #    if ($stat >= 400) {
  #      $errorAccess{$monYear,$eaCnt{$monYear}} = $saveline;
  #      $errorAccess{$dayMonYear,$eaCnt{$dayMonYear}} = $saveline;
  #      $eaCnt{$monYear}++;
  #      $eaCnt{$dayMonYear}++;
  #    }

      $monYears{$monYear}++;
      $dayMonYears{$dayMonYear}++;

      # comment out. must not uncomment
      #$lastMonYear = $monYear;
      #$lastDayMonYear = $dayMonYear;

    } else {                             # if match a log line.
      &outError("unmatched line in httplog ($saveline)");
    }
  } # end of while

  $cl = tell(HTTPLOG);  # currect position for cache
  close(HTTPLOG);


  # write cache data
  $lockFileName = $collectLogDir . sprintf("$lockFile",$cacheIndexFile);
  if ($useCache && &checkFileLock($lockFileName)) {

    open(LOCKFP,">$lockFileName$$");
    close(LOCKFP);
    $locked = link("$lockFileName$$","$lockFileName");
    unlink("$lockFileName$$");
    if ($locked) {
      if (open(CACHEFP,">$cacheName")) { # open and write
        $orgHandle = select(CACHEFP);
        $| = 1;
        print CACHEFP "HttpLogTop $ctop\n" if ($ctop ne "");
        print CACHEFP "HttpSeekPoint $cl\n" if ($cl =~ /^[0-9]+$/);
        print CACHEFP "HttpLastLine $saveline\n" if ($saveline ne "");
        close(CACHEFP);
        select($orgHandle);
        unlink($lockFileName);
      } else {                   # cannot open for wite
        &toDie("cannot create cache file \"$cacheName\"");
      }
    } else {  # locked
      &toDie("cannot create lock file \"$lockFileName\"");
      unlink("$lockFileName") if (-f $lockFileName);
    }
  }

  } else {
    &outError("cannot find httplog \"$httpLogName\"");
  } # end of if

}

#
# count from existing collection files
#
sub collectLog3 {
  local($dateIndex,$subDir,$fileOpt) = @_;
  local($fileName,$key,$monYear);
  local($day,$hour,$access,$bytes);
  local($day2,$hour2,$min2,$sec2,$cnt2);
  local($url,$host,$stat,$page);
  local($lockFileName,$lc);
  local($oldFunc);
  $oldFunc=$funcString;
  $funcString="collectLog3";

  # $subDir = "" and $fileOpt = "" likely for monthly log files
  # $subDir = "Apr1999" and $fileOpt = "" for daily log files

  $subDir .= $dirSp if ($subDir ne "");      # catnate the dir separator
  $fileOpt = $dateIndex if ($fileOpt eq ""); # fileOpt must be monthly word or null
  $fileName = $collectLogDir . $subDir . sprintf($collectLogFile,$fileOpt);
  $lockFileName = $collectLogDir . $subDir . sprintf($lockFile,$fileOpt);

  if ($lockFiles{$dateIndex} ne "") {
    &outError("[$dateIndex] is already locked");
    return;
  } 

  if (-e $fileName && -s _ && -r _) {

    # lock file
    $lc = 0;
    while (!&checkFileLock($lockFileName)) {
      &outError("file is locking ($lockFileName)($lc)");
      $lc++;
      &toDie("no removed lock file ($lockFileName)") if ($lc > 2);
    }

    $lockFiles{$dateIndex} = $lockFileName;

    if (-f $lockFileName) { &toDie("FATAL:bad lock file ($lockFileName)"); }
    open(LOCKFP,">$lockFileName$$");
    close(LOCKFP);
    $locked = link("$lockFileName$$","$lockFileName");
    unlink("$lockFileName$$");
    if ($locked) {
      #&outError("create lock file ($lockFileName)");
    } else {
      unlink($lockFileName);
      &toDie("cannot create lock file \"$lockFileName\"");
    }

    # open collect log
    if (!open(FP,$fileName)) {
      unlink($lockFileName);
      &toDie("cannot open clog \"$fileName\"");
    }

    # clear variables
    $hourCnt{$dateIndex} = $urlCnt{$dateIndex} = 0;
    $hostCnt{$dateIndex} = $statCnt{$dateIndex} = 0;
    $logLastDay{$dateIndex} = $logLastHour{$dateIndex} = 0;
    $logLastMin{$dateIndex} = $logLastSec{$dateIndex} = 0;
    $logLastCnt{$dateIndex} = $logLastCheck{$dateIndex} = 0;

    # read a file and set
    while (<FP>) {
      chop;

      # monthly log files have the last daytime keyword
      if (($subDir eq "") &&
       (($day2,$hour2,$min2,$sec2,$cnt2) =
       (/^#last daytime \[([0-9]+) ([0-9]+):([0-9]+):([0-9]+) \#([0-9]+)\].*/))) {
        $logLastDay{$dateIndex}=$day2;
        $logLastHour{$dateIndex}=$hour2;
        $logLastMin{$dateIndex}=$min2;
        $logLastSec{$dateIndex}=$sec2;
        $logLastCnt{$dateIndex}=$cnt2;
        $logLastCheck{$dateIndex}=1;
      }

      next if (/^#/);

      if (($subDir eq "") &&
       (($day,$access,$bytes) =
       (/^([0-9]{2})d ([0-9]+) ([0-9]+).*/))) {
        $hourAccess{$dateIndex,$day .'d'} += $access;
        $hourBytes{$dateIndex,$day .'d'} += $bytes;
        $hourCnt{$dateIndex}++;
      }
      if (($subDir ne "") &&
       (($hour,$access,$bytes) =
       (/^([0-9]{2})h ([0-9]+) ([0-9]+).*/))) {
        $hourAccess{$dateIndex,$hour.'h'} += $access;
        $hourBytes{$dateIndex,$hour.'h'} += $bytes;
        $hourCnt{$dateIndex}++;
      }
      if (
       ($url,$access,$bytes) =
       (/^\"([^"]+)\" ([0-9]+) ([0-9]+).*/)) {
        $urlAccess{$dateIndex,$url} += $access;
        $urlBytes{$dateIndex,$url} += $bytes;
        $urlCnt{$dateIndex}++;
      }
      if (
       ($host,$access,$bytes) =
       (/^\[([^\]]+)\] ([0-9]+) ([0-9]+).*/)) {
        $hostAccess{$dateIndex,$host} += $access;
        $hostBytes{$dateIndex,$host} += $bytes;
        $hostCnt{$dateIndex}++;
      }
      if (
       ($stat,$access,$bytes) =
       (/^S([0-9]{3}) ([0-9]+) ([0-9]+).*/)) {
        $statAccess{$dateIndex,$stat} += $access;
        $statBytes{$dateIndex,$stat} += $bytes;
        $statCnt{$dateIndex}++;
      }
      if (
       ($page,$access,$bytes) =
       (/^(Page) ([0-9]+) ([0-9]+).*/)) {
        $pageAccess{$dateIndex} += $access;
      }
    } # end of while
    close(FP);
  } # end of if file

  $funcString=$oldFunc;
}

#
# sort collection arrays 
#
sub sortCollection {
  local($key,$monYear,$dayMonYear,$cnt);
  local($day,$hour,$access,$bytes);
  local($url,$host,$stat);
  local($i,$accessA,$accessB,$byteA,$byteB);
  $funcString="sortCollection";

  foreach $monYear (keys %monYears) {

      # Hours
      $hourCnt{$monYear}=0;
      foreach $key (sort keys %hourAccess) {
        if (($day) = ($key =~ /^$monYear:(.*)/)) {
          if (($bytes = $hourBytes{$key}) eq "") { $bytes = 0; }
          $hourLines{$monYear,$hourCnt{$monYear}} = "$day $hourAccess{$key} $bytes\n";
        }
        $hourCnt{$monYear}++;
      }

      # Urls
      $urlCnt{$monYear}=0;
      @urlLines = ();
      foreach $key (keys %urlAccess) {
        if (($url) = ($key =~ /^$monYear:(.*)/)) {
          if (($bytes = $urlBytes{$key}) eq "") { $bytes = 0; }
          $urlLines[$urlCnt{$monYear}] = "\"$url\" $urlAccess{$key} $bytes\n";
        }
        $urlCnt{$monYear}++;
      }
      @urlSorted = sort {
         ($accessA,$byteA) = ($a =~ /^\"[^"]+\" ([0-9]+) ([0-9]+).*/);
         ($accessB,$byteB) = ($b =~ /^\"[^"]+\" ([0-9]+) ([0-9]+).*/);
         if ($accessA < $accessB) { 1; }
         elsif ($accessA > $accessB) { -1; }
         else {
          if ($byteA < $byteB) { 1; }
          elsif ($byteA > $byteB) { -1; } else { 0; }
        }
        } @urlLines;
      for ($i = 0; $i < $urlCnt{$monYear}; $i++) {
        $urlLines{$monYear,$i}=$urlSorted[$i];
      }

      # Hosts
      $hostCnt{$monYear}=0;
      @hostLines = ();
      foreach $key (keys %hostAccess) {
        if (($host) = ($key =~ /^$monYear:(.*)/)) {
          if (($bytes = $hostBytes{$key}) eq "") { $bytes = 0; }
          $hostLines[$hostCnt{$monYear}] = "[$host] $hostAccess{$key} $bytes\n";
        }
        $hostCnt{$monYear}++;
      }
      @hostSorted = sort {
         ($accessA,$byteA) = ($a =~ /^\[[^\]]+\] ([0-9]+) ([0-9]+).*/);
         ($accessB,$byteB) = ($b =~ /^\[[^\]]+\] ([0-9]+) ([0-9]+).*/);
         if ($accessA < $accessB) { 1; }
         elsif ($accessA > $accessB) { -1; }
         else {
          if ($byteA < $byteB) { 1; }
          elsif ($byteA > $byteB) { -1; } else { 0; }
         }
         } @hostLines;
      for ($i = 0; $i < $hostCnt{$monYear}; $i++) {
        $hostLines{$monYear,$i}=$hostSorted[$i];
      }

      # Stats
      $statCnt{$monYear}=0;
      foreach $key (sort keys %statAccess) {
        if (($stat) = ($key =~ /^$monYear:(.*)/)) {
          if (($bytes = $statBytes{$key}) eq "") { $bytes = 0; }
          $statLines{$monYear,$statCnt{$monYear}} = "S$stat $statAccess{$key} $bytes\n";
        }
        $statCnt{$monYear}++;
      }

  } # end of foreach monYears


  foreach $dayMonYear (keys %dayMonYears) {

      # Hours
      $hourCnt{$dayMonYear}=0;
      foreach $key (sort keys %hourAccess) {
        if (($hour) = ($key =~ /^$dayMonYear:(.*)/)) {
          if (($bytes = $hourBytes{$key}) eq "") { $bytes = 0; }
          $hourLines{$dayMonYear,$hourCnt{$dayMonYear}} = "$hour $hourAccess{$key} $bytes\n";
        }
        $hourCnt{$dayMonYear}++;
      }

      # Urls
      $urlCnt{$dayMonYear}=0;
      @urlLines = ();
      foreach $key (keys %urlAccess) {
        if (($url) = ($key =~ /^$dayMonYear:(.*)/)) {
          if (($bytes = $urlBytes{$key}) eq "") { $bytes = 0; }
          $urlLines[$urlCnt{$dayMonYear}] = "\"$url\" $urlAccess{$key} $bytes\n";
        }
        $urlCnt{$dayMonYear}++;
      }
      @urlSorted = sort {
         ($accessA,$byteA) = ($a =~ /^\"[^"]+\" ([0-9]+) ([0-9]+).*/);
         ($accessB,$byteB) = ($b =~ /^\"[^"]+\" ([0-9]+) ([0-9]+).*/);
         if ($accessA < $accessB) { 1; }
         elsif ($accessA > $accessB) { -1; }
         else {
          if ($byteA < $byteB) { 1; }
          elsif ($byteA > $byteB) { -1; } else { 0; }
        }
        } @urlLines;
      for ($i = 0; $i < $urlCnt{$dayMonYear}; $i++) {
        $urlLines{$dayMonYear,$i}=$urlSorted[$i];
      }

      # Hosts
      $hostCnt{$dayMonYear}=0;
      @hostLines = ();
      foreach $key (keys %hostAccess) {
        if (($host) = ($key =~ /^$dayMonYear:(.*)/)) {
          if (($bytes = $hostBytes{$key}) eq "") { $bytes = 0; }
          $hostLines[$hostCnt{$dayMonYear}] = "[$host] $hostAccess{$key} $bytes\n";
        }
        $hostCnt{$dayMonYear}++;
      }
      @hostSorted = sort {
         ($accessA,$byteA) = ($a =~ /^\[[^\]]+\] ([0-9]+) ([0-9]+).*/);
         ($accessB,$byteB) = ($b =~ /^\[[^\]]+\] ([0-9]+) ([0-9]+).*/);
         if ($accessA < $accessB) { 1; }
         elsif ($accessA > $accessB) { -1; }
         else {
          if ($byteA < $byteB) { 1; }
          elsif ($byteA > $byteB) { -1; } else { 0; }
         }
         } @hostLines;
      for ($i = 0; $i < $hostCnt{$dayMonYear}; $i++) {
        $hostLines{$dayMonYear,$i}=$hostSorted[$i];
      }

      # Stats
      $statCnt{$dayMonYear}=0;
      foreach $key (sort keys %statAccess) {
        if (($stat) = ($key =~ /^$dayMonYear:(.*)/)) {
          if (($bytes = $statBytes{$key}) eq "") { $bytes = 0; }
          $statLines{$dayMonYear,$statCnt{$dayMonYear}} = "S$stat $statAccess{$key} $bytes\n";
        }
        $statCnt{$dayMonYear}++;
      }

  } # end of foreach dayMonYears
}

#
# clear collection arrays
#
sub clearArrays {
  undef %hourAccess;
  undef %hourBytes;
  undef %urlAccess;
  undef %urlBytes;
  undef %hostAccess;
  undef %hostBytes;
  undef %statAccess;
  undef %statBytes;

  undef %pageAccess;
  undef %errorAccess;
  undef %eaCnt;

  undef %hourCnt;
  undef %urlCnt;
  undef %hostCnt;
  undef %statCnt;

  undef %hourLines;
  undef %urlLines;
  undef %hostLines;
  undef %statLines;

  undef %urlSorted;  
  undef %hostSorted;

}

######################################################################
#
# rebuild Log
#
sub rebuildLog {
local($hLogDir,$hLogFile,$ext) = @_;
local(@cmdLine,$cmdStr);
local($hFile);
local($orgHttpdLogDir,$orgHttpdLogFile);
local($orgUseCache);
$funcString="rebuildLog";

  $hLogDir =~ s/\/$//;

  # keep global variables
  $orgUseCache = $useCache;
  $orgHttpdLogDir = $httpdLogDir;
  $orgHttpdLogFile = $httpdLogFile;

  # set httpd log directory for makeCollection
  $useCache = 0;
  $httpdLogDir = $temporaryDir;

  # open archive directory
  if (opendir(ARCDIR,$hLogDir)) {
  
    foreach $hFile (
     sort {
       if ($a lt $b) { 1;} elsif ($a gt $b) { -1;} else { 0;}
     } readdir(ARCDIR)) {
      # check the file name
      if (($hFile =~ /^$hLogFile/) && ($hFile =~ /$ext$/)) {
        # check the extension
        if ($ext eq ".gz") {
          $cmdStr = "$gunzip -c $hLogDir$dirSp$hFile > ${temporaryDir}hlog.$$";
          if (!system $cmdStr) {
            sleep(1);
            $httpdLogFile = "hlog.$$";
            &makeCollection();
          } else {
            &outError("cannot exec uncompress command");
          }
          unlink("${temporaryDir}hlog.$$");
        } else {
          &outError("unmatch the file extention");
        }
      }
    }

    closedir(ARCDIR);
  } else {
    $funcString="rebuildLog";
    &outError("cannot open archive directory ($hLogDir)");
  }

  # restore global variables
  $useCache = $orgUseCache;
  $httpdLogDir = $orgHttpdLogDir;
  $httpdLogFile = $orgHttpdLogFile;
}

#
# rotate http-log
#
sub rotateHttpLog {
local($hLogDir,$hLogFile,$ext) = @_;
local(@cmdLine,$cmdStr);
local($hFile,$num,$num2,$hFile2);
local($orgHttpdLogDir,$orgHttpdLogFile);
local($orgUseCache);
$funcString="rotateHttpLog";

  $hLogDir =~ s/\/$//;

  # keep global variables
  $orgUseCache = $useCache;
  $orgHttpdLogDir = $httpdLogDir;
  $orgHttpdLogFile = $httpdLogFile;

  # set httpd log directory for makeCollection
  $useCache = 0;
  $httpdLogDir = $temporaryDir;

  # open archive directory
  if (opendir(ARCDIR,$hLogDir)) {

    foreach $hFile (
     sort {
       if ($a lt $b) { 1;} elsif ($a gt $b) { -1;} else { 0;}
     } readdir(ARCDIR)) {
      # check the file name
      if (($hFile =~ /^$hLogFile/)) {
        # check the extension
        if (($hFile =~ /$ext$/) && ($ext eq ".gz")) { # rotate log
          ($num) = ($hFile =~ /^$hLogFile\.(\d+)$ext$/);
          $num2 = $num;
          $num2++;
          $hFile2 = "$hLogDir$dirSp$hLogFile.$num2$ext";

          if (link("$hLogDir$dirSp$hFile",$hFile2)) {
            unlink("$hLogDir$dirSp$hFile");
            # sleep(1);
          } else {
            &outError("cannot link $hFile to $hFile2");
          }
        } elsif ($hFile =~ /^$hLogFile$/) {  # compress the currect log
          $hFile2 = "$hLogDir$dirSp$hLogFile.0";
          if (link("$hLogDir$dirSp$hLogFile",$hFile2)) {
            unlink("$hLogDir$dirSp$hLogFile");

            $cmdStr = "$gzip $hFile2";
            if (system $cmdStr) {
              &outError("cannot exec gzip\n");
            } else {
              open(TMPFP,">>$hLogDir$dirSp$hLogFile");
              close(TMPFP);
            }
          } else {
            &outError("cannot link $hLogFile to $hFile2");
          }
        } else {
          &outError("unmatch the file extention");
        }
      }
    }

    closedir(ARCDIR);
  } else {
    $funcString="rotateHttpLog";
    &outError("cannot open archive directory ($hLogDir)");
  }

  # restore global variables
  $useCache = $orgUseCache;
  $httpdLogDir = $orgHttpdLogDir;
  $httpdLogFile = $orgHttpdLogFile;
}
