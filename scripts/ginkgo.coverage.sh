#!/usr/bin/env bash

# Copyright 2016 The Kubernetes Authors All rights reserved.
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

set -eo pipefail

covermode=${COVERMODE:-atomic}
coverdir=$(mktemp -d /tmp/coverage.XXXXXXXXXX)
profile="${coverdir}/cover.out"

hash goveralls 2>/dev/null || go get github.com/mattn/goveralls
hash godir 2>/dev/null || go get github.com/Masterminds/godir

generate_cover_data() {
  ginkgo -skipPackage test/e2e/dcos,test/e2e/kubernetes -cover -r .
  find . -type f -name "*.coverprofile" | while read -r file; do mv $file ${coverdir}; done

  echo "mode: $covermode" >"$profile"
  grep -h -v "^mode:" "$coverdir"/*.coverprofile >>"$profile"
}

push_to_coveralls() {
  goveralls -coverprofile="${profile}" -repotoken $COVERALLS_TOKEN
}

generate_cover_data
go tool cover -func "${profile}"

case "${1-}" in
  --html)
    go tool cover -html "${profile}"
    ;;
  --coveralls)
		if [ -z $COVERALLS_TOKEN ]; then
			echo '$COVERALLS_TOKEN not set. Skipping pushing coverage report to coveralls.io'
			exit
		fi
    push_to_coveralls
    ;;
esac