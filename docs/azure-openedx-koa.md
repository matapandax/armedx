# Install Open edX Koa Native di Azure

Panduan ini memakai ARM template Koa native:

- `templates/stamp/template-openedx-koa.json`
- `templates/stamp/parameters.openedx-koa.example.json`

Template ini memakai `openedx-unsupported/configuration` branch `open-release/koa.master` dan tetap menjalankan `util/install/native.sh`. Sebelum `native.sh` menjalankan Ansible, template menyisipkan dua patch:

- clone internal di `native.sh` diarahkan dari `edx/configuration` ke `openedx-unsupported/configuration`.
- dependency lama di `requirements/edx-sandbox/py35.txt` disesuaikan untuk Python 3.8:
- `numpy==1.19.5`
- `scipy==1.5.4`

Patch dependency ini menggantikan pekerjaan manual yang biasanya muncul saat dependency lama Koa tidak cocok dengan Python 3.8 di Ubuntu 20.04. Akun GitHub `edx-requirements-bot` tidak dapat dipanggil langsung dari deployment ini, dan akun tersebut tidak menyediakan repo publik untuk dijadikan sumber konfigurasi.

Branch Koa yang dipakai adalah branch remote yang benar:

```text
openedx-unsupported/configuration -> refs/heads/open-release/koa.master
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
- `adminPassword`: password SSH yang kuat.
- `edxConfigurationGithubAccountName`: biarkan `openedx-unsupported`.
- `edxConfigurationGithubProjectName`: biarkan `configuration`.
- `edxConfigurationGithubBranch`: biarkan `open-release/koa.master` untuk Koa native.

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
  -installerGithubAccountName "openedx-unsupported" `
  -installerGithubProjectName "configuration" `
  -installerGithubBranch "open-release/koa.master" `
  -edxConfigurationGithubAccountName "openedx-unsupported" `
  -edxConfigurationGithubProjectName "configuration" `
  -edxConfigurationGithubBranch "open-release/koa.master"
```

## 3. Cek proses install

Setelah VM dibuat, login lewat SSH:

```bash
ssh azureuser@<public-ip-vm>
sudo su
tail -f /home/azureuser/openedx-install/install.out
```

URL default setelah selesai:

- LMS: `http://<clusterName>-lms-tm.trafficmanager.net`
- Studio/CMS: `http://<clusterName>-cms-tm.trafficmanager.net`

Koa adalah release lama. Jika install gagal, cek log terakhir di `/home/<adminUsername>/openedx-install/install.out` dan log Ansible di folder `/home/<adminUsername>/openedx-install/logs/`.
