set -e -o pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if ! [ -x "$(command -v golangci-lint)" ]; then
	echo "Installing GolangCI-Lint"
	${DIR}/util/golangci-lint.sh -b $GOPATH/bin v1.12.2
fi

golangci-lint run \
	--no-config \
    --skip-dirs vendor \
	-E goconst \
	-E goimports \
	-E golint \
	-E interfacer \
	-E maligned \
	-E misspell \
	-E unconvert \
	-E unparam \
	-E errcheck \