#!/bin/bash
exec gosu "${USER}" /app/*server monitor || exit 1
