# About this Docker Image

This Docker image contains the Oracle Instant Client 'Basic', 'SDK' and 'SQL*Plus' packages.  It can be extended to run OCI, OCCI, and JDBC applications.  It can also be extended to build and run scripting language drivers that use OCI such as Python's cx_Oracle, Node.js's node-oracledb, PHP's OCI8, and Ruby's ruby-oci8.  

The SQL*Plus command-line query tool is also included, allowing quick ad-hoc SQL and PL/SQL execution.

## About Oracle Instant Client

[Oracle Instant Client](http://www.oracle.com/technetwork/database/features/instant-client/) is a repackaging of Oracle Database libraries, tools and header files usable to create and run applications that connect to a remote (or local) Oracle Database.

## Required files

Download the Oracle Instant Client 12.2 RPMs from OTN:

http://www.oracle.com/technetwork/topics/linuxx86-64soft-092277.html

The following three RPMs are required:

- `oracle-instantclient12.2-basic-12.2.0.1.0-1.x86_64.rpm`
- `oracle-instantclient12.2-devel-12.2.0.1.0-1.x86_64.rpm`
- `oracle-instantclient12.2-sqlplus-12.2.0.1.0-1.x86_64.rpm`

## Building

Place the downloaded Oracle Instant Client RPMs (from the previous step) in the
same directory as the `Dockerfile` and run:

```
docker build -t oracle/instantclient:12.2.0.1 .
```

## Usage

You can run a container interactively to execute ad-hoc SQL and PL/SQL statements in SQL*Plus:

```
docker run -ti --rm oracle/instantclient:12.2.0.1 sqlplus hr/welcome@example.com/pdborcl
```

## Adding Oracle Database Drivers

To extend the image with optional Oracle Database drivers, follow your desired driver installation steps.  The Instant Client libraries are in `/usr/lib/oracle/12.2/client64/lib` and the Instant Client headers are in `/usr/include/oracle/12.2/client64/`.

The Instant Client libraries are in the default library search path.
