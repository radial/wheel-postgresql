# Spoke Dockerfile for PostgreSQL

FROM            radial/spoke-base:latest
MAINTAINER      Brian Clements <radial@brianclements.net>

# Install packages
ENV             DEBIAN_FRONTEND noninteractive
RUN             apt-get -q update && apt-get -qyV install \
                    postgresql postgresql-client postgresql-contrib &&\
                apt-get clean
RUN             env --unset=DEBIAN_FRONTEND

# Process startup info
ENV             SPOKE_NAME postgresql

COPY            /entrypoint.sh /entrypoint.sh

EXPOSE          5432
