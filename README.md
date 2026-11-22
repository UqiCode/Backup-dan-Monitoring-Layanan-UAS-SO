# SysGuard — Backup & Monitoring Layanan

Proyek Akhir Praktikum Sistem Operasi, **Pilihan A: Backup dan Monitoring Layanan**.
Kelas / Kelompok: [Kelas B / Kelompok ]

## Tujuan

SysGuard adalah solusi administrasi Linux dengan dua modul yang saling terhubung:

1. **Monitoring**: memeriksa status layanan (nginx) dan kapasitas disk, lalu melaporkan status OK, WARNING, atau CRITICAL beserta log.
2. **Backup & Restore**: mencadangkan data simulasi menjadi arsip dengan checksum SHA-256, lalu memulihkannya. Restore menolak arsip yang checksum-nya tidak cocok.

**Integrasi:** hasil monitoring menentukan apakah backup dilanjutkan atau dibatalkan (`run_backup_safe.sh`).

**Akses aman:** container dapat diakses lewat SSH hanya dengan key, memakai user non-root `sysguard`. Password dan login root dimatikan.

Seluruh data adalah **data simulasi**. Tidak ada data sistem atau data pribadi yang disentuh.

## Kebutuhan Lingkungan

- Windows 10/11 dengan WSL 2 dan distro Ubuntu
- Docker Desktop (WSL integration untuk Ubuntu menyala)
- Bash, Git, klien SSH (`ssh`, `ssh-keygen`)
- nginx di Ubuntu (hanya untuk menguji script langsung di host): jalankan `sudo apt-get install -y nginx`

## Struktur Repo

```
source/
  scripts/   monitor.sh, backup.sh, restore.sh, run_backup_safe.sh
  data/      config.conf, users.txt (data simulasi)
  docker/    Dockerfile, authorized_keys (public key SSH)
evidence/    screenshot dan log hasil pengujian
README.md
Laporan-Pengujian.pdf
Slide-Presentasi.pdf
```

## Arsitektur dan Pembagian Komponen Host/Container

```
Windows
 └─ WSL 2 (Ubuntu) ............................ HOST (tempat bekerja)
      ├─ Git, repo, editor
      ├─ key SSH privat (~/sysguard_key, di luar repo)
      ├─ script, diuji langsung di host
      └─ docker CLI ─► Docker Desktop (engine)
                          │
                          ▼
              ┌───────────────────────────────────────┐
              │ sysguard-container                    │ CONTAINER
              │  nginx (port 80)   sshd (port 22)     │
              │  /app/source/scripts                  │
              │  /app/source/data ◄───────────────────┼── volume sysguard-data
              │  /app/backups     ◄───────────────────┼── volume sysguard-backups
              │  batas 0.5 CPU, 256 MB                │
              └───────────────────────────────────────┘
        jaringan: sysguard-net | host 8080 -> 80, host 2222 -> 22
```

| Komponen | Lokasi | Keterangan |
|---|---|---|
| Git, repo, berkas Dockerfile | Host | Pengembangan dan pengumpulan |
| Key SSH privat | Host (`~/sysguard_key`) | Tidak masuk repo |
| Docker Desktop (engine) | Host | Membangun image dan menjalankan container |
| Image `sysguard-app` | Dibangun dari Dockerfile | Ubuntu 22.04, nginx, openssh-server, script, data simulasi |
| nginx (layanan yang dipantau) | Host (uji monitoring) dan container | Layanan contoh |
| Script | Host dan container | Di container berada di `/app/source/scripts` |
| Data simulasi | Volume `sysguard-data` di `/app/source/data` | Tetap ada saat container dibuat ulang |
| Arsip backup | Volume `sysguard-backups` di `/app/backups` | Tetap ada saat container dibuat ulang |
| sshd, user `sysguard`, public key | Container | Login hanya dengan key |
| Batas CPU/memori, network | Opsi `docker run` | Diterapkan Docker pada container |

Struktur folder di container sama dengan struktur repo (`source/scripts`, `source/data`), dan direktori kerja container adalah `/app`. Karena itu script berjalan di container tanpa diubah.

## Instalasi

