#!/usr/bin/env bash
set -euo pipefail

CONFIG_REPO="${CONFIG_REPO:-https://github.com/matapandax/configuration}"
CONFIGURATION_VERSION="${CONFIGURATION_VERSION:-install-openedx-quince-native}"
CONFIG_RAW_BASE="${CONFIG_RAW_BASE:-https://raw.githubusercontent.com/matapandax/configuration/${CONFIGURATION_VERSION}}"
OPENEDX_RELEASE="${OPENEDX_RELEASE:-open-release/quince.master}"
INSTALL_DIR="${INSTALL_DIR:-${HOME}/openedx-quince-native-install}"
PLATFORM_NAME="${PLATFORM_NAME:-edxquince}"
SUPPORT_EMAIL="${SUPPORT_EMAIL:-support@example.com}"
MFE_DEPLOY_NODE_VERSION="${MFE_DEPLOY_NODE_VERSION:-16.13.2}"
MFE_DEPLOY_GIT_PATH="${MFE_DEPLOY_GIT_PATH:-openedx}"
LMS_HOST="${LMS_HOST:-}"
CMS_HOST="${CMS_HOST:-}"
MFE_HOST="${MFE_HOST:-}"

usage() {
    cat <<'EOF'
Install Open edX Quince native from an SSH session.

Required:
  --lms-host <host>    LMS hostname, for example lms.edxquince.example.edu
  --cms-host <host>    Studio/CMS hostname, for example studio.edxquince.example.edu
  --mfe-host <host>    MFE hostname, for example apps.lms.edxquince.example.edu

Optional env vars:
  CONFIG_REPO              Default: https://github.com/matapandax/configuration
  CONFIGURATION_VERSION    Default: install-openedx-quince-native
  OPENEDX_RELEASE          Default: open-release/quince.master
  INSTALL_DIR              Default: ~/openedx-quince-native-install
  PLATFORM_NAME            Default: edxquince
  SUPPORT_EMAIL            Default: support@example.com
  MFE_DEPLOY_NODE_VERSION  Default: 16.13.2
  MFE_DEPLOY_GIT_PATH      Default: openedx

Example:
  ./utils/install/install-openedx-quince-native-ssh.sh \
    --lms-host lms.edxquince.example.edu \
    --cms-host studio.edxquince.example.edu \
    --mfe-host apps.lms.edxquince.example.edu
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --lms-host)
            LMS_HOST="${2:-}"
            shift 2
            ;;
        --cms-host)
            CMS_HOST="${2:-}"
            shift 2
            ;;
        --mfe-host)
            MFE_HOST="${2:-}"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            usage
            exit 2
            ;;
    esac
done

if [[ -z "${LMS_HOST}" || -z "${CMS_HOST}" || -z "${MFE_HOST}" ]]; then
    echo "Missing --lms-host, --cms-host, or --mfe-host." >&2
    usage
    exit 2
fi

if [[ "${EUID}" -eq 0 ]]; then
    echo "Run as the SSH user with sudo access, not as root." >&2
    exit 1
fi

if command -v lsb_release >/dev/null 2>&1 && [[ "$(lsb_release -rs)" != "20.04" ]]; then
    echo "This native Quince script is prepared for Ubuntu 20.04." >&2
    exit 1
fi

mkdir -p "${INSTALL_DIR}"
cd "${INSTALL_DIR}"

exec > >(tee -a install.out) 2>&1

export OPENEDX_RELEASE
export CONFIGURATION_VERSION
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LC_CTYPE=en_US.UTF-8

echo "==> Open edX Quince native install"
echo "==> CONFIG_REPO=${CONFIG_REPO}"
echo "==> CONFIGURATION_VERSION=${CONFIGURATION_VERSION}"
echo "==> OPENEDX_RELEASE=${OPENEDX_RELEASE}"
echo "==> LMS_HOST=${LMS_HOST}"
echo "==> CMS_HOST=${CMS_HOST}"
echo "==> MFE_HOST=${MFE_HOST}"
echo "==> Log=${INSTALL_DIR}/install.out"

if command -v cloud-init >/dev/null 2>&1; then
    sudo cloud-init status --wait || true
fi

while sudo fuser /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock /var/cache/apt/archives/lock /var/lib/apt/lists/lock >/dev/null 2>&1; do
    echo "==> Waiting for apt lock..."
    sleep 10
done

