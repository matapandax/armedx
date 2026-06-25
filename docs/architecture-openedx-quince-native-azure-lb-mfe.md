# Arsitektur Azure Open edX Quince Native dengan Load Balancer dan MFE

Dokumen ini mendesain jalur **Open edX Quince native** di Azure dengan **Azure Load Balancer**, DNS `edxquince`, host **LMS** dan **Studio/CMS** terpisah, serta konfigurasi MFE.

Quince sudah termasuk release lama/unsupported pada dokumentasi Open edX 2026. Jalur native ini dipakai jika tujuan utamanya adalah kompatibilitas dengan branch Quince native yang sudah ada, bukan mengikuti jalur instalasi modern.

## Ringkasan Keputusan

- Metode install: native Ansible dari repo `configuration`.
- Default repo konfigurasi: `https://github.com/matapandax/configuration`.
- Default branch/ref: `install-openedx-quince-native`.
- Open edX release: `open-release/quince.master`.
- OS VM: Ubuntu 20.04 LTS.
- Entry point publik: Azure Standard Load Balancer.
- DNS:
  - LMS: `lms.edxquince.<domain>`
  - Studio/CMS: `studio.edxquince.<domain>`
  - MFE: `apps.lms.edxquince.<domain>`
- MFE native Quince:
  - Node: `16.13.2`
  - repo org/path: `openedx`
  - MFE host: `apps.lms.edxquince.<domain>`

## Arsitektur

```text
Internet
  |
  | DNS:
  |   lms.edxquince.<domain>      -> Public IP Azure Load Balancer
  |   studio.edxquince.<domain>   -> Public IP Azure Load Balancer
  |   apps.lms.edxquince.<domain> -> Public IP LMS Load Balancer
  |
Azure Standard Load Balancer
  | frontend rules:
  |   80  -> VM backend 80
  |   443 -> VM backend 443
  | health probe:
  |   80
  |
Backend Pool
  |
  +-- VM openedx-quince-native-01
      - Ubuntu 20.04 LTS
      - Native Open edX under /edx
      - Ansible/configuration clone under /var/tmp/configuration
      - LMS/CMS services managed by native stack
      - MFE built/deployed by native MFE roles
```

## Resource Azure

Minimal staging:

- Resource Group: `rg-edxquince-native-staging`
- VNet: `vnet-edxquince`
- Subnet: `subnet-openedx`
- Public IP: Standard SKU, static
- Load Balancer: Standard SKU
- VM: Ubuntu 20.04 LTS
- NSG: buka hanya port yang diperlukan

Template ARM:

```text
templates/stamp/template-openedx-quince-native.json
templates/stamp/parameters.openedx-quince-native.example.json
```

Spesifikasi VM staging:

- `Standard_D4s_v5`
- 4 vCPU
- 16 GB RAM
- OS disk 128 GB Premium SSD
- Swap 4-8 GB

Spesifikasi production awal single-node:

- `Standard_D8s_v5`
- 8 vCPU
- 32 GB RAM
- OS disk 256 GB Premium SSD
- Backup/snapshot terjadwal

## Port yang Dibuka

NSG inbound:

| Priority | Port | Source | Tujuan |
|---:|---:|---|---|
| 100 | 22 | IP admin saja | SSH |
| 200 | 80 | Internet | LMS/CMS/MFE HTTP |
| 210 | 443 | Internet | LMS/CMS/MFE HTTPS |

Load Balancer rules:

| Frontend | Backend | Untuk |
|---:|---:|---|
| 80 | 80 | LMS/MFE lewat HTTP host routing |
| 443 | 443 | LMS/MFE lewat HTTPS host routing |

Azure Load Balancer tidak boleh punya dua rule berbeda yang memakai backend pool, protocol, dan backend port yang sama. Karena itu MFE tidak dibuatkan rule Load Balancer sendiri. Host MFE diarahkan ke Public IP LMS dan dibedakan oleh `Host` header/reverse proxy.

Jangan buka port internal ini ke publik:

- `8000`, `8001`: app internal LMS/CMS jika muncul saat debug.
- `18010`, `48010`: pola Studio lama; jangan dibuka jika sudah memakai reverse proxy/host routing.
- `1995`, `1996`, `2000+`: port dev MFE, hanya untuk build/debug lokal.
- `3306`, `27017`, `6379`, `9200/7700`: database/cache/search internal.

Catatan: MFE **tidak perlu port publik terpisah**. Untuk akses browser, MFE harus berada di host seperti `apps.lms.edxquince.<domain>` dan dilayani melalui `80/443`.

## DNS

Buat record ke Public IP Load Balancer:

```text
lms.edxquince.<domain>       A  <public-ip-lms-lb>
studio.edxquince.<domain>    A  <public-ip-cms-lb>
apps.lms.edxquince.<domain>  A  <public-ip-lms-lb>
```

