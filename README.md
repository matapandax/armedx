# Open edX Quince Native on Azure

Repository ini berisi template dan script untuk deploy **Open edX Quince native** di Azure dengan:

- Azure Load Balancer
- LMS dan Studio/CMS terpisah
- hostname MFE
- installer SSH native berbasis `matapandax/configuration`

Branch deployment yang dipakai VM:

```text
quince-native-azure
```

Repo publik untuk clone di VM:

```text
https://github.com/matapandax/armedx.git
```

## File Utama

ARM template:

```text
templates/stamp/template-openedx-quince-native.json
```

Contoh parameter:

```text
templates/stamp/parameters.openedx-quince-native.example.json
```

Installer native via SSH:

```text
utils/install/install-openedx-quince-native-ssh.sh
```

Dokumentasi arsitektur:

```text
docs/architecture-openedx-quince-native-azure-lb-mfe.md
```

## Arsitektur Singkat

Default hostname dari template:

```text
LMS:
http://edxquince-lms-tm.trafficmanager.net

Studio/CMS:
http://edxquince-cms-tm.trafficmanager.net

MFE:
http://edxquince-mfe-tm.trafficmanager.net
```

Port publik yang dibuka:

```text
22   SSH, batasi ke IP admin
80   HTTP
443  HTTPS
```

MFE tidak memakai Load Balancer rule terpisah. Host MFE diarahkan ke Public IP LMS dan dibedakan oleh host header/reverse proxy supaya tidak bentrok dengan aturan Azure Load Balancer untuk backend port `80/443`.

## Deploy ARM dari PowerShell

Salin parameter contoh:

```powershell
Copy-Item .\templates\stamp\parameters.openedx-quince-native.example.json .\templates\stamp\parameters.openedx-quince-native.local.json
```

Edit file lokal:

```text
templates/stamp/parameters.openedx-quince-native.local.json
```

Minimal nilai penting:

```text
clusterName: edxquince
virtualMachineSize: Standard_D4s_v5
diskSize: 128
adminUsername: edxicei atau azureuser
installerGithubProjectName: armedx
installerGithubBranch: quince-native-azure
edxConfigurationGithubAccountName: matapandax
edxConfigurationGithubBranch: install-openedx-quince-native
openEdxRelease: open-release/quince.master
```

Jalankan deploy:

```powershell
.\Deploy-ARM.ps1 `
  -AzureSubscriptionName "<Azure Subscription Name>" `
  -ResourceGroupName "DEV-BLOCKCERT" `
  -Location "southeastasia" `
  -AadWebClientId "<App Registration Client ID>" `
  -AadWebClientAppKey "<Client Secret>" `
  -AadTenantId "<Tenant ID>" `
  -FullDeploymentArmTemplateFile ".\templates\stamp\template-openedx-quince-native.json" `
  -ParameterFile ".\templates\stamp\parameters.openedx-quince-native.local.json" `
  -clusterName "edxquince" `
  -virtualMachineSize "Standard_D4s_v5" `
  -diskSize 128 `
  -adminUsername "edxicei" `
  -adminPassword "<password kuat untuk VM>"
```

## Install Manual via SSH

Jika Azure CustomScript gagal, lanjutkan langsung dari SSH VM:

```bash
ssh edxicei@<public-ip-vm>
```

Clone branch deployment:

```bash
cd ~
git clone --branch quince-native-azure https://github.com/matapandax/armedx.git armedx
cd ~/armedx
```

Jika folder sudah ada:

```bash
cd ~/armedx
git fetch origin
git checkout quince-native-azure
git pull --ff-only
```

Jalankan installer:

```bash
chmod +x utils/install/install-openedx-quince-native-ssh.sh

OPENEDX_RELEASE=open-release/quince.master \
CONFIGURATION_VERSION=install-openedx-quince-native \
CONFIG_REPO=https://github.com/matapandax/configuration \
./utils/install/install-openedx-quince-native-ssh.sh \
  --lms-host edxquince-lms-tm.trafficmanager.net \
  --cms-host edxquince-cms-tm.trafficmanager.net \
  --mfe-host edxquince-mfe-tm.trafficmanager.net
```

Pantau log:

```bash
tail -f ~/openedx-quince-native-install/install.out
```

Jika ada sisa percobaan gagal:

```bash
sudo rm -rf /tmp/configuration
```

Lalu jalankan ulang installer.

## Verifikasi

Cek branch configuration:

```bash
cd /var/tmp/configuration
git status
git branch --show-current
```

Branch yang diharapkan:

```text
install-openedx-quince-native
```

Cek service:

```bash
sudo /edx/bin/supervisorctl status
sudo systemctl status nginx
```

Cek akses dari VM:

```bash
curl -I -H "Host: edxquince-lms-tm.trafficmanager.net" http://localhost
curl -I -H "Host: edxquince-cms-tm.trafficmanager.net" http://localhost
curl -I -H "Host: edxquince-mfe-tm.trafficmanager.net" http://localhost
```

## Catatan

Quince adalah release lama. Jalur ini dipakai karena kebutuhan native/compatibility, bukan karena ini jalur modern Open edX. Untuk production multi-VM, pisahkan dulu MySQL, MongoDB, Redis, search, dan file storage dari VM aplikasi sebelum menambahkan backend VM ke Load Balancer.
