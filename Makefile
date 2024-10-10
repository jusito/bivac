DEPS = $(wildcard */*/*/*.go)
VERSION = $(shell git describe --always --dirty)
COMMIT_SHA1 = $(shell git rev-parse HEAD)
BUILD_DATE = $(shell date +%Y-%m-%d)
IMAGE_NAME = docker.io/jusito/bivac
BIVAC_VERSION = 2.5.1

GO_VERSION = 1.23
RCLONE_VERSION = v1.68.1
RESTIC_VERSION = v0.17.1

#ll: lint vet test bivac # triggered? You are welcome to fix it
all: test bivac

bivac: main.go $(DEPS)
	GO111MODULE=on CGO_ENABLED=0 GOARCH=$(GOARCH) GOOS=$(GOOS) GOARM=$(GOARM) \
	  go build \
	    -a -ldflags="-s -X main.version=$(VERSION) -X main.buildDate=$(BUILD_DATE) -X main.commitSha1=$(COMMIT_SHA1)" \
	    -installsuffix cgo -o $@ $<
	@if [ "${GOOS}" = "linux" ] && [ "${GOARCH}" = "amd64" ]; then strip $@; fi

release: clean
	GO_VERSION=$(GO_VERSION) ./scripts/build-release.sh

docker-images: clean
	bash scripts/build-docker.sh "$(IMAGE_NAME)" "$(BIVAC_VERSION)" "$(GO_VERSION)" "$(RCLONE_VERSION)" "$(RESTIC_VERSION)"

lint:
	go install honnef.co/go/tools/cmd/staticcheck@2024.1
	@for file in $$(go list ./... | grep -v '_workspace/' | grep -v 'vendor'); do \
		export output="$$(staticcheck $${file})"; \
		[ -n "$${output}" ] && echo "$${output}" && export status=1; \
	done; \
	exit $${status:-0}

vet: main.go
	go vet $<

clean:
	git clean -fXd -e \!vendor -e \!vendor/**/* && rm -f ./bivac

test:
	go test -cover -coverprofile=coverage -v ./...

.PHONY: all lint vet clean test