```bash
git clone https://github.com/UqiCode/Backup-dan-Monitoring-Layanan-UAS-SO.git
cd Backup-dan-Monitoring-Layanan-UAS-SO
chmod +x source/scripts/*.sh   # beri izin eksekusi (tanpa ini muncul "Permission denied", kode 126)

# key SSH (private key tetap di host, jangan di-commit)
[ -f ~/sysguard_key ] || ssh-keygen -t rsa -b 4096 -f ~/sysguard_key -N ""
cp ~/sysguard_key.pub source/docker/authorized_keys

docker build -t sysguard-app -f source/docker/Dockerfile .
```

`authorized_keys` berisi public key dan aman disimpan di repo. Perintah `cp` di atas menimpa public key bawaan repo dengan public key milikmu; jangan di-commit.

## Menjalankan

```bash
docker network create sysguard-net
docker volume create sysguard-data
docker volume create sysguard-backups

docker run -d --name sysguard-container \
  --network sysguard-net \
  --memory="256m" --cpus="0.5" \
  -v sysguard-data:/app/source/data \
  -v sysguard-backups:/app/backups \
  -p 8080:80 -p 2222:22 \
  sysguard-app
```

Container tidak berjalan sebagai privileged dan tidak memasang Docker socket.

### Setelah komputer dimatikan atau dihidupkan ulang

Image, volume, dan container tetap tersimpan, tetapi container berhenti (status `Exited`). Buka Docker Desktop dan tunggu sampai siap, lalu:

```bash
docker ps -a                          # container terlihat, status Exited
docker start sysguard-container       # jalankan lagi (jangan docker run, nama sudah dipakai)
docker ps                             # status harus Up
sudo service nginx start              # nginx di host, untuk uji di host
```

## Menguji dan Memverifikasi

### Di container

```bash
docker ps
curl -I http://localhost:8080
docker exec sysguard-container ls /app/source/data
docker exec sysguard-container /app/source/scripts/monitor.sh nginx
docker exec sysguard-container /app/source/scripts/run_backup_safe.sh   # sehat -> backup jalan
docker exec sysguard-container ls /app/backups
```

### Akses aman (SSH)

```bash
# DIIZINKAN: dengan key, user sysguard
ssh -i ~/sysguard_key -p 2222 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    -o LogLevel=ERROR -o BatchMode=yes sysguard@localhost "whoami && ls /app/source/data"

# DITOLAK: tanpa key
ssh -p 2222 -o PubkeyAuthentication=no -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    -o LogLevel=ERROR -o BatchMode=yes sysguard@localhost "whoami"

# DITOLAK: root, meski memakai key
ssh -i ~/sysguard_key -p 2222 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    -o LogLevel=ERROR -o BatchMode=yes root@localhost "whoami"
```

Hasil yang diharapkan: perintah pertama menampilkan `sysguard` dan isi folder data. Dua perintah berikutnya menampilkan `Permission denied (publickey)`.

Ownership dan permission file SSH:

```bash
docker exec sysguard-container ls -ld /home/sysguard/.ssh
docker exec sysguard-container ls -l /home/sysguard/.ssh/authorized_keys
```

Yang diharapkan: pemilik `sysguard`, `.ssh` berizin `drwx------`, dan `authorized_keys` berizin `-rw-------`.

### Di host (dari root repo)

```bash
sudo service nginx start
./source/scripts/monitor.sh nginx                  # sehat: "System health OK"
./source/scripts/backup.sh                         # arsip + checksum di backups/
LATEST=$(ls -t backups/backup_*.tar.gz | head -1)
./source/scripts/restore.sh "$LATEST"              # hasil di restored/data
diff -r source/data restored/data && echo "DATA IDENTIK"

./source/scripts/run_backup_safe.sh                # monitoring OK -> backup jalan
sudo service nginx stop
./source/scripts/monitor.sh nginx                  # layanan mati -> WARNING, exit 1
./source/scripts/run_backup_safe.sh                # monitoring gagal -> backup dibatalkan
sudo service nginx start
```

Hasil restore berada di `restored/data`, bukan `restored/source/data`.

