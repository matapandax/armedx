# Arsitektur Open edX Koa via SSH Clone

Dokumen ini untuk jalur deploy yang lebih mudah diaudit: VM dibuat dulu, lalu repo ini di-clone dari dalam SSH VM, kemudian installer Koa dijalankan manual.

## Alur Arsitektur

```text
Azure Resource Group
  -> Ubuntu 20.04 VM
  -> Network Security Group
       - 22 untuk SSH
       - 80 untuk LMS
       - 18010 untuk Studio/CMS jika tidak memakai reverse proxy
  -> Public IP atau Traffic Manager host

SSH VM
  -> git clone repo enialrahs
  -> ./utils/install/install-openedx-koa-ssh.sh
  -> openedx-unsupported/configuration open-release/koa.master
  -> /var/tmp/configuration
  -> /edx service stack
```

## Sumber Koa

- Configuration repo: `https://github.com/openedx-unsupported/configuration`
- Branch: `open-release/koa.master`
- Installer lokal: `utils/install/install-openedx-koa-ssh.sh`
- Working directory di VM: `~/openedx-koa-install`
- Log utama: `~/openedx-koa-install/install.out`

Script installer tetap mengambil `util/install/native.sh` dari branch Koa tersebut, lalu patch clone internalnya agar memakai `openedx-unsupported/configuration`. Script juga patch dependency sandbox Koa ke:

- `numpy==1.19.5`
- `scipy==1.5.4`

## Cara Pakai di SSH

Login ke VM:

```bash
ssh azureuser@<public-ip-vm>
```

Clone repo ini:

```bash
git clone <url-repo-ini> enialrahs
cd enialrahs
```

Jalankan installer:

```bash
chmod +x utils/install/install-openedx-koa-ssh.sh
./utils/install/install-openedx-koa-ssh.sh \
  --lms-host edxicei-lms-tm.trafficmanager.net \
  --cms-host edxicei-cms-tm.trafficmanager.net
```

Jika memakai domain sendiri, ganti host:

```bash
./utils/install/install-openedx-koa-ssh.sh \
  --lms-host belajar.example.com \
  --cms-host studio.example.com
```

## Cek Progress

```bash
tail -f ~/openedx-koa-install/install.out
```

Jika install berhenti, cek juga clone Ansible:

```bash
cd /var/tmp/configuration
git status
git branch --show-current
```

Branch yang benar harus:

```text
open-release/koa.master
```

## Catatan Operasional

Jalankan script dari user SSH biasa yang punya akses `sudo`, bukan dari root langsung. Beberapa langkah di `native.sh` memakai file di home user seperti `config.yml` dan `my-passwords.yml`, jadi lebih aman membiarkan script mengatur `sudo` hanya saat dibutuhkan.

Koa adalah release lama dan repo `openedx-unsupported/configuration` bersifat archived/read-only. Jalur ini cocok untuk instalasi legacy, tetapi jika ada error runtime, sumber kebenaran berikutnya adalah log di `~/openedx-koa-install/install.out` dan state Ansible di `/var/tmp/configuration`.
