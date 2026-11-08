#!/bin/sh
# Piwigo's LinuxServer image starts s6 as root and symlinks its writable
# directories into /app/www/public. TOS forbids root containers, so run the
# unmodified Piwigo code with PHP's built-in server as uid 1000 instead.
# local/, _data/, upload/ and galleries/ are mounted writable and persist the
# installer config, cache, uploads and the photo library.
set -u

for d in local _data upload galleries; do
    mkdir -p "/app/www/public/$d" 2>/dev/null || true
done

cd /app/www/public || exit 1
exec php -S 0.0.0.0:8080 -t /app/www/public
