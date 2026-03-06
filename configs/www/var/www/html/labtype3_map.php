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

    <img src="../_img/labtype3.png" width="960" height="540" border="0" usemap="#network_map" />

    <map name="network_map">
        <area shape="rect" coords="435,198,462,222" href="https://webssh.%AuthDomain%/?hostname=%ip4cli%&username=%username4cli%&password=%password4cli%" alt="cli" target="_blank" rel="noopener noreferrer" />
        <area shape="circle" coords="246,255,16" href="https://webssh.%AuthDomain%/?hostname=%ip4rtr%&username=%username4rtr%&password=%password4rtr%" alt="rtr" target="_blank" rel="noopener noreferrer" />
    </map>
</body>
</html>
