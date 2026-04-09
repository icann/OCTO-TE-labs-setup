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

    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 500 250" >
        <defs>
            <!-- symbols code in this file is licensed under the MIT license -->
            <symbol id="router" viewBox="0 0 36 36">
                <path d="M18,1.67a16,16,0,1,0,16,16A16,16,0,0,0,18,1.67ZM13.86,9.92a.8.8,0,0,1,1.13,0l2.21,2.19V5.93a.8.8,0,0,1,1.6,0v6.18L21,9.92a.8.8,0,1,1,1.13,1.14L18,15.15l-4.14-4.1A.8.8,0,0,1,13.86,9.92ZM10.32,21.74a.8.8,0,0,1-1.13,0L5,17.67l4.19-4.09a.8.8,0,1,1,1.12,1.14l-2.2,2.14h6.27a.8.8,0,0,1,0,1.6H8.11l2.2,2.15A.8.8,0,0,1,10.32,21.74Zm11.82,3.67a.8.8,0,0,1-1.13,0L18.8,23.23V29.4a.8.8,0,0,1-1.6,0V23.23L15,25.42a.8.8,0,1,1-1.13-1.14L18,20.18l4.14,4.1A.8.8,0,0,1,22.14,25.41Zm4.67-3.66a.8.8,0,1,1-1.12-1.14l2.2-2.15H21.63a.8.8,0,0,1,0-1.6h6.27l-2.2-2.14a.8.8,0,1,1,1.12-1.14L31,17.67Z" class="clr-i-solid clr-i-solid-path-1"></path>
            </symbol>

            <symbol id="server" viewBox="0 0 36 36">
                <path d="M20.5 8.5V5.5C20.5 5.23478 20.3946 4.98043 20.2071 4.79289C20.0196 4.60536 19.7652 4.5 19.5 4.5H4.5C4.23478 4.5 3.98043 4.60536 3.79289 4.79289C3.60536 4.98043 3.5 5.23478 3.5 5.5V8.5C3.5 8.76522 3.60536 9.01957 3.79289 9.20711C3.98043 9.39464 4.23478 9.5 4.5 9.5C4.23478 9.5 3.98043 9.60536 3.79289 9.79289C3.60536 9.98043 3.5 10.2348 3.5 10.5V13.5C3.5 13.7652 3.60536 14.0196 3.79289 14.2071C3.98043 14.3946 4.23478 14.5 4.5 14.5C4.23478 14.5 3.98043 14.6054 3.79289 14.7929C3.60536 14.9804 3.5 15.2348 3.5 15.5V18.5C3.5 18.7652 3.60536 19.0196 3.79289 19.2071C3.98043 19.3946 4.23478 19.5 4.5 19.5H19.5C19.7652 19.5 20.0196 19.3946 20.2071 19.2071C20.3946 19.0196 20.5 18.7652 20.5 18.5V15.5C20.5 15.2348 20.3946 14.9804 20.2071 14.7929C20.0196 14.6054 19.7652 14.5 19.5 14.5C19.7652 14.5 20.0196 14.3946 20.2071 14.2071C20.3946 14.0196 20.5 13.7652 20.5 13.5V10.5C20.5 10.2348 20.3946 9.98043 20.2071 9.79289C20.0196 9.60536 19.7652 9.5 19.5 9.5C19.7652 9.5 20.0196 9.39464 20.2071 9.20711C20.3946 9.01957 20.5 8.76522 20.5 8.5ZM19.5 18.5H4.5V15.5H19.5V18.5ZM19.5 13.5H4.5V10.5H19.5V13.5ZM19.5 8.5H4.5V5.5H19.5V8.5Z"/>
                <path d="M6.25 7.75C6.66421 7.75 7 7.41421 7 7C7 6.58579 6.66421 6.25 6.25 6.25C5.83579 6.25 5.5 6.58579 5.5 7C5.5 7.41421 5.83579 7.75 6.25 7.75Z"/>
                <path d="M8.75 7.75C9.16421 7.75 9.5 7.41421 9.5 7C9.5 6.58579 9.16421 6.25 8.75 6.25C8.33579 6.25 8 6.58579 8 7C8 7.41421 8.33579 7.75 8.75 7.75Z"/>
                <path d="M6.25 12.75C6.66421 12.75 7 12.4142 7 12C7 11.5858 6.66421 11.25 6.25 11.25C5.83579 11.25 5.5 11.5858 5.5 12C5.5 12.4142 5.83579 12.75 6.25 12.75Z"/>
                <path d="M8.75 12.75C9.16421 12.75 9.5 12.4142 9.5 12C9.5 11.5858 9.16421 11.25 8.75 11.25C8.33579 11.25 8 11.5858 8 12C8 12.4142 8.33579 12.75 8.75 12.75Z"/>
                <path d="M6.25 17.75C6.66421 17.75 7 17.4142 7 17C7 16.5858 6.66421 16.25 6.25 16.25C5.83579 16.25 5.5 16.5858 5.5 17C5.5 17.4142 5.83579 17.75 6.25 17.75Z"/>
                <path d="M8.75 17.75C9.16421 17.75 9.5 17.4142 9.5 17C9.5 16.5858 9.16421 16.25 8.75 16.25C8.33579 16.25 8 16.5858 8 17C8 17.4142 8.33579 17.75 8.75 17.75Z"/>
            </symbol>
        </defs>

        <!--
        !!!!!!!!!!!!!!!!  ATTENTION !!!!!!!!!!!!!!!!
        
        Any changes to these diagram needs to be 
        reflected in the lab instructions as well
        
        -->
        
        <!-- net-bb -->

        <path style="fill: none; stroke: rgb(255, 0,   0); stroke-width: 3px;" d="M  50  38 L 470  38"/>
        <path style="fill: none; stroke: rgb(255, 0,   0); stroke-width: 3px;" d="M 100  83 L 100  38"/>

        <use href="#router" x="30" y="26" width="24" height="24" fill="#000080"/>
        <text style="fill: rgb(255, 0, 0); font-family: Arial, sans-serif; font-size: 8px; white-space: pre;" x="55" y="33" >.1 | ::1</text>

        <text style="fill: rgb(255, 0, 0); font-family: Arial, sans-serif; font-size: 8px; white-space: pre; text-anchor: middle;" x="150" y="10" >iborder-rtr</text>
        <use href="#router" x="142" y="10" width="16" height="16" fill="#ff0000"/>
        <text style="fill: rgb(255, 0, 0); font-family: Arial, sans-serif; font-size: 8px; white-space: pre; text-anchor: middle;" x="150" y="32" >.10 | ::10</text>

        <text style="fill: rgb(255, 0, 0); font-family: Arial, sans-serif; font-size: 8px; white-space: pre; text-anchor: middle;" x="230" y="10" >rpki1</text>
        <use href="#server" x="220" y="10" width="24" height="24" fill="#ff0000"/>
        <text style="fill: rgb(255, 0, 0); font-family: Arial, sans-serif; font-size: 8px; white-space: pre; text-anchor: middle;" x="230" y="32" >.70 | ::70</text>

        <text style="fill: rgb(255, 0, 0); font-family: Arial, sans-serif; font-size: 8px; white-space: pre; text-anchor: middle;" x="310" y="10" >rpki2</text>
        <use href="#server" x="300" y="10" width="24" height="24" fill="#ff0000"/>
        <text style="fill: rgb(255, 0, 0); font-family: Arial, sans-serif; font-size: 8px; white-space: pre; text-anchor: middle;" x="310" y="32" >.71 | ::71</text>

        <text style="fill: rgb(255, 0, 0); font-family: Arial, sans-serif; font-size: 8px; white-space: pre; text-anchor: end;" x="470" y="25" >100.100.0.0/22</text>
        <text style="fill: rgb(255, 0, 0); font-family: Arial, sans-serif; font-size: 8px; white-space: pre; text-anchor: end;" x="470" y="33" >%IPv6pfx%:0::/48</text>

        <text style="fill: rgb(255, 0, 0); font-family: Arial, sans-serif; font-size: 8px; white-space: pre; text-anchor: end;" x="95" y="80" >.1.%GRP% | 1::%GRP%</text>

        <!-- LAN -->

        <path style="fill: none; stroke: rgb(0,   0, 128); stroke-width: 3px;" d="M 108  93 L 470  93"/>

        <a href="https://webssh.%AuthDomain%/?hostname=%ip4rtr%&amp;username=%username4rtr%&amp;password=%password4rtr%" alt="rtr" target="_blank" rel="noopener noreferrer">
            <rect x="222" y="65" width="24" height="24" fill="transparent"/>
            <use href="#router" x="87" y="80" width="24" height="24" fill="#000080"/>
        </a>
        <text style="fill: rgb(0, 0, 128); font-family: Arial, sans-serif; font-size: 8px; white-space: pre;" x="110" y="88" >.1 | ::1</text>

        <text style="fill: rgb(0, 0, 128); font-family: Arial, sans-serif; font-size: 8px; white-space: pre; text-anchor: middle;" x="230" y="65" >cli</text>
        <a href="https://webssh.%AuthDomain%/?hostname=%ip4cli%&amp;username=%username4cli%&amp;password=%password4cli%" alt="cli" target="_blank" rel="noopener noreferrer">
            <rect x="222" y="65" width="24" height="24" fill="transparent"/>
            <use href="#server" x="222" y="65" width="24" height="24" fill="#000080"/>
        </a>
        <text style="fill: rgb(0, 0, 128); font-family: Arial, sans-serif; font-size: 8px; white-space: pre; text-anchor: middle;" x="230" y="88" >.2 | ::2</text>

        <text style="fill: rgb(0, 0, 128); font-family: Arial, sans-serif; font-size: 8px; white-space: pre; text-anchor: end;" x="470" y="80" >100.100.%GRP%.0/26</text>
        <text style="fill: rgb(0, 0, 128); font-family: Arial, sans-serif; font-size: 8px; white-space: pre; text-anchor: end;" x="470" y="88" >%IPv6pfx%:%GRP%:0::/64</text>
        <text style="fill: rgb(0, 0, 128); font-family: Arial, sans-serif; font-size: 8px; white-space: pre; text-anchor: end;" x="470" y="102" >LAN</text>

        <!-- INTERNAL -->

        <path style="fill: none; stroke: rgb(192, 0, 128); stroke-width: 3px;" d="M 103 102 L 130 155 L 470 155"/>

        <text style="fill: rgb(192, 0, 128); font-family: Arial, sans-serif; font-size: 8px; white-space: pre;" x="110" y="110" >.65 | ::1</text>

        <text style="fill: rgb(192, 0, 128); font-family: Arial, sans-serif; font-size: 8px; white-space: pre; text-anchor: end;" x="470" y="142" >100.100.%GRP%.64/26</text>
        <text style="fill: rgb(192, 0, 128); font-family: Arial, sans-serif; font-size: 8px; white-space: pre; text-anchor: end;" x="470" y="150" >%IPv6pfx%:%GRP%:64::/64</text>
        <text style="fill: rgb(192, 0, 128); font-family: Arial, sans-serif; font-size: 8px; white-space: pre; text-anchor: end;" x="470" y="164" >Internal</text>

        <!-- DMZ -->

        <path style="fill: none; stroke: rgb(0, 100,   0); stroke-width: 3px;" d="M 100 102 L 100 155 L 130 230 L 470 230"/>

        <text style="fill: rgb(0, 100, 0); font-family: Arial, sans-serif; font-size: 8px; white-space: pre; text-anchor: end;" x="95" y="110" >.129 | ::1</text>

        <text style="fill: rgb(0, 100, 0); font-family: Arial, sans-serif; font-size: 8px; white-space: pre; text-anchor: end;" x="470" y="217" >100.100.%GRP%.128/26</text>
        <text style="fill: rgb(0, 100, 0); font-family: Arial, sans-serif; font-size: 8px; white-space: pre; text-anchor: end;" x="470" y="225" >%IPv6pfx%:%GRP%:128::/64</text>
        <text style="fill: rgb(0, 100, 0); font-family: Arial, sans-serif; font-size: 8px; white-space: pre; text-anchor: end;" x="470" y="239" >DMZ</text>

        <!-- network done -->
    </svg>    
</body>
</html>
