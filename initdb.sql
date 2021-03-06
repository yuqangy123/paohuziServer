drop database rrphDB;
create database rrphDB;

use rrphDB;

create table players(
pid int(32) not null auto_increment primary key,
openid varchar(32),
name varchar(32),
roomids varchar(1024)
) charset=utf8;

create table roomRecord(
roomid int(32) not null auto_increment primary key,
js char(1),
zz char(1),
times varchar(32),
p1name varchar(32),
p1score int(32),
p2name varchar(32),
p2score int(32),
p3name varchar(32),
p3score int(32),
p4name varchar(32),
p4score int(32)
) charset=utf8;



create table iddb(
roomid int(32),
pid int(32)
);

insert into iddb values(0,0);

alter database rrphDB  character set utf8;