sudo apt-get update -y
sudo apt-get install -y \
    acl \
    build-essential \
    ca-certificates \
    curl \
    git \
    locales \
    net-tools \
    python3 \
    python3-dev \
    python3-pip \
    python3.8-dev \
    software-properties-common \
    unzip \
    wget

sudo locale-gen en_US.UTF-8
sudo update-locale LANG=en_US.UTF-8

cat > config.yml <<EOF
EDXAPP_PLATFORM_NAME: ${PLATFORM_NAME}
EDXAPP_LMS_BASE: ${LMS_HOST}
EDXAPP_CMS_BASE: ${CMS_HOST}
EDXAPP_SITE_NAME: ${LMS_HOST}
EDXAPP_LMS_SITE_NAME: ${LMS_HOST}
EDXAPP_CMS_SITE_NAME: ${CMS_HOST}
COMMON_LMS_BASE_URL: "http://${LMS_HOST}"
EDXAPP_LMS_BASE_SCHEME: http
EDXAPP_CMS_BASE_SCHEME: http

MFE_DEPLOY_NODE_VERSION: "${MFE_DEPLOY_NODE_VERSION}"
MFE_DEPLOY_GIT_PATH: "${MFE_DEPLOY_GIT_PATH}"
MFE_HOST: ${MFE_HOST}
EDXAPP_MICROFRONTEND_URLS:
  learning: "http://${MFE_HOST}/learning"
  account: "http://${MFE_HOST}/account"
  profile: "http://${MFE_HOST}/profile"
  gradebook: "http://${MFE_HOST}/gradebook"

EDXAPP_PROFILE_MICROFRONTEND_URL: "http://${MFE_HOST}/profile"
EDXAPP_ACCOUNT_MICROFRONTEND_URL: "http://${MFE_HOST}/account"
EDXAPP_GRADEBOOK_MICROFRONTEND_URL: "http://${MFE_HOST}/gradebook"
EDXAPP_LEARNING_MICROFRONTEND_URL: "http://${MFE_HOST}/learning"

common_debian_pkgs:
  - apt-transport-https
  - ntp
  - acl
  - iotop
  - lynx
  - logrotate
  - rsyslog
  - git
  - unzip
  - net-tools
  - python3-pip
  - python3-dev
  - python3.8-dev

EDXAPP_TECH_SUPPORT_EMAIL: ${SUPPORT_EMAIL}
EDXAPP_CONTACT_EMAIL: ${SUPPORT_EMAIL}
EDXAPP_BUGS_EMAIL: ${SUPPORT_EMAIL}
EDXAPP_DEFAULT_FROM_EMAIL: ${SUPPORT_EMAIL}
EDXAPP_DEFAULT_FEEDBACK_EMAIL: ${SUPPORT_EMAIL}
EDXAPP_DEFAULT_SERVER_EMAIL: ${SUPPORT_EMAIL}
EDXAPP_BULK_EMAIL_DEFAULT_FROM_EMAIL: ${SUPPORT_EMAIL}
EDXAPP_UNIVERSITY_EMAIL: ${SUPPORT_EMAIL}
EDXAPP_PRESS_EMAIL: ${SUPPORT_EMAIL}
EDXAPP_PAYMENT_SUPPORT_EMAIL: ${SUPPORT_EMAIL}
EOF

wget -O ansible-bootstrap.sh "${CONFIG_RAW_BASE}/util/install/ansible-bootstrap.sh"
perl -0pi -e 's/PYTHON_VERSION="3\.5"/PYTHON_VERSION="3.8"/g; s/python3\.5-dev/python3.8-dev/g; s/python3\.5/python3.8/g' ansible-bootstrap.sh
perl -0pi -e "s#https://github.com/edx/configuration(?:\\.git)?#${CONFIG_REPO}#g; s#https://github.com/openedx/configuration(?:\\.git)?#${CONFIG_REPO}#g" ansible-bootstrap.sh
sudo -E bash ansible-bootstrap.sh

wget -O - "${CONFIG_RAW_BASE}/util/install/generate-passwords.sh" | bash
wget -O native.sh "${CONFIG_RAW_BASE}/util/install/native.sh"

perl -0pi -e "s#git clone https://github.com/edx/configuration#git clone ${CONFIG_REPO}#g" native.sh
perl -0pi -e "s#git clone https://github.com/openedx/configuration#git clone ${CONFIG_REPO}#g" native.sh

bash native.sh 2>&1 | tee -a install.out
