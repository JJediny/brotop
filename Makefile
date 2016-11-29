VERSION=$(shell cat VERSION)
BUILDVERSION=$(shell cat VERSION)
GO_VERSION=$(shell go version)

# Get the git commit
SHA=$(shell git rev-parse --short HEAD)
BUILD_COUNT=$(shell git rev-list --count HEAD)
CWD=$(shell pwd)

NAME="brotop"
DESCRIPTION="Top for bro log files."

CCOS=windows freebsd darwin linux
CCARCH=386 amd64
CCOUTPUT="pkg/{{.OS}}-{{.Arch}}/$(NAME)"

NO_COLOR=\033[0m
OK_COLOR=\033[32;01m
ERROR_COLOR=\033[31;01m
WARN_COLOR=\033[33;01m
DEPS = $(go list -f '{{range .TestImports}}{{.}} {{end}}' ./...)
UNAME := $(shell uname -s)

ifeq ($(UNAME),Darwin)
	ECHO=echo
else
	ECHO=/bin/echo -e
endif

all: deps
	@mkdir -p bin/
	@$(ECHO) "$(OK_COLOR)==> Building $(NAME) $(NO_COLOR)"
	@godep go build -o bin/$(NAME)
	@chmod +x bin/$(NAME)
	@./bin/$(NAME) --version >> VERSION
	@$(ECHO) "$(OK_COLOR)==> Done$(NO_COLOR)"


deps: bindata
	@$(ECHO) "$(OK_COLOR)==> Installing dependencies$(NO_COLOR)"
	@godep get

updatedeps:
	@$(ECHO) "$(OK_COLOR)==> Updating all dependencies$(NO_COLOR)"
	@go get -d -v -u ./...
	@echo $(DEPS) | xargs -n1 go get -d -u
	@godep update ...

bindata:
	@$(ECHO) "$(OK_COLOR)==> Embedding Assets$(NO_COLOR)"
	@go-bindata web/...

test: deps
	@$(ECHO) "$(OK_COLOR)==> Testing $(NAME)...$(NO_COLOR)"
	godep go test ./...

goxBuild:
	@gox -os="$(CCOS)" -arch="$(CCARCH)" -build-toolchain

gox: 
	@$(ECHO) "$(OK_COLOR)==> Cross Compiling $(NAME)$(NO_COLOR)"
	@gox -os="$(CCOS)" -arch="$(CCARCH)" -output=$(CCOUTPUT)

release: clean all gox
	@mkdir -p release/
	@for os in $(CCOS); do \
		for arch in $(CCARCH); do \
			cd pkg/$$os-$$arch/; \
			tar -zcvf ../../release/$(NAME)-$$os-$$arch.tar.gz brotop* > /dev/null 2>&1; \
			cd ../../; \
		done \
	done
	@$(ECHO) "$(OK_COLOR)==> Done Cross Compiling $(NAME)$(NO_COLOR)"

clean:
	@$(ECHO) "$(OK_COLOR)==> Cleaning$(NO_COLOR)"
	@rm -rf VERSION
	@rm -rf release/
	@rm -rf bin/
	@rm -rf pkg/

install: clean all

uninstall: clean

tar: 

.PHONY: all clean deps
