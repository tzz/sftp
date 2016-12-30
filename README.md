# Supported tags and respective `Dockerfile` links

- [`debian-jessie`, `debian`, `latest` (*Dockerfile*)](https://github.com/tzz/sftp/blob/master/Dockerfile) [![](https://images.microbadger.com/badges/image/tzlatanov/sftp.svg)](http://microbadger.com/images/tzz/sftp "Get your own image badge on microbadger.com")

# Securely share your files

Easy to use SFTP ([SSH File Transfer Protocol](https://en.wikipedia.org/wiki/SSH_File_Transfer_Protocol)) server with [OpenSSH](https://en.wikipedia.org/wiki/OpenSSH).
This is an automated build linked with the [debian](https://hub.docker.com/_/debian/) and [alpine](https://hub.docker.com/_/alpine/) repositories.

# Usage

- Define users as command arguments, STDIN or mounted in `/etc/sftp-users.conf`
  (syntax: `user:pass[:e][:uid[:gid[:dir1[,dir2]...]]]...`).
  - Set UID/GID manually for your users if you want them to make changes to
    your mounted volumes with permissions matching your host filesystem.
  - Add directory names at the end, if you want to create them and/or set user
    ownership. Perfect when you just want a fast way to upload something without
    mounting any directories, or you want to make sure a directory is owned by
    a user (chown -R).
- Mount volumes in user's home directory.
  - The users are chrooted to their home directory, so you must mount the
    volumes in separate directories inside the user's home directory
    (/home/user/**mounted-directory**).

# Examples


## Simplest docker run example

```
docker run -p 22:22 -d tzz/sftp foo:pass:::upload
```

User "foo" with password "pass" can login with sftp and upload files to a folder called "upload". No mounted directories or custom UID/GID. Later you can inspect the files and use `--volumes-from` to mount them somewhere else (or see next example).

## Sharing a directory from your computer

Let's mount a directory and set UID:

```
docker run \
    -v /host/share:/home/foo/share \
    -p 2222:22 -d tzz/sftp \
    foo:123:1001
```

### Using Docker Compose:

```
sftp:
    image: tzz/sftp
    volumes:
        - /host/share:/home/foo/share
    ports:
        - "2222:22"
    command: foo:123:1001
```

### Logging in

The OpenSSH server runs by default on port 22, and in this example, we are
forwarding the container's port 22 to the host's port 2222. To log in with the
OpenSSH client, run: `sftp -P 2222 foo@<host-ip>`

## Store users in config

```
docker run \
    -v /host/users.conf:/etc/sftp-users.conf:ro \
    -v /host/share:/home/foo/share \
    -v /host/documents:/home/foo/documents \
    -v /host/http:/home/bar/http \
    -p 2222:22 -d tzz/sftp
```

/host/users.conf:

```
foo:123:1001
bar:abc:1002
```

## Encrypted password

Add `:e` behind password to mark it as encrypted. Use single quotes if using terminal.

```
docker run \
    -v /host/share:/home/foo/share \
    -p 2222:22 -d tzz/sftp \
    'foo:$1$0G2g0GSt$ewU0t6GXG15.0hWoOX8X9.:e:1001'
```

Tip: you can use [atmoz/makepasswd](https://hub.docker.com/r/atmoz/makepasswd/) to generate encrypted passwords:  
`echo -n "your-password" | docker run -i --rm atmoz/makepasswd --crypt-md5 --clearfrom=-`

## Using SSH key (and no password)

Mount all public keys in the user's `.ssh/keys/` directory. All keys are automatically
appended to `.ssh/authorized_keys`.

```
docker run \
    -v /host/id_rsa.pub:/home/foo/.ssh/keys/id_rsa.pub:ro \
    -v /host/id_other.pub:/home/foo/.ssh/keys/id_other.pub:ro \
    -v /host/share:/home/foo/share \
    -p 2222:22 -d tzz/sftp \
    foo::1001
```

## Execute custom scripts or applications

Put your programs in `/etc/sftp.d/` and it will automatically run when the container starts.
See next section for an example.

## Bindmount dirs from another location

If you are using `--volumes-from` or just want to make a custom directory
available in user's home directory, you can add a script to `/etc/sftp.d/` that
bindmounts after container starts.

```
#!/bin/bash
# File mounted as: /etc/sftp.d/bindmount.sh
# Just an example (make your own)

function bindmount() {
    if [ -d "$1" ]; then
        mkdir -p "$2"
    fi
    mount --bind $3 "$1" "$2"
}

# Remember permissions, you may have to fix them:
# chown -R :users /data/common

bindmount /data/admin-tools /home/admin/tools
bindmount /data/common /home/dave/common
bindmount /data/common /home/peter/common
bindmount /data/docs /home/peter/docs --read-only
```

Here's another bindmount example using `s3fs`. You'll have to pass in the
`BIND_USER`, `BIND_DIR`, `S3_BUCKET`, `S3_DIR`, `S3_REGION`, and `IAM_ROLE` as
environment variables to the container.

```
#!/bin/bash
# File mounted as: /etc/sftp.d/bindmount.sh

mkdir -p ${BIND_DIR}
chown -R ${BIND_USER} ${BIND_DIR}

s3fs ${S3_BUCKET}:${S3_DIR} ${BIND_DIR} -o enable_noobj_cache -o stat_cache_expire=30 -o enable_content_md5 -o iam_role=${IAM_ROLE} -o endpoint=${S3_REGION} -o allow_other -o uid=$(id -u ${BIND_USER})
```
