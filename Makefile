VERSION        := $(shell git describe --always --dirty 2>/dev/null || echo "v$(BIVAC_VERSION)")
COMMIT_SHA1    := $(shell git rev-parse HEAD 2>/dev/null || echo "unknown")
BUILD_DATE     := $(shell date +%Y-%m-%d)
IMAGE_NAME     := docker.io/jusito/bivac
BIVAC_VERSION  := 2.5.1

GO_VERSION     := 1.25
RCLONE_VERSION := v1.71.2
RESTIC_VERSION := v0.18.1

LDFLAGS := -s -w \
           -X main.version=$(VERSION) \
           -X main.buildDate=$(BUILD_DATE) \
           -X main.commitSha1=$(COMMIT_SHA1)

.PHONY: all check lint vet clean test release docker-images

all: check lint vet clean test

# Check for retracted packages
check:
	scripts/build/check_retracted.sh "Bivac" "current"
	scripts/build/build_rclone.sh $(RCLONE_VERSION) $(BUILD_DATE) ".local/rclone"
	scripts/build/build_restic.sh $(RESTIC_VERSION) $(BUILD_DATE) ".local/restic"
	echo "checked!"

lint:
	@command -v staticcheck >/dev/null 2>&1 || (echo "staticcheck not found. Run: go install honnef.co/go/tools/cmd/staticcheck@latest" && exit 1)
	staticcheck ./...

vet: main.go
	go vet ./...

test:
	go test -cover -v ./...

bivac: main.go $(wildcard */*/*/*.go)
	CGO_ENABLED=0 go build -ldflags="$(LDFLAGS)" -o bivac main.go

release: clean
	GO_VERSION=$(GO_VERSION) ./scripts/build-release.sh

docker-images: clean
	bash scripts/build-docker.sh "$(IMAGE_NAME)" "$(BIVAC_VERSION)" "$(GO_VERSION)" "$(RCLONE_VERSION)" "$(RESTIC_VERSION)"

clean:
	rm -f bivac coverage
	git clean -fXd -e \!vendor -e \!.local
