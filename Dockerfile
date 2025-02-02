FROM ubuntu:22.04 AS builder

RUN export DEBIAN_FRONTEND=noninteractive \
	&& ln -fs /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime

RUN apt-get update && apt-get install -y --no-install-recommends \
	git cmake curl zip unzip tar automake ca-certificates build-essential \
	libglew-dev libx11-dev autoconf libtool pkg-config tzdata libssl3 \
	&& dpkg-reconfigure --frontend noninteractive tzdata \
	&& apt-get clean && apt-get autoclean

WORKDIR /opt
COPY vcpkg.json /opt
RUN vcpkgCommitId=$(grep '.builtin-baseline' vcpkg.json | awk -F: '{print $2}' | tr -d '," ') \
	&& echo "vcpkg commit ID: $vcpkgCommitId" \
	&& git clone https://github.com/Microsoft/vcpkg.git \
	&& cd vcpkg \
	&& git checkout $vcpkgCommitId \
	&& ./bootstrap-vcpkg.sh

WORKDIR /opt/vcpkg
COPY vcpkg.json /opt/vcpkg/
RUN /opt/vcpkg/vcpkg --feature-flags=binarycaching,manifests,versions install

COPY ./ /blue-client/
WORKDIR /blue-client/build

RUN cmake -DCMAKE_TOOLCHAIN_FILE=/opt/vcpkg/scripts/buildsystems/vcpkg.cmake ..
RUN make -j$(nproc)

FROM ubuntu:22.04

RUN apt-get update; \
 	apt-get install -y \
	libluajit-5.1-dev \
 	libglew-dev \
	libx11-dev \
 	libopenal1 \
 	libopengl0 \
 	&& apt-get clean && apt-get autoclean

COPY --from=builder /blue-client /blue-client
COPY ./data/ /blue-client/data/.
COPY ./mods/ /blue-client/mods/.
COPY ./modules/ /blue-client/modules/.
COPY ./init.lua /blue-client/.
WORKDIR /blue-client
CMD ["./blue-client"]
