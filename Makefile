include versions.mk

VERSION        := $(shell git describe --always --dirty 2>/dev/null || echo "v$(BIVAC_VERSION)")
COMMIT_SHA1    := $(shell git rev-parse HEAD 2>/dev/null || echo "unknown")
BUILD_DATE     := $(shell date +%Y-%m-%d)
IMAGE_NAME     := ghcr.io/jusito/bivac
IMAGE_TAGS     := $(BIVAC_VERSION)
CPU_ARCH       ?= $(shell uname -m)

ifeq ($(CPU_ARCH),x86_64)
CPU_ARCH_SUPPORTED = true
GOARCH = amd64
GOARM =
else ifeq ($(CPU_ARCH),aarch64)
CPU_ARCH_SUPPORTED = true
GOARCH = arm64
GOARM =
else ifeq ($(CPU_ARCH),arm64)
CPU_ARCH_SUPPORTED = true
GOARCH = arm64
GOARM =
else ifeq ($(CPU_ARCH),armv7l)
CPU_ARCH_SUPPORTED = true
GOARCH = arm
GOARM = 7
else ifeq ($(CPU_ARCH),i386)
CPU_ARCH_SUPPORTED = true
GOARCH = 386
GOARM =
else ifeq ($(CPU_ARCH),i686)
CPU_ARCH_SUPPORTED = true
GOARCH = 386
GOARM =
else
CPU_ARCH_SUPPORTED = false
GOARCH =
GOARM =
endif

LDFLAGS := -s -w \
           -X main.version=$(VERSION) \
           -X main.buildDate=$(BUILD_DATE) \
           -X main.commitSha1=$(COMMIT_SHA1)

.PHONY: all check lint vet clean test integration-test .check-cpu-arch release print-version-env docker docker-images docker-push docker-release

all: check lint vet clean test

# Check for retracted packages
check:
	scripts/build/check_retracted.sh "Bivac" "current"

	scripts/build/build_rclone.sh "$(RCLONE_VERSION)" "$(BUILD_DATE)" ".local/rclone"
	cd .local/rclone
	scripts/build/check_retracted.sh "RClone" "$(RCLONE_VERSION)"
	cd ../..

	scripts/build/build_restic.sh "$(RESTIC_VERSION)" "$(BUILD_DATE)" ".local/restic"
	cd .local/restic
	scripts/build/check_retracted.sh "Restic" "$(RESTIC_VERSION)"

	echo "checked!"

lint:
	@command -v staticcheck >/dev/null 2>&1 || (echo "staticcheck not found. Run: go install honnef.co/go/tools/cmd/staticcheck@latest" && exit 1)
	staticcheck ./...

vet: main.go
	go vet ./...

test:
	go test -cover -v ./...

integration-test:
	test/integration/docker/run_tests.sh

.check-cpu-arch:
	@if [ "$(CPU_ARCH_SUPPORTED)" != "true" ]; then echo "unsupported CPU_ARCH: $(CPU_ARCH)" >&2; exit 2; fi

bivac: main.go $(wildcard */*/*/*.go)
	CGO_ENABLED=0 GOARCH=$(GOARCH) GOOS=$(GOOS) GOARM=$(GOARM) go build -ldflags="$(LDFLAGS)" -o bivac main.go

release: docker-release

print-version-env:
	@echo "BIVAC_VERSION=$(BIVAC_VERSION)"
	@echo "GO_VERSION=$(GO_VERSION)"
	@echo "RCLONE_VERSION=$(RCLONE_VERSION)"
	@echo "RESTIC_VERSION=$(RESTIC_VERSION)"
	@echo "GOARCH=$(GOARCH)"
	@echo "GOARM=$(GOARM)"

docker-images: clean
	bash scripts/build-docker.sh "$(IMAGE_NAME)" "$(BIVAC_VERSION)" "$(GO_VERSION)" "$(RCLONE_VERSION)" "$(RESTIC_VERSION)" amd64
	bash scripts/build-docker.sh "$(IMAGE_NAME)" "$(BIVAC_VERSION)" "$(GO_VERSION)" "$(RCLONE_VERSION)" "$(RESTIC_VERSION)" arm64
	bash scripts/build-docker.sh "$(IMAGE_NAME)" "$(BIVAC_VERSION)" "$(GO_VERSION)" "$(RCLONE_VERSION)" "$(RESTIC_VERSION)" arm 7

docker-push:
	bash scripts/push-docker.sh "$(IMAGE_NAME)" "$(GO_VERSION)" "$(RCLONE_VERSION)" "$(RESTIC_VERSION)" $(IMAGE_TAGS)

docker-release:
	bash scripts/build-release.sh "$(IMAGE_NAME)" "$(GO_VERSION)" "$(RCLONE_VERSION)" "$(RESTIC_VERSION)" "$(BIVAC_VERSION)"

docker: .check-cpu-arch clean
	bash scripts/build-docker.sh "$(IMAGE_NAME)" "$(BIVAC_VERSION)" "$(GO_VERSION)" "$(RCLONE_VERSION)" "$(RESTIC_VERSION)" "$(GOARCH)" "$(GOARM)"

clean:
	rm -f bivac coverage
	git clean -fXd -e \!vendor -e \!.local
