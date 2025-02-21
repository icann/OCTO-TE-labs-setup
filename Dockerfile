FROM registry.access.redhat.com/ubi9/ubi:latest
LABEL io.k8s.description "Red Hat UBI 9 image"
LABEL maintainer="mcirilo@icann.org" \
      url="https://github.com/icann/Dockerfiles" \
      vcs-type="git" vcs-url="git@github.com:icann/Dockerfiles.git"

USER 0:0

ENV ICANN_BASEIMAGE="icann-base"
RUN echo ${ICANN_BASEIMAGE} >> /etc/icann-container-baseimage

RUN dnf -y install unzip \
    && dnf clean all

RUN rm -rf /var/cache/dnf/ubi-9*

# add bashrc to set PS1 to say "docker"
ADD common/bashrc /root/.bashrc
ADD common/bashrc /.profile
ADD common/icann-bash-profile.sh /etc/profile.d/icann-bash-profile.sh

# this can get variables injected into it, see also Jenkins software
ADD common/icann_setenv.sh /etc/icann_setenv.sh
# htcache script used to prune cache when running on shared tmpfs
ADD common/icann-htcache.sh /usr/local/bin/icann-htcache.sh

ADD common/icann-last-commit-as-json.sh /usr/local/bin/icann-last-commit-as-json.sh
ADD common/icann-rpm-json.sh /usr/local/bin/icann-rpm-json.sh
ADD common/icann-timestamp-as-json.sh /usr/local/bin/icann-timestamp-as-json.sh
ADD common/generic-mysqldump.sh /usr/local/bin/generic-mysqldump.sh
ADD common/sqlc.sh /usr/local/bin/sqlc.sh

# replace the default self-signed certificate. mod_ssl wants a localhost.crt
RUN openssl req -nodes -new -x509 -days 180 -newkey rsa:4096 \
       -keyout /etc/pki/tls/private/localhost.key \
       -out /etc/pki/tls/certs/localhost.crt \
       -subj "/C=US/ST=California/L=Los Angeles/O=ICANN/OU=ICANN IT Ops/CN=localhost" \
       -addext "subjectAltName=DNS:localhost,DNS:*.icann.org,DNS:*.icann-production.svc.cluster.local,IP:127.0.0.1" \
    && cp /etc/pki/tls/certs/localhost.crt /etc/pki/ca-trust/source/anchors/localhost.pem

# this adds the certificate to the OS the proper way.
# Child images can import this pem into the java keystore for LDAP and so on.
ADD anchors /etc/pki/ca-trust/source/anchors
RUN /usr/bin/update-ca-trust extract

# this is otherwise unset but you need it for top
ENV TERM=xterm-256color

# java requires this and it probably benefits other things
ENV LANG=en_US.UTF-8

# install the aws cli for linux
RUN cd /tmp \
    && curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && ./aws/install \
    && rm -rf awscli*

USER 32767:0

CMD ["bash"]
