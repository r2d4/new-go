ORG := matt-rickard.com
PROJECT := new-go

BUILD_DIR ?= out
REPOSITORY ?= $(ORG)/$(PROJECT)
BUILD_PACKAGE = $(REPOSITORY)/cmd

GOOS ?= $(shell go env GOOS)
GOARCH ?= amd64
SUPPORTED_PLATFORMS := linux-$(ARCH) darwin-$(GOARCH) windows-$(GOARCH).exe

GIT_COMMIT := $(shell git rev-parse HEAD)
GIT_TREE_STATE := $(if $(shell git status --porcelain),dirty,clean)

VERSION_PACKAGE = $(REPOSITORY)/pkg/version
MAJOR_VERSION = 0
MINOR_VERSION = 0
BUILD_VERSION = 1
VERSION ?= $(MAJOR_VERSION).$(MINOR_VERSION).$(BUILD_VERSION)

DATE := $(shell date +'%Y-%m-%dT%H:%M:%SZ')

GO_GCFLAGS := "all=-trimpath=${PWD}"
GO_ASMFLAGS := "all=-trimpath=${PWD}"
GO_CGO_ENABLED = 0
GO_BUILD_TAGS := ""

GO_LDFLAGS :="
GO_LDFLAGS += -extldflags \"${LDFLAGS}\"
GO_LDFLAGS += -X $(VERSION_PACKAGE).project=$(PROJECT)
GO_LDFLAGS += -X $(VERSION_PACKAGE).version=$(VERSION)
GO_LDFLAGS += -X $(VERSION_PACKAGE).buildDate=$(DATE)
GO_LDFLAGS += -X $(VERSION_PACKAGE).gitCommit=$(GIT_COMMIT)
GO_LDFLAGS += -X $(VERSION_PACKAGE).gitTreeState=$(GIT_TREE_STATE)
GO_LDFLAGS +="

GO_FILES := $(shell find . -type f -name '*.go' -not -path "./vendor/*")

$(BUILD_DIR)/$(PROJECT): $(BUILD_DIR)/$(PROJECT)-$(GOOS)-$(GOARCH)
	cp $(BUILD_DIR)/$(PROJECT)-$(GOOS)-$(GOARCH) $@

$(BUILD_DIR)/$(PROJECT)-%-$(GOARCH): $(GO_FILES) $(BUILD_DIR)
	GOOS=$* GOARCH=$(GOARCH) CGO_ENABLED=$(GO_CGO_ENABLED) go build -ldflags $(GO_LDFLAGS) -gcflags $(GO_GCFLAGS) -asmflags $(GO_ASMFLAGS) -tags $(GO_BUILD_TAGS) -o $@ $(BUILD_PACKAGE)

%.sha256: %
	shasum -a 256 $< > $@

%.exe: %
	cp $< $@

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

.PRECIOUS: $(foreach platform, $(SUPPORTED_PLATFORMS), $(BUILD_DIR)/$(PROJECT)-$(platform))
.PHONY: cross
cross: $(foreach platform, $(SUPPORTED_PLATFORMS), $(BUILD_DIR)/$(PROJECT)-$(platform).sha256)

.PHONY: link
link:
	ln -s $(BUILD_DIR)/$(PROJECT) /usr/local/bin/$(PROJECT)

.PHONY: test
test:
	@ hack/test.sh

.PHONY: integration
integration: install $(BUILD_DIR)/$(PROJECT)
	go test -v -tags integration $(REPOSITORY)/integration -timeout 10m --remote=$(REMOTE_INTEGRATION)

.PHONY: coverage
coverage: $(BUILD_DIR)
	go test -coverprofile=$(BUILD_DIR)/coverage.txt -covermode=atomic ./...

.PHONY: clean
clean:
	rm -rf $(BUILD_DIR) $(DOCS_DIR)