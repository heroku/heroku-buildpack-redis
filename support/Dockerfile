FROM heroku/cedar:14
MAINTAINER cyberdelia

RUN apt-get -q update
RUN apt-get -q -y install curl gcc g++ make wget unzip awscli

ADD stunnel-build stunnel-build

CMD ./stunnel-build
