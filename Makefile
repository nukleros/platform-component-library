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
# automation workflows
#
GROUP ?=
PROJECT ?=
project:
	@mkdir -p .source/$(GROUP)/$(PROJECT)/config/overlays .source/$(GROUP)/$(PROJECT)/static .source/$(GROUP)/$(PROJECT)/vendor $(GROUP)/$(PROJECT)
	@touch .source/$(GROUP)/$(PROJECT)/config/vendor.yaml .source/$(GROUP)/$(PROJECT)/config/values.yaml

download:
	@GROUP=$(GROUP) PROJECT=$(PROJECT) .scripts/download.sh

overlay:
	@for OVERLAY in `ls .source/$(GROUP)/$(PROJECT)/config/overlays`; do \
		yot -I 2 -i .source/$(GROUP)/$(PROJECT)/config/overlays/$$OVERLAY -o . -f .source/$(GROUP)/$(PROJECT)/config/values.yaml --remove-comments -s > $(GROUP)/$(PROJECT)/$$OVERLAY;\
	done
