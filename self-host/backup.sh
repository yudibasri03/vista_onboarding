#!/usr/bin/env bash
#
# Backup harian database self-hosted Supabase.
# WAJIB di self-host: tidak ada yang backup untukmu.
#
# Pasang di cron (jam 2 pagi tiap hari), edit path lalu:
#   crontab -e
#   0 2 * * * /path/ke/self-host/backup.sh >> /var/log/supabase-backup.log 2>&1
#
set -euo pipefail

# --- konfigurasi ---
SUPABASE_DOCKER_DIR="/root/supabase/docker"   # folder docker-compose Supabase
BACKUP_DIR="/root/backups"                      # folder tujuan backup
RETENTION_DAYS=14                               # simpan backup 14 hari terakhir
DB_CONTAINER="supabase-db"                       # nama service/container Postgres
# -------------------

mkdir -p "$BACKUP_DIR"
STAMP="$(date +%Y%m%d-%H%M%S)"
OUT="$BACKUP_DIR/supabase-$STAMP.sql.gz"

cd "$SUPABASE_DOCKER_DIR"

# Dump seluruh database (termasuk schema auth & storage) lalu gzip.
docker compose exec -T "$DB_CONTAINER" pg_dumpall -U postgres | gzip > "$OUT"

echo "[$(date)] Backup selesai: $OUT ($(du -h "$OUT" | cut -f1))"

# Hapus backup yang lebih tua dari RETENTION_DAYS
find "$BACKUP_DIR" -name 'supabase-*.sql.gz' -mtime +"$RETENTION_DAYS" -delete

echo "[$(date)] Backup lama (> $RETENTION_DAYS hari) dibersihkan."

# TIP: sesekali salin $BACKUP_DIR ke lokasi lain (S3/Backblaze/komputer lokal)
# supaya aman kalau VPS-nya bermasalah.
