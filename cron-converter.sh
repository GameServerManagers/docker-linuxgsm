#!/bin/bash

# Converts a given duration in minutes into a valid cron expression
# Outputs the cron string to stdout on success
# Returns 0 on success, 1 on invalid input or unrepresentable interval
convert_minutes_to_cron() {
  local input="$1"

  # Validate input: strictly positive integer
  if ! [[ "$input" =~ ^[1-9][0-9]*$ ]]; then
    return 1
  fi

  local minutes=$input

  # Minute intervals (< 60 min)
  if [ "$minutes" -lt 60 ]; then
    echo "*/${minutes} * * * *"
    return 0
  fi

  # Hour intervals (< 1440 min / 24 hrs)
  if [ "$minutes" -lt 1440 ]; then
    if [ "$((minutes % 60))" -ne 0 ]; then
      return 1
    fi

    local hours=$((minutes / 60))
    if [ "$hours" -gt 23 ]; then
      return 1
    fi

    echo "0 */${hours} * * *"
    return 0
  fi

  # # Exact 1 Year (525.600 min = 365 days)
  # if [ "$minutes" -eq 525600 ]; then
  #   echo "0 0 1 1 *"
  #   return 0
  # fi

  # # Exact 1 Month (43.200 min = 30 days)
  # if [ "$minutes" -eq 43200 ]; then
  #   echo "0 0 1 * *"
  #   return 0
  # fi

  # Day intervals (>= 1440 min)
  if [ "$((minutes % 1440))" -ne 0 ]; then
    return 1
  fi

  local days=$((minutes / 1440))
  # Cron day-of-month step cannot exceed 31
  if [ "$days" -gt 31 ]; then
    return 1
  fi

  echo "0 0 */${days} * *"
  return 0
}
