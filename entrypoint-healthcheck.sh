#!/bin/bash
exec gosu "${USERNAME}" /app/*server monitor || exit 1
