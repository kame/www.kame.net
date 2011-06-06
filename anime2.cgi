#! /usr/bin/env perl

if ($ENV{'REMOTE_ADDR'} !~ /2001:200:d00:100::/) {
	$v6p = 'yes';
}

print "Content-type: text/html\n\n";

$| = 1;
if (0) {
	print <<EOF;
<img src="/img/kame-noanime-small.gif" alt="Non-dancing kame" /><br />
sorry www.kame.net is IPv4 only due to trouble, and dancing kame service is suspended...
EOF
} elsif ($v6p) {
	print <<EOF;
<canvas id="anime" width="124" height="100"></canvas>
<img id="gif" src="/img/kame-anime-small.gif" alt="Dancing kame" /><br />
Dancing kame by <a href="http://www.momonga.org/">atelier momonga</a>

<script type="text/JavaScript">
<!--
\$(document).ready(function() {
  var canvas = document.getElementById('anime');
  if (! canvas || ! canvas.getContext) {
    return false;
  }
  \$('img#gif').remove();
  var ctx;
  var img = new Array();
  var count = 0;
  var max = 17;
  ctx = canvas.getContext('2d');
  for (i = 0; i <= max; i++) {
    img[i] = new Image();
    img[i].src = "/img/anime/kame-anime-small-" + i + ".png";
  }
  // xxx: img[max] should not be the last session. other sessions may be delayed
  img[max].onload = function() {
    setInterval(function() {
      ctx.clearRect(0, 0, 124, 100)
      ctx.drawImage(img[count], 0, 0);
      count++;
      if (count > max) {
        count = 0;
      }
    }, 100);
  }
});
// -->
</script>
EOF
} else {
	print <<EOF;
<img src="/img/kame-noanime-small.gif" alt="Non-dancing kame" /><br />
Use IPv6 HTTP and you will watch
<a href="/canvas4.html">the dancing kame</a>
EOF
}
exit 0;
