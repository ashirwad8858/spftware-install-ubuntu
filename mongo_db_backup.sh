#!/bin/bash

# Get current date and time
current_date=$(date +"%Y-%m-%d_%H-%M-%S")

# Directory name for backup
backup_dir="bk_$current_date"

# Run mongodump command
mongodump --host localhost --port 27017 --username root --password 'example' --out "$backup_dir"
