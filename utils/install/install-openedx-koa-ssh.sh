#!/usr/bin/env bash
set -euo pipefail

OPENEDX_RELEASE="${OPENEDX_RELEASE:-open-release/koa.3}"
CONFIG_REPO="${CONFIG_REPO:-https://github.com/openedx-unsupported/configuration}"
CONFIG_RAW_BASE="${CONFIG_RAW_BASE:-https://raw.githubusercontent.com/openedx-unsupported/configuration/${OPENEDX_RELEASE}}"
INSTALL_DIR="${INSTALL_DIR:-${HOME}/openedx-koa-install}"
PLATFORM_NAME="${PLATFORM_NAME:-ICEI}"
SUPPORT_EMAIL="${SUPPORT_EMAIL:-support@example.com}"
LMS_HOST="${LMS_HOST:-}"
CMS_HOST="${CMS_HOST:-}"

usage() {
    cat <<'EOF'
Install Open edX Koa native from an SSH session.

Required:
  --lms-host <host>    LMS hostname, for example lms.example.com
  --cms-host <host>    Studio/CMS hostname, for example studio.example.com

Optional env vars:
  OPENEDX_RELEASE      Default: open-release/koa.3
  CONFIG_REPO          Default: https://github.com/openedx-unsupported/configuration
  INSTALL_DIR          Default: ~/openedx-koa-install
  PLATFORM_NAME        Default: ICEI
  SUPPORT_EMAIL        Default: support@example.com

Example:
  ./utils/install/install-openedx-koa-ssh.sh \
    --lms-host edxicei-lms-tm.trafficmanager.net \
    --cms-host edxicei-cms-tm.trafficmanager.net
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

if [[ -z "${LMS_HOST}" || -z "${CMS_HOST}" ]]; then
    echo "Missing --lms-host or --cms-host." >&2
    usage
    exit 2
fi

if [[ "$(lsb_release -rs)" != "20.04" ]]; then
    echo "This Koa native script is prepared for Ubuntu 20.04." >&2
    exit 1
fi

mkdir -p "${INSTALL_DIR}"
cd "${INSTALL_DIR}"

export OPENEDX_RELEASE
export CONFIGURATION_VERSION="${CONFIGURATION_VERSION:-${OPENEDX_RELEASE}}"
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LC_CTYPE=en_US.UTF-8

sudo apt-get update -y
sudo apt-get install -y locales wget curl git ca-certificates python3 python3-pip python3-dev python3.8-dev build-essential software-properties-common
sudo locale-gen en_US.UTF-8
sudo update-locale LANG=en_US.UTF-8

cat > config.yml <<EOF
EDXAPP_PLATFORM_NAME: ${PLATFORM_NAME}
EDXAPP_LMS_BASE: ${LMS_HOST}
EDXAPP_CMS_BASE: ${CMS_HOST}
EDXAPP_SITE_NAME: ${LMS_HOST}
EDXAPP_LMS_SITE_NAME: ${LMS_HOST}
EDXAPP_CMS_SITE_NAME: ${CMS_HOST}
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
perl -0pi -e 's/python3\.5-dev/python3.8-dev/g; s/python3\.5/python3/g' ansible-bootstrap.sh
sudo -E bash ansible-bootstrap.sh
wget -O - "${CONFIG_RAW_BASE}/util/install/generate-passwords.sh" | bash
wget -O native.sh "${CONFIG_RAW_BASE}/util/install/native.sh"

perl -0pi -e "s#git clone https://github.com/edx/configuration#git clone ${CONFIG_REPO}#g" native.sh
perl -0pi -e 's#git checkout \$CONFIGURATION_VERSION\ngit pull#git checkout \$CONFIGURATION_VERSION\ngit pull\nsudo sed -i -e "s/^numpy==.*/numpy==1.19.5/" -e "s/^scipy==.*/scipy==1.5.4/" requirements/edx-sandbox/py35.txt#' native.sh

bash native.sh 2>&1 | tee install.out
