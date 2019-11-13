#!/bin/bash
NOW=$(date '+%Y-%m-%d-%H-%M-%S');
TARGETS=( '/home/mpoc' )
BACKUP_ROOT="/home/mpoc/windows-shared/backup"
EXCLUDE_LIST="${BACKUP_ROOT}/exclude-list.txt"
BACKUP_DIR="${BACKUP_ROOT}/backups/backup-${NOW}"

echo "$NOW: Beginning backup"
mkdir -p $BACKUP_DIR

for i in ${TARGETS[@]}; do
    if rsync --exclude-from ${EXCLUDE_LIST} -Ra --copy-links $i ${BACKUP_DIR}; then
        echo "Successfully backed up $i"
    else
        echo "Failed backing up $i"
        #echo "$NOW: Backup failed"
        #exit 1
    fi
done

if tar -czf "${BACKUP_DIR}.tar.gz" $BACKUP_DIR &> /dev/null; then
    rm -rf $BACKUP_DIR
    echo "Successfully compressed ${BACKUP_DIR}"
else
    rm -rf $BACKUP_DIR
    echo "Failed compressing ${BACKUP_DIR}.tar.gz"
    echo "$NOW: Backup failed"
    exit 1
fi

if gpg -o "${BACKUP_DIR}.tar.gz.gpg" --symmetric ${BACKUP_DIR}.tar.gz; then
    rm -rf ${BACKUP_DIR}.tar.gz
    echo "Successfully encrypted ${BACKUP_DIR}.tar.gz"
else
    rm -rf ${BACKUP_DIR}.tar.gz
    echo "Failed encrypting ${BACKUP_DIR}.tar.gz.gpg"
    echo "$NOW: Backup failed"
    exit 1
fi

if ln -sfn ${BACKUP_DIR}.tar.gz.gpg ${BACKUP_ROOT}/latest-backup.tar.gz.gpg; then
    echo "Successfully linked ${BACKUP_DIR}.tar.gz.gpg to ${BACKUP_ROOT}/latest-backup.tar.gz.gpg"
else
    echo "Failed linking ${BACKUP_DIR}.tar.gz.gpg to ${BACKUP_ROOT}/latest-backup.tar.gz.gpg"
    echo "$NOW: Backup failed"
    exit 1
fi

# To decrypt
#gpg -o backup-name.tar.gz -d backup-name.tar.gz.gpg
