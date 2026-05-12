<?php
$ip = $_SERVER['REMOTE_ADDR'] ?? '';

header('Content-Type: text/plain; charset=UTF-8');
if (filter_var($ip, FILTER_VALIDATE_IP, FILTER_FLAG_IPV4)) {
    echo "You connected over IPv4\n";
} elseif (filter_var($ip, FILTER_VALIDATE_IP, FILTER_FLAG_IPV6)) {
    echo "You connected over IPv6\n";
} else {
    http_response_code(500);
    echo "No idea how you connected\n";
}
