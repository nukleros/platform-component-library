OS ?= darwin
ARCH ?= amd64

#
# developer tools
#
VENDIR_VERSION ?= v0.30.0
vendir:
	@curl -L https://github.com/vmware-tanzu/carvel-vendir/releases/download/$(VENDIR_VERSION)/vendir-$(OS)-$(ARCH) -o /usr/local/bin/vendir && chmod +x /usr/local/bin/vendir

YOT_VERSION ?= v0.6.5
yot:
	@curl -L https://github.com/vmware-tanzu-labs/yaml-overlay-tool/releases/download/$(YOT_VERSION)/yot_$(YOT_VERSION)_Darwin_x86_64.tar.gz -o /usr/local/bin/yot.tar.gz && \
		tar zxvf /usr/local/bin/yot.tar.gz -C /usr/local/bin && \
		chmod +x /usr/local/bin/yot

#
# developer automation workflows
#
CATEGORY ?=
PROJECT ?=
project:
	@mkdir -p .source/$(CATEGORY)/$(PROJECT)/config/overlays .source/$(CATEGORY)/$(PROJECT)/static .source/$(CATEGORY)/$(PROJECT)/vendor $(CATEGORY)/$(PROJECT)
	@touch .source/$(CATEGORY)/$(PROJECT)/config/vendor.yaml .source/$(CATEGORY)/$(PROJECT)/config/values.yaml

download:
	@CATEGORY=$(CATEGORY) PROJECT=$(PROJECT) .scripts/download.sh

overlay:
	@CATEGORY=$(CATEGORY) PROJECT=$(PROJECT) .scripts/overlay.sh
