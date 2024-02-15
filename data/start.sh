#!/bin/sh

# Starte den Cron-Dienst
crond

# Starte Nginx im Vordergrund
nginx -g 'daemon off;'
