# Example LDAP / SASL / Kerberos / TiDB Server

This docker image will setup an slapd, kerberos, and a tidb server. Run the following command will create an interactive bash with the `slapd`, `krb5` and `tidb` booted.

```
docker run -it --name tidb-with-ldap -h "example.org" -p4000:4000 tidb-with-ldap:latest /bin/bash
```

## `slapd` configuration

1. The base dn of `slapd` is `dc=example,dc=org`. It includes two users: `admin` and `yangkeao`. The password of both of them are `123456`.
2. The `sasl` is configured to authenticate with `sasldb2`. The user `yangkeao@example.org` is added in the `sasldb2` with password `123456`, so you can login the user `yangkeao` with sasl2.
3. The TLS is also enabled. The CA certificate/key is under `/ssl/example.crt` and `/ssl/example.key`. The signed certificate is assigned with DNS `localhost` and IP `127.0.0.1` in `ssl/ldap.crt`/`ssl/ldap.key`. However the key of CA certificate is not included in the docker image, as it's not needed for the bootstrap of `slapd`.

## `kerberos` configuration

TODO

## TiDB server configuration

1. An user `yangkeao` is added to the tidb database, authenticated with `LDAP_SASL` and the dn is `cn=yangkeao,dc=example,dc=org`.
2. An user `cbc` is added to the tidb database, authenticated with `LDAP_SASL` and the dn is `uid=cbc,dc=example,dc=org`.

## Buide the image

```

export TIDB_SRC = '<source code path to tidb>' && make ldap-sasl-tidb
```

Client-side plugin for mysql, `authentication_ldap_sasl_client.so`, can be downloaded in https://ubuntu.pkgs.org/22.04/mysql-8.0-amd64/mysql-community-client-plugins_8.0.33-1ubuntu22.04_amd64.deb.html