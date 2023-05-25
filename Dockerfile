# Prepare tidb
FROM rockylinux:9

ENV GOLANG_VERSION 1.20.4
ENV ARCH amd64
ENV GOLANG_DOWNLOAD_URL https://dl.google.com/go/go$GOLANG_VERSION.linux-$ARCH.tar.gz
ENV GOPATH /go
ENV GOROOT /usr/local/go
ENV PATH $GOPATH/bin:$GOROOT/bin:$PATH

RUN yum update -y && yum groupinstall 'Development Tools' -y \
  && yum install -y mysql.x86_64 \
  && curl -fsSL "$GOLANG_DOWNLOAD_URL" -o golang.tar.gz \
	&& tar -C /usr/local -xzf golang.tar.gz \
	&& rm golang.tar.gz

COPY ./tidb /tidb
COPY ./mysql-community-client-plugins-8.0.33-1.el9.x86_64.rpm /mysql-community-client-plugins.rpm
RUN yum install -y /mysql-community-client-plugins.rpm

ARG GOPROXY
RUN export GOPROXY=${GOPROXY} && cd /tidb && make server \
  && cp /tidb/bin/tidb-server /tidb-server \
  && rm -rf /tidb /go /usr/local/go /mysql-community-client-plugins.rpm

# # Prepare LDAP

# COPY ./debconf-slapd.conf /tmp/debconf-slapd.conf
# RUN cat /tmp/debconf-slapd.conf | DEBIAN_FRONTEND=noninteractive debconf-set-selections
# RUN DEBIAN_FRONTEND=noninteractive apt-get install slapd ldap-utils libldap-2.5-0 sasl2-bin slapd-contrib libsasl2-modules libsasl2-modules-gssapi-mit libsasl2-modules-ldap -y

# COPY ./slapd.conf.ldif /tmp/slapd.conf.ldif
# RUN ulimit -n 1024 && service slapd start && ldapmodify -Y EXTERNAL -H ldapi:/// -f /tmp/slapd.conf.ldif && service slapd stop
# COPY ./user.ldif /tmp/user.ldif
# RUN ulimit -n 1024 && service slapd start && ldapadd -x -D "cn=admin,dc=example,dc=org" -w 123456 -H ldapi:/// -f /tmp/user.ldif && service slapd stop

# RUN echo "123456" |saslpasswd2 -c yangkeao -u example.org -p
# RUN usermod -aG sasl openldap

# COPY ./ssl.ldif /tmp/ssl.ldif
# COPY ./ssl/ldap.key /etc/ssl/private/ldap.key
# COPY ./ssl/ldap.crt /etc/ssl/certs/ldap.crt
# COPY ./ssl/example.crt /etc/ssl/certs/example.crt
# RUN chmod 777 -R /etc/ssl
# RUN ulimit -n 1024 && service slapd start && ldapmodify -H ldapi:// -Y EXTERNAL -f /tmp/ssl.ldif && service slapd stop

# # Prepare Kerberos

# COPY kerberos.openldap.ldif /tmp/kerberos.openldap.ldif
# COPY index.ldif /tmp/index.ldif
# COPY user2.ldif /tmp/user2.ldif
# COPY alc.ldif /tmp/alc.ldif
# COPY debconf-krb5-config.conf /tmp/debconf-krb5-config.conf
# COPY services.ldif /tmp/services.ldif
# COPY slapd /etc/default/slapd
# COPY reg.ldif /tmp/reg.ldif
# COPY ldap.conf /etc/ldap/ldap.conf

# RUN cat /tmp/debconf-krb5-config.conf | DEBIAN_FRONTEND=noninteractive debconf-set-selections
# RUN apt-get update -y && DEBIAN_FRONTEND=noninteractive apt-get install krb5-kdc krb5-admin-server krb5-kdc-ldap krb5-pkinit schema2ldif -y

# RUN ulimit -n 1024 && service slapd start && ldapadd -Q -Y EXTERNAL -H ldapi:/// -f /tmp/kerberos.openldap.ldif \
#   && ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f /tmp/index.ldif \
#   && ldapadd -x -D "cn=admin,dc=example,dc=org" -w 123456 -H ldapi:/// -f /tmp/user2.ldif \
#   && ldapadd -x -D "cn=admin,dc=example,dc=org" -w 123456 -H ldapi:/// -f /tmp/services.ldif \
#   && service slapd stop

# RUN ulimit -n 1024 && service slapd start && ldappasswd -x -D cn=admin,dc=example,dc=org -w 123456 -s 123456 uid=kdc,ou=kerberos,ou=services,dc=example,dc=org && service slapd stop
# RUN ulimit -n 1024 && service slapd start && ldappasswd -x -D cn=admin,dc=example,dc=org -w 123456 -s 123456 uid=kadmin,ou=kerberos,ou=services,dc=example,dc=org && service slapd stop
# RUN ulimit -n 1024 && service slapd start && ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f /tmp/alc.ldif && service slapd stop

# COPY ./krb5.conf /etc/krb5.conf
# COPY ./kdc.conf /etc/krb5kdc/kdc.conf
# COPY ./kadm5.acl /etc/krb5kdc/kadm5.acl

# # The following steps need to read kdc.conf
# RUN service slapd start && printf "123456\n123456\n123456" | kdb5_ldap_util -D "cn=admin,dc=example,dc=org" create -subtrees dc=example,dc=org -r EXAMPLE.ORG -s -H ldapi:/// -sscope 2 && service slapd stop
# RUN service slapd start && printf "123456\n123456\n123456" | kdb5_ldap_util -D cn=admin,dc=example,dc=org stashsrvpw -f /etc/krb5kdc/service.keyfile uid=kdc,ou=kerberos,ou=services,dc=example,dc=org && service slapd stop
# RUN service slapd start && printf "123456\n123456\n123456" | kdb5_ldap_util -D cn=admin,dc=example,dc=org stashsrvpw -f /etc/krb5kdc/service.keyfile uid=kadmin,ou=kerberos,ou=services,dc=example,dc=org && service slapd stop

# RUN service slapd start && service krb5-kdc start && service krb5-admin-server start \
#   && kadmin.local -q "addprinc -pw 123456 -x dn=uid=cbc,dc=example,dc=org cbc@EXAMPLE.ORG" \
#   && kadmin.local -q "addprinc -randkey ldap/example.org" \
#   && kadmin.local -q "ktadd -k /etc/krb5.keytab ldap/example.org" \
#   && chown openldap:openldap /etc/krb5.keytab \
#   && chmod 600 /etc/krb5.keytab \
#   && ldapmodify -H ldapi:/// -Y EXTERNAL -f /tmp/reg.ldif

WORKDIR /
EXPOSE 4000
COPY ./entrypoint.sh /entrypoint.sh
ENTRYPOINT [ "/entrypoint.sh" ]