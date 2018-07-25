#!/usr/bin/env bash
set -ex

# The script does automatic checking on a Go package and its sub-packages,
# including:
# 1. gofmt         (http://golang.org/cmd/gofmt/)
# 2. go vet        (http://golang.org/cmd/vet)
# 3. gosimple      (https://github.com/dominikh/go-simple)
# 4. unconvert     (https://github.com/mdempsky/unconvert)
# 5. ineffassign   (https://github.com/gordonklaus/ineffassign)
# 6. misspell      (https://github.com/client9/misspell)
# 7. race detector (http://blog.golang.org/race-detector)

# gometalinter (github.com/alecthomas/gometalinter) is used to run each each
# static checker.

# To run on docker on windows, symlink /mnt/c to /c and then execute the script
# from the repo path under /c.  See:
# https://github.com/Microsoft/BashOnWindows/issues/1854
# for more details.

#Default GOVERSION
GOVERSION=${1:-1.10}
REPO=hcstakepool
DOCKER_IMAGE_TAG=HcashOrg-golang-builder-$GOVERSION

testrepo () {
  TMPFILE=$(mktemp)

  # Check lockfile
  cp Gopkg.lock $TMPFILE && dep ensure && diff Gopkg.lock $TMPFILE >/dev/null
  if [ $? != 0 ]; then
    echo 'lockfile must be updated with dep ensure'
    exit 1
  fi

  # Check linters
  gometalinter --vendor --disable-all --deadline=10m \
    --enable=gofmt \
    --enable=gosimple \
    --enable=unconvert \
    --enable=ineffassign \
    --enable=misspell \
    ./...
  if [ $? != 0 ]; then
    echo 'gometalinter has some complaints'
    exit 1
  fi

  # Test application install
  if [ $GOVERSION == "1.10" ]; then
    go install -i . ./backend/...
  else
    go install . ./backend/...
  fi
  if [ $? != 0 ]; then
    echo 'go install failed'
    exit 1
  fi

  # Check tests
  env GORACE='halt_on_error=1' go test -short -race ./...
  if [ $? != 0 ]; then
    echo 'go tests failed'
    exit 1
  fi

  echo "------------------------------------------"
  echo "Tests completed successfully!"
}

if [ $GOVERSION == "local" ]; then
    testrepo
    exit
fi

mkdir -p ~/.cache

if [ -f ~/.cache/$DOCKER_IMAGE_TAG.tar ]; then
	# load via cache
	docker load -i ~/.cache/$DOCKER_IMAGE_TAG.tar
	if [ $? != 0 ]; then
		echo 'docker load failed'
		exit 1
	fi
else
	# pull and save image to cache
	docker pull HcashOrg/$DOCKER_IMAGE_TAG
	if [ $? != 0 ]; then
		echo 'docker pull failed'
		exit 1
	fi
	docker save HcashOrg/$DOCKER_IMAGE_TAG > ~/.cache/$DOCKER_IMAGE_TAG.tar
	if [ $? != 0 ]; then
		echo 'docker save failed'
		exit 1
	fi
fi

docker run --rm -it -v $(pwd):/src HcashOrg/$DOCKER_IMAGE_TAG /bin/bash -c "\
  rsync -ra --filter=':- .gitignore'  \
  /src/ /go/src/github.com/HcashOrg/$REPO/ && \
  cd github.com/HcashOrg/$REPO/ && \
  bash run_tests.sh local"
if [ $? != 0 ]; then
	echo 'docker run failed'
	exit 1
fi
