# Copyright 2017 The Openstack-Helm Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

BUILD_DIR       := $(shell mktemp -d)
HELM            := $(BUILD_DIR)/helm

all: charts


.PHONY: charts
charts: clean helm-install helm-toolkit
	$(HELM) dependency update divingbell
	$(HELM) package divingbell


# Perform Linting
.PHONY: lint
lint: helm_lint build_docs

# Dry run templating of chart
.PHONY: dry-run
dry-run: clean helm-toolkit
	$(HELM) template divingbell

.PHONY: clean
clean:
	rm -rf build
	rm -rf docs/build
	rm -rf deps
	@echo "Removed .b64, _partials.tpl, and _globals.tpl files"
	rm -rf helm-toolkit/secrets/*.b64
	rm -rf */templates/_partials.tpl
	rm -rf */templates/_globals.tpl
	rm -f *.tgz
	rm -f */charts/*.tgz

.PHONY: helm_lint
helm_lint: clean helm-toolkit
	$(HELM) dependency update divingbell
	$(HELM) lint divingbell

.PHONY: docs
docs: clean build_docs

.PHONY: build_docs
build_docs:
	tox -e docs

# Initialize local helm config
.PHONY: helm-toolkit
helm-toolkit: helm-install
	tools/helm_tk.sh $(HELM)

# Install helm binary
.PHONY: helm-install
helm-install:
	tools/helm_install.sh $(HELM)
