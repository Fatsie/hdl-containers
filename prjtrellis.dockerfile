# Authors:
#   Unai Martinez-Corral
#
# Copyright 2019-2021 Unai Martinez-Corral <unai.martinezcorral@ehu.eus>
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
#
# SPDX-License-Identifier: Apache-2.0

FROM alpine as get
RUN apk add --no-cache --update git \
 && git clone --recurse-submodules https://github.com/YosysHQ/prjtrellis /tmp/prjtrellis \
 && cd /tmp/prjtrellis \
 && git describe --tags > libtrellis/git_version

#---

FROM hdlc/build:dev AS build
COPY --from=get /tmp/prjtrellis /tmp/prjtrellis

ENV LDFLAGS "-Wl,--copy-dt-needed-entries"

RUN cd /tmp/prjtrellis/libtrellis \
 && cmake -DCURRENT_GIT_VERSION="$(cat git_version)" . \
 && make -j $(nproc) \
 && make DESTDIR=/opt/prjtrellis install

#---

FROM scratch AS pkg
COPY --from=build /opt/prjtrellis /prjtrellis

#---

FROM hdlc/build:base
COPY --from=build /opt/prjtrellis /

RUN apt-get update -qq \
 && DEBIAN_FRONTEND=noninteractive apt-get -y install --no-install-recommends \
    libboost-all-dev \
    make \
 && apt-get autoclean && apt-get clean && apt-get -y autoremove \
 && rm -rf /var/lib/apt/lists/*
