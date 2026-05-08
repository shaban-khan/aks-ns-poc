while ($true) {
    docker run --rm busybox nslookup www.google.com
    Start-Sleep -Seconds 10
}