<!DOCTYPE html>

<head>
    <meta charset="utf-8" />
    <meta name="generator" content="pandoc" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=yes" />
    <meta name="author" content="Nicolas Antoniello @ICANN" />
    <title>grp%group% network</title>
    <style type="text/css">
        body { text-align:center; margin-left: 25%; margin-right: 25%; width: 50%; min-width: 1000px;}
        code{white-space: pre-wrap;}
        span.smallcaps{font-variant: small-caps;}
        span.underline{text-decoration: underline;}
        div.column{display: inline-block; vertical-align: top; width: 50%;}
        div.success{ width: 100%; background:#00AA00; text-align: center; font-size: 20px; line-height: 40px; border-radius: 25px;  display: inline-block; }
        textarea {width: 900px; height: 100px;}
    </style>
</head>
<body>
  <header id="title-block-header">
  <h1 class="title">grp%group% network</h1>
  <p class="subtitle">This is the network topology for your group (X=%group%)</p>
  <p class="author">Lab: %AuthDomain%</p>
  </header>
  <hr />

<img src="../_img/grp_network_map.png" width="960" height="540" border="0" usemap="#grp%group%_network_map" />

<map name="grp%group%_network_map">
<!-- #$-:Image map file created by GIMP Image Map plug-in -->
<!-- #$-:GIMP Image Map plug-in by Maurits Rijk -->
<!-- #$-:Please do not edit lines starting with "#$" -->
<!-- #$VERSION:2.3 -->
<!-- #$AUTHOR:Nicolas Antoniello -->
<%commentCLI%area shape="rect" coords="433,121,464,168" href="https://webssh.%AuthDomain%/?hostname=%ip4cli%&username=%username4cli%&password=%password4cli%" alt="cli" target="_blank" rel="noopener noreferrer" /%commentCLIeol%>
<%commentSOA%area shape="rect" coords="344,232,374,274" href="https://webssh.%AuthDomain%/?hostname=%ip4soa%&username=%username4soa%&password=%password4soa%" alt="soa" target="_blank" rel="noopener noreferrer" /%commentSOAeol%>
<area shape="rect" coords="480,233,534,273" href="https://webssh.%AuthDomain%/?hostname=%ip4resolv1%&username=%username4resolv1%&password=%password4resolv1%" alt="resolv1" target="_blank" rel="noopener noreferrer" />
<area shape="rect" coords="629,231,684,274" href="https://webssh.%AuthDomain%/?hostname=%ip4resolv2%&username=%username4resolv2%&password=%password4resolv2%" alt="resolv2" target="_blank" rel="noopener noreferrer" />
<%commentNS1%area shape="rect" coords="257,342,285,384" href="https://webssh.%AuthDomain%/?hostname=%ip4ns1%&username=%username4ns1%&password=%password4ns1%" alt="ns1" target="_blank" rel="noopener noreferrer" /%commentNS1eol%>
<%commentNS2%area shape="rect" coords="435,342,464,385" href="https://webssh.%AuthDomain%/?hostname=%ip4ns2%&username=%username4ns2%&password=%password4ns2%" alt="ns2" target="_blank" rel="noopener noreferrer" /%commentNS2eol%>
<%commentRTR%area shape="circle" coords="246,195,20" href="https://webssh.%AuthDomain%/?hostname=%ip4rtr%&username=%username4rtr%&password=%password4rtr%" alt="rtr" target="_blank" rel="noopener noreferrer" /%commentRTReol%>
</map>
<hr>
<h1> Update your DS records! </h1>
<?php
// strip slashes before putting the form data into target file
$cd = stripslashes($_POST['dsrecords']);

// Show the msg, if the code string is empty
if (!empty($cd)) {
	$tmpfname = tempnam("/tmp", "");
	$file = fopen($tmpfname, "w");
 	fwrite($file, $cd);
   fclose($file);
   rename($tmpfname, $tmpfname.".DS");
   echo "<div class=\"success\">Your DS record(s) are submitted</div>";
}
?>
<form action="%url%" method="post">
  <p><label for="dsrecords">One DS record per line</label></p>
  <textarea id="dsrecords" name="dsrecords"></textarea>
  <br>
  <input type="submit" value="Submit">
</form>
</body>
</html>
