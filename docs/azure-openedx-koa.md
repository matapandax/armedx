# Install Open edX Koa Native di Azure

Panduan ini memakai ARM template Koa native:

- `templates/stamp/template-openedx-koa.json`
- `templates/stamp/parameters.openedx-koa.example.json`

Template ini tidak lagi menyimpan logic `native.sh` panjang di dalam ARM. Saat VM selesai dibuat, Custom Script Extension hanya melakukan hal kecil ini:

1. Install `git`.
2. Clone repo deploy ini dari `https://github.com/matapandax/enialrahs.git`.
3. Jalankan `utils/install/install-openedx-koa-ssh.sh` dari repo hasil clone.

Script lokal itulah yang mengambil `openedx-unsupported/configuration` release ref/tag `open-release/koa.3`, menjalankan `util/install/native.sh`, lalu patch dependency lama Koa untuk Python 3.8:

- `numpy==1.19.5`
- `scipy==1.5.4`

Ref Koa yang dipakai adalah tag remote yang benar:

```text
openedx-unsupported/configuration -> refs/tags/open-release/koa.3
```

## 1. Siapkan parameter

Salin contoh parameter agar perubahan lokal tidak tercampur dengan template:

```powershell
Copy-Item .\templates\stamp\parameters.openedx-koa.example.json .\templates\stamp\parameters.openedx-koa.local.json
```

Nilai penting yang perlu diganti:

- `clusterName`: awalan nama resource Azure, gunakan huruf kecil dan angka saja.
- `location`: region Azure, contoh `southeastasia`.
- `virtualMachineSize`: gunakan minimal `Standard_D3_v2`.
- `diskSize`: disarankan minimal 100 GB.
- `adminUsername`: user SSH VM.
- `adminPassword`: password SSH yang kuat, 6-72 karakter dan minimal 3 jenis karakter dari huruf besar, huruf kecil, angka, dan simbol. Contoh format: `AzureEdx2026!`.
- `installerGithubAccountName`: biarkan `matapandax`.
- `installerGithubProjectName`: biarkan `enialrahs`.
- `installerGithubBranch`: biarkan `master`.
- `edxConfigurationGithubAccountName`: biarkan `openedx-unsupported`.
- `edxConfigurationGithubProjectName`: biarkan `configuration`.
- `edxConfigurationGithubBranch`: biarkan `open-release/koa.3` untuk Koa native.

## 2. Deploy

```powershell
.\Deploy-ARM.ps1 `
  -AzureSubscriptionName "<Azure Subscription Name>" `
  -ResourceGroupName "rg-edxicei-koa-native" `
  -Location "southeastasia" `
  -AadWebClientId "<App Registration Client ID>" `
  -AadWebClientAppKey "<Client Secret>" `
  -AadTenantId "<Tenant ID>" `
  -FullDeploymentArmTemplateFile ".\templates\stamp\template-openedx-koa.json" `
  -ParameterFile ".\templates\stamp\parameters.openedx-koa.local.json" `
  -clusterName "edxicei" `
  -virtualMachineSize "Standard_D3_v2" `
  -diskSize 100 `
  -adminUsername "azureuser" `
  -adminPassword "<password kuat untuk VM>" `
  -installerGithubAccountName "matapandax" `
  -installerGithubProjectName "enialrahs" `
  -installerGithubBranch "master" `
  -edxConfigurationGithubAccountName "openedx-unsupported" `
  -edxConfigurationGithubProjectName "configuration" `
  -edxConfigurationGithubBranch "open-release/koa.3"
```

## 3. Cek proses install

Setelah VM dibuat, login lewat SSH:

```bash
ssh azureuser@<public-ip-vm>
tail -f /home/azureuser/openedx-koa-install/install.out
```

URL default setelah selesai:

- LMS: `http://<clusterName>-lms-tm.trafficmanager.net`
- Studio/CMS: `http://<clusterName>-cms-tm.trafficmanager.net`

Koa adalah release lama. Jika install gagal, cek log terakhir di `/home/<adminUsername>/openedx-koa-install/install.out` dan state Ansible di `/var/tmp/configuration`.
