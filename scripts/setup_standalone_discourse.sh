#!/bin/sh
set -e
set -x

# install needed packages
yum update -y
yum install docker git -y

# disable selinux (not playing well with docker/pgsql)
setenforce 0
cat >/etc/selinux/config <<EOF
SELINUX=enforcing
SELINUXTYPE=targeted
EOF

# setup the docker service
service docker start
chkconfig --level 345 docker on

# anonymously clone discourse docker
cd /var/
git clone https://github.com/discourse/discourse_docker.git discourse
cd discourse

# setup instance from provided env variables

cp samples/standalone.yml containers/app.yml -f -y

sed -i s/DISCOURSE_SMTP_ADDRESS:\ smtp.example.com/DISCOURSE_SMTP_ADDRESS:\ "$SMTP_SERVER"/g containers/app.yml
sed -i s/\#DISCOURSE_SMTP_PORT:\ 587/DISCOURSE_SMTP_PORT:\ "$SMTP_PORT"/g containers/app.yml
sed -i s/\#DISCOURSE_SMTP_USER_NAME:\ user@example.com/DISCOURSE_SMTP_USER_NAME:\ "$SMTP_USER"/g containers/app.yml
sed -i s/\#DISCOURSE_SMTP_PASSWORD:\ pa\$\$word/DISCOURSE_SMTP_PASSWORD:\ "$SMTP_PASSWORD"/g containers/app.yml
sed -i s/DISCOURSE_HOSTNAME:\ \'discourse.example.com\'/DISCOURSE_HOSTNAME:\ \'"$DOMAIN_NAME"\'/g containers/app.yml
sed -i s/DISCOURSE_DEVELOPER_EMAILS:\ \'me@example.com\'/DISCOURSE_DEVELOPER_EMAILS:\ \'"$ADMIN_EMAIL"\'/g containers/app.yml
sed -i s/LANG:\ en_US.UTF-8/LANG:\ es_ES.UTF-8/g containers/app.yml

# bootstrap and start

./launcher bootstrap app
./launcher start app

# TODO(mangelajo): create admin user

./launcher ssh app <<EOF
rails c
User.find_by_email('miguelangel@ajo.es')
EOF


# (in rails console)
#> me = User.find_by_username_or_email('myemailaddress@me.com')
#> me.activate #use this in case you haven't configured your mail server and therefore can't receive the activation mail.
#> me.admin = true
#u=User.where(:email => 'usermail@gmail.com').first
#u.password='userpassword'
#u.password_confirmation='userpassword'
#u.save!
#> me.save
