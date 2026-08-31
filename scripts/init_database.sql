
##create database and schemas##
--------------------------------------------

use master;

--Drop and recreate the 'Datawarehoue' database 
if exits (select 1 from sys.databases where name = 'Datawarehouse')
begin
    Alter DATABASE Datawarehouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE Datawarehouse;
End;

--create the database datawarehouse;

create database datawarehouse;

use datawarehouse;

create schema bronze;

CREATE SCHEMA sliver;

CREATE SCHEMA gold;