Pengujian gagal (jalankan setelah blok di atas karena memakai $LATEST):

```bash
./source/scripts/backup.sh ./folder-ngaco                  # sumber tidak ada -> exit 1
cp "$LATEST" backups/rusak.tar.gz && cp "$LATEST.sha256" backups/rusak.tar.gz.sha256
echo "rusak" >> backups/rusak.tar.gz
./source/scripts/restore.sh backups/rusak.tar.gz           # checksum tidak cocok -> ditolak
```

### Recovery (data hilang lalu dipulihkan)

```bash
./source/scripts/backup.sh
rm source/data/users.txt
ls source/data                                      # users.txt hilang
LATEST=$(ls -t backups/backup_*.tar.gz | head -1)
./source/scripts/restore.sh "$LATEST"
cp restored/data/users.txt source/data/
ls source/data                                      # users.txt kembali
```

Restore memverifikasi checksum lebih dulu. Setelah uji, kembalikan kondisi dengan `git checkout source/data` bila perlu.

### Persistensi

```bash
docker exec sysguard-container sh -c 'echo "bukti-persisten" > /app/source/data/persist.txt'
docker stop sysguard-container
docker rm sysguard-container
# jalankan ulang perintah docker run yang sama persis (bagian Menjalankan)
docker exec sysguard-container ls /app/source/data
docker exec sysguard-container cat /app/source/data/persist.txt   # harus masih ada
```

Bukti hasil pengujian ada di folder `evidence/`.

## Memantau

```bash
docker stats sysguard-container --no-stream
docker logs sysguard-container
docker inspect --format 'Memory={{.HostConfig.Memory}} NanoCpus={{.HostConfig.NanoCpus}}' sysguard-container
```

Nilai yang diharapkan: `Memory=268435456` (256 MB) dan `NanoCpus=500000000` (0,5 CPU). Log script ada di `/tmp/sysguard/` (di host maupun di dalam container).

## Cleanup

```bash
docker stop sysguard-container
docker rm sysguard-container
docker volume rm sysguard-data sysguard-backups   # menghapus data dan backup persisten
docker network rm sysguard-net
docker rmi sysguard-app
rm -rf backups restored
```

## Rollback

- **Data:** pulihkan dari backup dengan `./source/scripts/restore.sh <file_backup.tar.gz>` (di container: `docker exec sysguard-container /app/source/scripts/restore.sh /app/backups/<file>`). Checksum diverifikasi sebelum restore.
- **Container:** hapus dengan `docker rm`, lalu jalankan ulang dari image yang sama. Data tetap ada di volume.
- **Kode:** kembali ke versi final dengan `git checkout P2-FINAL-v01`.

## Keterbatasan

- Layanan mati menghasilkan status **WARNING** (kode keluar 1). Status **CRITICAL** hanya muncul bila layanan dan disk bermasalah bersamaan. Ambang disk tetap 90% dan kondisi disk penuh tidak disimulasikan.
- `run_backup_safe.sh` hanya memantau nginx.
- Mematikan nginx di dalam container akan menghentikan container (nginx adalah proses utamanya). Skenario "backup dibatalkan" karena itu diuji di host; di container diuji skenario sehat.
- Uji akses aman dilakukan dari host ke port 2222 dengan satu key. Tidak ada pembatasan percobaan login.
- Backup dijalankan manual tanpa jadwal otomatis. Pemantauan container manual lewat `docker stats` dan `docker logs`, tanpa alerting.
- Diuji hanya di WSL 2 dengan Docker Desktop.

## Kontribusi Anggota

| Anggota | Peran | Kontribusi |
|---|---|---|
| Muhammad Syauqi Rabbani / 2510501065 | A1 | Modul monitoring dan data simulasi |
| Adilah Azzahra / 2510501045 | A2 | Modul backup dan restore |
| Annisa Ayu Saleha / 2510501039 | A3 | Script integrasi monitoring-backup |
| Aulia Gitananda / 2510501048 | A4 | Docker: image, network, volume, resource limit, akses SSH berbasis key |
| Jelove Nadine / 2510501050 | A5 | Pengujian, laporan, slide, README |
