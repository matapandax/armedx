# Install Open edX di Azure

Panduan ini memakai ARM template di folder `templates/stamp` dan script `Deploy-ARM.ps1`.

## 1. Siapkan parameter Azure

Salin `templates/stamp/parameters.azure.example.json` menjadi `templates/stamp/parameters.local.json` jika ingin menyimpan konfigurasi lokal sendiri.

Nilai penting yang perlu diganti:

- `clusterName`: awalan nama resource Azure. Gunakan huruf kecil dan angka saja, contoh `edxicei`.
- `location`: region Azure, contoh `southeastasia`, `eastus`, atau `westus2`.
- `virtualMachineSize`: ukuran VM. Default contoh memakai `Standard_D3_v2`.
- `diskSize`: ukuran OS disk dalam GB. Untuk Open edX, 80 GB lebih aman daripada 50 GB.
- `adminUsername`: user SSH VM.
- `adminPassword`: password untuk login SSH ke VM. Gunakan 6-72 karakter dan minimal 3 jenis karakter dari huruf besar, huruf kecil, angka, dan simbol. Contoh format: `AzureEdx2026!`.
- `installerGithubAccountName`, `installerGithubProjectName`, `installerGithubBranch`: repo yang berisi script `utils/install/install-openedx.sh`.
- `edxConfigurationGithubAccountName`, `edxConfigurationGithubProjectName`, `edxConfigurationGithubBranch`: repo konfigurasi Open edX.

Jika memakai domain sendiri, ubah juga `utils/install/config/config.yml`:

```yaml
EDXAPP_LMS_BASE: 'lms-domain-anda.com'
EDXAPP_CMS_BASE: 'studio-domain-anda.com'
```

## 2. Deploy dengan PowerShell

Login memakai service principal:

```powershell
.\Deploy-ARM.ps1 `
  -AzureSubscriptionName "<Azure Subscription Name>" `
  -ResourceGroupName "rg-enialrahs" `
  -Location "southeastasia" `
  -AadWebClientId "<App Registration Client ID>" `
  -AadWebClientAppKey "<Client Secret>" `
  -AadTenantId "<Tenant ID>" `
  -ParameterFile ".\templates\stamp\parameters.local.json" `
  -clusterName "edxicei" `
  -virtualMachineSize "Standard_D3_v2" `
  -diskSize 80 `
  -adminUsername "azureuser" `
  -adminPassword "<password kuat untuk VM>"
```

`-FullDeploymentArmTemplateFile` sekarang opsional. Jika tidak diisi, script otomatis memakai `templates/stamp/template.json`. `-ParameterFile` juga opsional; jika tidak diisi, script memakai `templates/stamp/parameters.json`.

## 3. Cek proses install

Setelah resource Azure selesai dibuat, proses install Open edX berjalan di VM dan bisa memakan waktu sekitar 2 jam.

```bash
ssh azureuser@<public-ip-vm>
sudo su
cd ~
tail -f install.out
```

URL default setelah selesai:

- LMS: `http://<clusterName>-lms-tm.trafficmanager.net`
- Studio/CMS: `http://<clusterName>-cms-tm.trafficmanager.net`

Jika memakai domain sendiri, arahkan DNS domain ke endpoint Traffic Manager di atas.
