# PostgreSQL: Open Source SQL Database

This is a Radial Wheel repository for a [PostgreSQL][postgres] database.

When run, the database folder and permissions are created/set and then the
database is initialized. Make note of the `/config/postgresql/setupdb` file.
This file contains a single string that gets sent into `postgres --single` at
setup for additional database commands such as assigning users, ownerships, and
any other initial database setup you might want to do.

[postgres]: http://www.postgresql.org/

## Tunables

It has sane defaults so you can test it all out. Separate from the postgresql
configuration located in the `/config/postgresql` directory, the initial
database setup can be done by running with the following environment variables
set:

  - **$DB_USER**: Database admin user
  - **$DB_PASS**: Password. Don't set this and a random string will be used
  - **$DB_NAME**: Database name
  - **$DB_DIR**: Database folder location. Should be somewhere in the `/data`
    folder to make sure it is shared properly.
  - **$SETUP_DB_COMMANDS**: SQL commands, separated by ";" and a new line, all
    wrapped in double quotes to make it a single string. These are for
    additional user/permissions setup to the database after it is initialized. 

## Radial

[Radial][radial] is a [Docker][docker] container topology strategy that
seeks to put the canon of Docker best-practices into simple, re-usable, and
scalable images, dockerfiles, and repositories. Radial categorizes containers
into 3 types: Axles, Hubs, and Spokes. A Wheel is a repository used to recreate
an application stack consisting of any combination of all three types of
containers. Check out the [Radial documentation][radialdocs] for more.

One of the main design goals of Radial containers is simple and painless
modularity. All Spoke (application/binary) containers are designed to be run by
themselves as a service (a Wheel consisting of a Hub container for configuration
and a Spoke container for the running binary) or as part of a larger stack as a
Wheel of many Spokes all joined by the Hub container (database, application
code, web server, backend services etc.). Check out the [Wheel
tutorial][wheel-template] for some more details on how this works.

Note also that for now, Radial makes use of [Fig][fig] for all orchestration,
demonstration, and testing. Radial is just a collection of images and
strategies, so technically, any orchestration tool can work. But Fig was the
leanest and most logical to use for now. 

[wheel-template]: https://github.com/radial/template-wheel
[fig]: http://www.fig.sh
[docker]: http://docker.io/
[radial]: https://github.com/radial
[radialdocs]: http://radial.viewdocs.io/docs

## How to Use
### Static Build

In case you need to modify the entrypoint script, the Dockerfile itself, create
your "config" branch for dynamic building, or just prefer to build your own from
scratch, then you can do the following:

1. Clone this repository
2. Make whatever changes needed to configuration and add whatever files
3. `fig up`

### Dynamic Build

A standard feature of all Radial images is their ability to be used dynamically.
This means that since great care is made to separate the application code from
it's configuration, as long as you make your application configuration available
as a git repository, and in it's own "config" branch as per the guidelines in
the [Wheel template][wheel-template], no building of any images will be
necessary at deploy time. This has many benefits as it allows rapid deployment
and configuration without any wait time in the building process. However:

**Dynamic builds will not commit your configuration files into any
resulting images like static builds.**

Static builds do a "COPY" of files into the image before exposing the
directories as volumes. Dynamic builds do a `git fetch` at run time and the
resulting data is downloaded to an already existing volume location, which is
now free from Docker versioning. Both methods have their advantages and
disadvantages. Deploying the same exact configuration might benefit from a
single image built statically whereas deploying many different disposable 
configurations rapidly are best done dynamically with no building.

To run dynamically:

1. Modify the `fig-dynamic.yml` file to point at your own Wheel repository
   location by setting the `$WHEEL_REPO` variable. When run, the Hub container
   will pull the "config" branch of that repository and use it to run the Spoke
   container with your own configuration.
3. `fig -f fig-dynamic.yml up`
