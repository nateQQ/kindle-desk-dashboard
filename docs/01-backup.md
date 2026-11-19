# 1. Back up your books

Plug the Kindle into the computer. It shows up as a USB drive named `Kindle`.

```bash
cp -R /Volumes/Kindle/documents ~/kindle-backup/
cp /Volumes/Kindle/system/version.txt ~/kindle-backup/       # firmware proof
ls /Volumes/Kindle/documents | grep -v '\.sdr$' > ~/kindle-backup/book-list.txt
```

Check the copy against the original:

```bash
diff -rq /Volumes/Kindle/documents ~/kindle-backup/documents && echo IDENTICAL
```

Keep the backup **outside any git repository**. Books are large and often not yours to publish.

Also copy `metadata.calibre` and `driveinfo.calibre` from the Kindle root if they exist.

## Full system image (optional, later)

A full image of the Kindle can only be taken **after** the jailbreak and KUAL are installed, and only on older models (the guides list Paperwhite 2/3, Kindle Touch 2/3, Voyage, Oasis 1). It is not required for this guide. See the Backing Up page on [kindlemodding.org](https://kindlemodding.org/).

Next: [2. Jailbreak](02-jailbreak.md).
