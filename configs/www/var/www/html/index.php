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
    <p><a href="instructions" target="_blank" rel="noopener noreferrer">Lab instructions</a></p>
    <hr />
    <img src="topology%LABTYPE%.svg" alt="Network topology diagram" style="width:100%; height:auto;" />
    <hr />

    <?php if (%LABTYPE% == 2): ?>
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
        <hr>
        <h1> Delete your DS records! </h1>
        <?php
        // strip slashes before putting the form data into target file
        $rmrec = stripslashes($_POST['rmdsrecords']);

        // Show the msg, if the code string is empty
        if (!empty($rmrec)) {
            $tmpfname = tempnam("/tmp", "");
            $file = fopen($tmpfname, "w");
            fwrite($file, "$rmrec");
        fclose($file);
        rename($tmpfname, $tmpfname.".DEL");
        echo "<div class=\"success\">Your DS record(s) will be deleted</div>";
        }
        ?>
        <form action="%url%" method="post">
        <input type="hidden" name="rmdsrecords" value="grp%group%.%AuthDomain%"></textarea>
        <br>
        <input type="submit" value="Delete all DS records">
        </form>
    <?php endif; ?>
    </body>
</html>
