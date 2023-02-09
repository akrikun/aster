FROM centos:8

WORKDIR /tmp
RUN cd /etc/yum.repos.d/
RUN sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*
RUN sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*
RUN dnf install -y epel-release \
&&  dnf groupinstall -y "Development Tools" \
&& dnf install -y git wget net-tools sqlite-devel psmisc ncurses-devel libtermcap-devel newt-devel libxml2-devel libtiff-devel gtk2-devel libtool libuuid-devel subversion kernel-devel crontabs cronie-anacron mariadb mariadb-server
RUN wget https://dev.mysql.com/get/mysql80-community-release-el8-1.noarch.rpm \
&& dnf localinstall -y mysql80-community-release-el8-1.noarch.rpm
RUN echo -e "[MySQL-asterisk]\nDescription = MySQL Asterisk database\nDriver = MySQL\nServer = localhost\nUser = asterisk_user\nPassword = 12345678\nSocket = /var/lib/mysql/mysql.sock\nDatabase = asterisk" >> /etc/odbc.ini
RUN echo -e "CPTimeout = \nCPReuse =" >> /etc/odbcinst.ini
RUN wget http://sourceforge.net/projects/lame/files/lame/3.100/lame-3.100.tar.gz \
&& tar zxvf lame-3.* 
RUN cd lame-3.100 \
&& ./configure \
&& make && make install
RUN git clone https://github.com/akheron/jansson.git \
&& cd jansson \
&& autoreconf -i \
&& ./configure --prefix=/usr/ \
&& make -j8 && make install
RUN cd /tmp \
&& git clone https://github.com/pjsip/pjproject.git \
&& cd pjproject \
&& ./configure CFLAGS="-DNDEBUG -DPJ_HAS_IPV6=1" --prefix=/usr --libdir=/usr/lib64 --enable-shared --disable-video --disable-sound --disable-opencore-amr \
&& make dep && make -j8 && make install
RUN cd /tmp \
&& wget http://downloads.asterisk.org/pub/telephony/asterisk/asterisk-16-current.tar.gz
RUN cd /tmp \
&& dnf config-manager --set-enabled powertools \
&& tar -xf asterisk-16-current.tar.gz \
&& cd asterisk-16.29.1 \
&& ./contrib/scripts/install_prereq install \
&& ./contrib/scripts/get_mp3_source.sh \
&& dnf install -y libedit-devel \
&& ./configure --libdir=/usr/lib64 \
&& make -j8 \
&& ./menuselect/menuselect --enable format_mp3 --enable CORE-SOUNDS-RU-WAV --enable EXTRA-SOUNDS-EN-WAV \
&& make -j8 && make install && make samples && make config
RUN groupadd asterisk \
&& useradd -r -d /var/lib/asterisk -g asterisk asterisk \
&& usermod -aG audio,dialout asterisk \
&& chown -R asterisk.asterisk /etc/asterisk /var/{lib,log,spool}/asterisk /usr/lib64/asterisk
RUN sed -i 's";\[radius\]"\[radius\]"g' /etc/asterisk/cdr.conf \
&& sed -i 's";radiuscfg => /usr/local/etc/radiusclient-ng/radiusclient.conf"radiuscfg => /etc/radcli/radiusclient.conf"g' /etc/asterisk/cdr.conf \
&& sed -i 's";radiuscfg => /usr/local/etc/radiusclient-ng/radiusclient.conf"radiuscfg => /etc/radcli/radiusclient.conf"g' /etc/asterisk/cel.conf
RUN mkdir /mnt/calls \
&& chown -R asterisk. /mnt/calls
COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh
ENTRYPOINT /entrypoint.sh