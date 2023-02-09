#!/usr/bin/with-contenv bas
exec s6-setuidgid ${USERNAME} /linuxgsm/*server monitor || exit 1
