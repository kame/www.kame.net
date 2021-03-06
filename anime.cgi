#! /usr/bin/env perl

if ($ENV{'REMOTE_ADDR'} =~ /^[0-9a-f:]+$/i
    && $ENV{'REMOTE_ADDR'} !~ /2001:200:d00:100::/ # 2001:200:d00:100:: is IPv4 mapping prefix on WIDE cloud
    ) {
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
<div id="canvas" style="display: none;"><canvas id="anime" width="124" height="100"></canvas></div>
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
  \$('div#canvas').show();
  var ctx;
  var img = new Array();
  var count = 0;
  var max = 17;
  ctx = canvas.getContext('2d');
  for (i = 0; i <= max; i++) {
    img[i] = new Image();
    img[i].src = "/img/anime/kame-anime-small-" + i + ".png";
  }
  if ( /Android\s2\.[0|1]/.test(navigator.userAgent)) {
    // ugly hack for Android2.0/2.1
    var rate = Math.sqrt(320 / screen.width);
    ctx.scale(rate, rate);
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
<a href="/kame-mosaic.html">the dancing kame</a>
EOF
}
exit 0;
