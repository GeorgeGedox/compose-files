FROM ubuntu:focal

# Update our main system
RUN apt-get update

# Get some dependencies for adding apt repositories
RUN apt-get install -y wget gnupg

# Add perforce repo
RUN wget -qO - https://package.perforce.com/perforce.pubkey | apt-key add -
RUN echo 'deb http://package.perforce.com/apt/ubuntu focal release' > /etc/apt/sources.list.d/perforce.list
RUN apt-get update

# Install it
RUN apt-get install -y helix-p4d helix-cli \
    && rm -rf /var/cache/apt

EXPOSE 1666
VOLUME ["/data"]

ADD ./setup.sh /usr/local/bin/
ADD ./run.sh  /

# Start
CMD ["/run.sh"]
