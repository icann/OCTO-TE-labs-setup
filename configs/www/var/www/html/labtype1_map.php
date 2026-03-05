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

<img src="../_img/labtype1.png" width="960" height="540" border="0" usemap="#network_map" />

<map name="network_map">
    <area shape="rect" coords="433,121,464,168" href="https://webssh.%AuthDomain%/?hostname=%ip4cli%&username=%username4cli%&password=%password4cli%" alt="cli" target="_blank" rel="noopener noreferrer" />
    <area shape="rect" coords="480,233,534,273" href="https://webssh.%AuthDomain%/?hostname=%ip4resolv1%&username=%username4resolv1%&password=%password4resolv1%" alt="resolv1" target="_blank" rel="noopener noreferrer" />
    <area shape="rect" coords="629,231,684,274" href="https://webssh.%AuthDomain%/?hostname=%ip4resolv2%&username=%username4resolv2%&password=%password4resolv2%" alt="resolv2" target="_blank" rel="noopener noreferrer" />
</map>
</body>
</html>
