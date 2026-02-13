#!/bin/bash
cd /c/EMS/Terraform/timescaledb-complete-course || exit
git add .
git commit -m "Auto-sync: $(date '+%Y-%m-%d %H:%M:%S')"
git push origin main --force
