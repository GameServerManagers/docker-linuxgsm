#!/bin/bash
echo HEALTHCHECK
exec s6-setuidgid ${USERNAME} /linuxgsm/*server monitor
