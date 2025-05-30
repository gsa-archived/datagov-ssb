#!/bin/bash
set -ex
APP_NAME=app-solr
CSB_VERSION="v2.5.6"
DATAGOV_BROKERPAK_SOLR_VERSION="v2.3.0"

# Install zip for AWS Lambda restarts of solr
# Install pip to install slack_sdk for Slack notifications
sudo apt-get -y install zip

# Set up an app dir and bin dir
mkdir -p $APP_NAME/bin

# Generate a .profile to be run at startup for mapping VCAP_SERVICES to needed
# environment variables
cat > $APP_NAME/.profile << 'EOF'
# Locate additional binaries needed by the deployed brokerpaks
export PATH="$PATH:${PWD}/bin"
EOF
chmod +x $APP_NAME/.profile

# Add the cloud-service-broker binary
(cd $APP_NAME && curl -f -L -o cloud-service-broker https://github.com/cloudfoundry-incubator/cloud-service-broker/releases/download/${CSB_VERSION}/cloud-service-broker.linux) && \
    chmod +x $APP_NAME/cloud-service-broker

# Add the brokerpak(s)
(cd $APP_NAME && curl -f -LO https://github.com/GSA-TTS/datagov-brokerpak-solr/releases/download/${DATAGOV_BROKERPAK_SOLR_VERSION}/datagov-brokerpak-solr-${DATAGOV_BROKERPAK_SOLR_VERSION}.brokerpak)


# Create a manifest for pushing by hand, if necessary
cat > manifest-solrcloud.yml << MANIFEST
---
# Make a copy of vars-solr-template.yml for each deployment target, editing the
# values to match your expectations. Then push with
#   cf push ssb-solrcloud -f manifest-solrcloud.yml --vars-file vars-solr-ENV_NAME
applications:
- name: ssb-solrcloud
  path: app-solr
  buildpacks:
  - binary_buildpack
  command: source .profile && ./cloud-service-broker serve
  instances: 1
  memory: 256M
  disk_quota: 2G
  routes:
  - route: ssb-solrcloud-((ORG))-((SPACE)).app.cloud.gov
  env:
    SECURITY_USER_NAME: ((SECURITY_USER_NAME))
    SECURITY_USER_PASSWORD: ((SECURITY_USER_PASSWORD))
    AWS_ACCESS_KEY_ID: ((AWS_ACCESS_KEY_ID))
    AWS_SECRET_ACCESS_KEY: ((AWS_SECRET_ACCESS_KEY))
    AWS_DEFAULT_REGION: ((AWS_DEFAULT_REGION))
    DB_TLS: "skip-verify"
    GSB_COMPATIBILITY_ENABLE_CATALOG_SCHEMAS: true
    GSB_COMPATIBILITY_ENABLE_CF_SHARING: true
    GSB_DEBUG: true
    AWS_ZONE: ((AWS_ZONE))
MANIFEST
cat > vars-solr-template.yml << VARS
AWS_ACCESS_KEY_ID: your-key-id
AWS_SECRET_ACCESS_KEY: your-key-secret
AWS_DEFAULT_REGION: us-west-2
AWS_ZONE: your-ssb-zone
SECURITY_USER_NAME: your-broker-username
SECURITY_USER_PASSWORD: your-broker-password
ORG: gsa-datagov
SPACE: your-space
VARS