Jika memakai Azure DNS label public IP, bisa pakai CNAME ke:

```text
edxquince.southeastasia.cloudapp.azure.com
```

## Install Native via SSH

Script:

```text
utils/install/install-openedx-quince-native-ssh.sh
```

Jika ingin deploy VM + Load Balancer + Traffic Manager langsung dari Azure ARM, salin parameter contoh:

```powershell
Copy-Item .\templates\stamp\parameters.openedx-quince-native.example.json .\templates\stamp\parameters.openedx-quince-native.local.json
```

Lalu deploy:

```powershell
.\Deploy-ARM.ps1 `
  -AzureSubscriptionName "<Azure Subscription Name>" `
  -ResourceGroupName "rg-edxquince-native-staging" `
  -Location "southeastasia" `
  -AadWebClientId "<App Registration Client ID>" `
  -AadWebClientAppKey "<Client Secret>" `
  -AadTenantId "<Tenant ID>" `
  -FullDeploymentArmTemplateFile ".\templates\stamp\template-openedx-quince-native.json" `
  -ParameterFile ".\templates\stamp\parameters.openedx-quince-native.local.json" `
  -clusterName "edxquince" `
  -virtualMachineSize "Standard_D4s_v5" `
  -diskSize 128 `
  -adminUsername "azureuser" `
  -adminPassword "<password kuat untuk VM>"
```

Default host dari template:

```text
LMS:    http://edxquince-lms-tm.trafficmanager.net
Studio: http://edxquince-cms-tm.trafficmanager.net
MFE:    http://edxquince-mfe-tm.trafficmanager.net
```

Catatan: `edxquince-mfe-tm.trafficmanager.net` diarahkan ke Public IP LMS, bukan Public IP terpisah. Ini sengaja untuk menghindari konflik rule Azure Load Balancer pada backend port `80/443`.

Jalankan dari user SSH biasa yang punya akses `sudo`, bukan root:

```bash
git clone --branch quince-native-azure https://github.com/matapandax/armedx.git armedx
cd armedx
chmod +x utils/install/install-openedx-quince-native-ssh.sh

./utils/install/install-openedx-quince-native-ssh.sh \
  --lms-host lms.edxquince.example.edu \
  --cms-host studio.edxquince.example.edu \
  --mfe-host apps.lms.edxquince.example.edu
```

Log utama:

```bash
tail -f ~/openedx-quince-native-install/install.out
```

State Ansible:

```bash
cd /var/tmp/configuration
git status
git branch --show-current
```

Branch/ref yang diharapkan:

```text
install-openedx-quince-native
```

## Konfigurasi Native yang Disiapkan Script

Script membuat `config.yml` dengan nilai utama:

```yaml
EDXAPP_LMS_BASE: lms.edxquince.<domain>
EDXAPP_CMS_BASE: studio.edxquince.<domain>
MFE_HOST: apps.lms.edxquince.<domain>
MFE_DEPLOY_NODE_VERSION: "16.13.2"
MFE_DEPLOY_GIT_PATH: "openedx"
EDXAPP_LEARNING_MICROFRONTEND_URL: "http://apps.lms.edxquince.<domain>/learning"
EDXAPP_ACCOUNT_MICROFRONTEND_URL: "http://apps.lms.edxquince.<domain>/account"
EDXAPP_PROFILE_MICROFRONTEND_URL: "http://apps.lms.edxquince.<domain>/profile"
EDXAPP_GRADEBOOK_MICROFRONTEND_URL: "http://apps.lms.edxquince.<domain>/gradebook"
```

Script juga memastikan paket Ubuntu 20.04 memakai `python3-dev` dan `python3.8-dev`, bukan `python3.5-dev`.

## Verifikasi Setelah Install

Di VM:

```bash
curl -I -H "Host: lms.edxquince.example.edu" http://localhost
curl -I -H "Host: studio.edxquince.example.edu" http://localhost
curl -I -H "Host: apps.lms.edxquince.example.edu" http://localhost
```

Cek service:

```bash
sudo /edx/bin/supervisorctl status
sudo systemctl status nginx
```

Dari komputer luar:

```bash
curl -I http://lms.edxquince.example.edu
curl -I http://studio.edxquince.example.edu
curl -I http://apps.lms.edxquince.example.edu
```

## Catatan Skalabilitas

Load Balancer dengan 1 VM aman untuk staging. Untuk multi-VM production native, pisahkan stateful service dulu:

- MySQL
- MongoDB
- Redis
- Search
- file/media storage

Jika tidak dipisah, setiap VM akan punya data lokal sendiri dan Load Balancer membuat perilaku LMS/CMS tidak konsisten.

## Referensi

- Open edX Quince release notes: https://docs.openedx.org/en/latest/community/release_notes/quince.html
- Named release branches/tags: https://docs.openedx.org/en/latest/community/release_notes/index.html
