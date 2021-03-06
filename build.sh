#!/bin/bash

set -o pipefail
set -o errexit

EXTERNAL_DEPENDENCIES=(
        "golang.org/x/crypto/ssh/terminal"
        "github.com/stretchr/testify/assert"
        "github.com/sirupsen/logrus"
        "github.com/chzyer/readline"
        "github.com/fatih/color"
        "github.com/marcusolsson/tui-go"
)

COMPONENTS=(
        "cmd/client"
        "cmd/server"
)

PROJECT_DIR=$(pwd)
PROJECT_BUILD_OUTPUT_DIR="build"

VERSION_TEMPLATE="misc/version.template"

generate_version() {
        local gitVersion=$(git describe)
        for component in ${COMPONENTS[@]}
        do
                cat ${VERSION_TEMPLATE} | sed "s/@@VERSION_PLACEHOLDER@@/${gitVersion}/g" > "${component}/version.go"
        done
}

resolve_deps() {
        for component in ${EXTERNAL_DEPENDENCIES[@]}
        do
                go get $component
        done
}

run_test() {
        for component in ${COMPONENTS[@]}
        do
                cd "${component}"
                go test || exit 1
                cd "${PROJECT_DIR}"
        done
}

run_build() {
        if [[ ! -d "build" ]]; then
                mkdir build
        fi

        resolve_deps
        generate_version

        for component in ${COMPONENTS[@]}
        do
                cd "$component"
                go build -o "${PROJECT_DIR}/${PROJECT_BUILD_OUTPUT_DIR}/$(basename ${component})"
                cd "${PROJECT_DIR}"
        done

        #if [[ ! -e ${PROJECT_DIR}/misc/UserConfigs.json ]]; then
        #        cp ${PROJECT_DIR}/misc/UserConfigs.json ${PROJECT_DIR}/build
        #fi
}

run_clean() {
        rm -rf "${PROJECT_BUILD_OUTPUT_DIR}"
}

main() {
        case $1 in
        "-c")
                run_clean
                ;;
        "-t")
                run_test
                ;;
        "-b")
                run_build
                ;;
        *)
                run_clean
                run_build
                run_test
                ;;
        esac
}

main $@
