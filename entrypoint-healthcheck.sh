#!/bin/bash
exec gosu ${USERNAME} /linuxgsm/*server monitor || exit 1
