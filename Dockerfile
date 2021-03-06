FROM kalilinux/kali-linux-docker
MAINTAINER xn0px90@gmail.com
RUN echo "deb http://http.kali.org/kali kali-rolling main contrib non-free" > /etc/apt/sources.list && \
    echo "deb-src http://http.kali.org/kali kali-rolling main contrib non-free" >> /etc/apt/sources.list
ENV $DEBIAN_FRONTEND noninteractive RUN apt-get -y update && apt-get -y dist-upgrade && apt-get clean

# tools and deps 
RUN apt-get update; apt-get -y upgrade
RUN apt-get install -y \
		curl \
		openssl \
		g++ \
		gcc \
		libc6-dev \
		make \
		software-properties-common \
		python-all-dev \
		wget \
		libcapstone-dev \
		libzip-dev \
		libmagic-dev \
		httpie \
 		swig \ 
 		flex \ 
 		bison \
 		tmux \
 		git \ 
 		pkg-config \
 		glib-2.0 \
		python-gobject-dev \ 
		valgrind \ 
		gdb \
	&& rm -rf /var/lib/apt/lists/*
# Install Go
ENV GOLANG_VERSION 1.7.3
ENV GOLANG_DOWNLOAD_URL https://golang.org/dl/go$GOLANG_VERSION.linux-amd64.tar.gz
ENV GOLANG_DOWNLOAD_SHA256 508028aac0654e993564b6e2014bf2d4a9751e3b286661b0b0040046cf18028e

RUN curl -fsSL "$GOLANG_DOWNLOAD_URL" -o golang.tar.gz \
	&& echo "$GOLANG_DOWNLOAD_SHA256  golang.tar.gz" | sha256sum -c - \
	&& tar -C /usr/local -xzf golang.tar.gz \
	&& rm golang.tar.gz

ENV GOPATH /go
ENV PATH $GOPATH/bin:/usr/local/go/bin:$PATH

RUN mkdir -p "$GOPATH/src" "$GOPATH/bin" && chmod -R 777 "$GOPATH"
WORKDIR $GOPATH

COPY go-wrapper /usr/local/bin/
#debugging Go apps with dlv DWARF spec th eright way
RUN go get github.com/derekparker/delve/cmd/dlv 


# Set correct environment variables.
ENV HOME /root
# create code directory
RUN mkdir -p /opt/code/
# install packages required to compile vala and radare2
RUN apt-get update
RUN apt-get upgrade -y

ENV VALA_TAR vala-0.26.1

# compile vala
RUN cd /opt/code && \
	wget -c https://download.gnome.org/sources/vala/0.26/${VALA_TAR}.tar.xz && \
	shasum ${VALA_TAR}.tar.xz | grep -q 0839891fa02ed2c96f0fa704ecff492ff9a9cd24 && \
	tar -Jxf ${VALA_TAR}.tar.xz
RUN cd /opt/code/${VALA_TAR}; ./configure --prefix=/usr ; make && make install
# compile radare and bindings
RUN cd /opt/code 
RUN git clone https://github.com/radare/radare2.git
RUN cd radare2; ./sys/install.sh

#VIM SPF13 awesome stuff
#RUN curl https://j.mp/spf13-vim3 -L > spf13-vim.sh && sh spf13-vim.sh


# Clean up APT when done.
RUN apt-get -y update && apt-get -y dist-upgrade
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN r2 -V
RUN r2pm -i r2pipe-go
CMD ["/bin/bash"]
