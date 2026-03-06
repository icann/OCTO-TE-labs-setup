<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8" />
    <title>grp%group% network</title>
    <style type="text/css">
        body { text-align:center; margin-left: 25%; margin-right: 25%; width: 50%; min-width: 1000px;}
    </style>
</head>
<body>
    <h1>grp%group% network</h1>
    <p>This is the network topology for your group (X=%group%)</p>
    <p>Lab: %AuthDomain%</p>
    <p><a href="instructions" target="_blank" rel="noopener noreferrer">Lab instructions</a></p>
    <hr />

    <img src="../_img/labtype1.png" width="960" height="540" border="0" usemap="#network_map" />

    <map name="network_map">
        <area shape="rect" coords="433,121,464,168" href="https://webssh.%AuthDomain%/?hostname=%ip4cli%&username=%username4cli%&password=%password4cli%" alt="cli" target="_blank" rel="noopener noreferrer" />
        <area shape="rect" coords="480,233,534,273" href="https://webssh.%AuthDomain%/?hostname=%ip4resolv1%&username=%username4resolv1%&password=%password4resolv1%" alt="resolv1" target="_blank" rel="noopener noreferrer" />
        <area shape="rect" coords="629,231,684,274" href="https://webssh.%AuthDomain%/?hostname=%ip4resolv2%&username=%username4resolv2%&password=%password4resolv2%" alt="resolv2" target="_blank" rel="noopener noreferrer" />
    </map>
</body>
</html>
