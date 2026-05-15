include versions.mk

VERSION        := $(shell git describe --always --dirty 2>/dev/null || echo "v$(BIVAC_VERSION)")
COMMIT_SHA1    := $(shell git rev-parse HEAD 2>/dev/null || echo "unknown")
BUILD_DATE     := $(shell date +%Y-%m-%d)
IMAGE_NAME     := ghcr.io/jusito/bivac
IMAGE_TAGS     := $(BIVAC_VERSION)

LDFLAGS := -s -w \
           -X main.version=$(VERSION) \
           -X main.buildDate=$(BUILD_DATE) \
           -X main.commitSha1=$(COMMIT_SHA1)

.PHONY: all check lint vet clean test release print-version-env docker-images docker-push docker-release

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

bivac: main.go $(wildcard */*/*/*.go)
	CGO_ENABLED=0 GOARCH=$(GOARCH) GOOS=$(GOOS) GOARM=$(GOARM) go build -ldflags="$(LDFLAGS)" -o bivac main.go

release: docker-release

print-version-env:
	@echo "BIVAC_VERSION=$(BIVAC_VERSION)"
	@echo "GO_VERSION=$(GO_VERSION)"
	@echo "RCLONE_VERSION=$(RCLONE_VERSION)"
	@echo "RESTIC_VERSION=$(RESTIC_VERSION)"

.PHONY: docker-amd64 docker-arm docker-arm64 docker-386

docker-images: clean
	bash scripts/build-docker.sh "$(IMAGE_NAME)" "$(BIVAC_VERSION)" "$(GO_VERSION)" "$(RCLONE_VERSION)" "$(RESTIC_VERSION)" amd64
	bash scripts/build-docker.sh "$(IMAGE_NAME)" "$(BIVAC_VERSION)" "$(GO_VERSION)" "$(RCLONE_VERSION)" "$(RESTIC_VERSION)" arm64
	bash scripts/build-docker.sh "$(IMAGE_NAME)" "$(BIVAC_VERSION)" "$(GO_VERSION)" "$(RCLONE_VERSION)" "$(RESTIC_VERSION)" arm 7

docker-push:
	bash scripts/push-docker.sh "$(IMAGE_NAME)" "$(GO_VERSION)" "$(RCLONE_VERSION)" "$(RESTIC_VERSION)" $(IMAGE_TAGS)

docker-release:
	bash scripts/build-release.sh "$(IMAGE_NAME)" "$(GO_VERSION)" "$(RCLONE_VERSION)" "$(RESTIC_VERSION)" "$(BIVAC_VERSION)"

docker-amd64: clean
	bash scripts/build-docker.sh "$(IMAGE_NAME)" "$(BIVAC_VERSION)" "$(GO_VERSION)" "$(RCLONE_VERSION)" "$(RESTIC_VERSION)" amd64

docker-arm: clean
	bash scripts/build-docker.sh "$(IMAGE_NAME)" "$(BIVAC_VERSION)" "$(GO_VERSION)" "$(RCLONE_VERSION)" "$(RESTIC_VERSION)" arm 7

docker-arm64: clean
	bash scripts/build-docker.sh "$(IMAGE_NAME)" "$(BIVAC_VERSION)" "$(GO_VERSION)" "$(RCLONE_VERSION)" "$(RESTIC_VERSION)" arm64 7

docker-386: clean
	bash scripts/build-docker.sh "$(IMAGE_NAME)" "$(BIVAC_VERSION)" "$(GO_VERSION)" "$(RCLONE_VERSION)" "$(RESTIC_VERSION)" 386

clean:
	rm -f bivac coverage
	git clean -fXd -e \!vendor -e \!.local
