---
layout: post
title: "Explore the SIP World"
date:   2013-09-03 16:05:30
---

The world is dangerous, GFW and PRISM are just some exposed daemons, the more evil ones are hidden under the skin of kindness, so I have always been trying my best to use safer software and services.

As one of the most important aspects in privacy and security, communication has been monopolized by several big bros. In this post, I will share some exploring in the SIP related software.


Find a SIP server
-----------------

I've dug the Internet for the best open source SIP server software, but failed to make a decision for quite a long time, so many candidates: OpenSIPS, Kamailio, reSIProcate, Asterisk, GNU SIP Switch, OverSIP, etc.

I choose a product based on several common thoughts: more active development, larger users quantity and community, better documentation, easier configuration, and of course, I consider robust and scalable, which shouldn't be considered pointed by many people who just don't obey it.

1. All these SIP servers share the same features, compliant with RFC. 
2. OpenSIPS and Kamailio are identical in many aspects due to the fact that they are both forked from OpenSER.
3. Asterisk and OpenSIPS/Kamailio are the most famous SIP solutions, with lots of documents and large community. But Asterisk is not a pure SIP solution, it's intended for mature VoIP service.
4. OverSIP, reSIProcate solutions and GNU SIP Switch are good projects from their documents, but with so small community.

So finally, OpenSIPS became my choice, why I don't choose Kamailio is because Arch Linux has community package for OpenSIPS.


Setup OpenSIPS
--------------

It's not an easy task to make a SIP server work, due to my lack of SIP knowledge. At first, install required packages with pacman:

```bash
sudo pacman -S mariadb libmariadbclient opensips
sudo systemctl enable mysqld.service opensips.service
```


### Database

Modify _/etc/opensips/opensipsctlrc_ according to http://www.opensips.org/Documentation/Install-DBDeployment-1-11. Remember `STORE_PLAINTEXT_PW=0`.

Create database with `sudo opensipsdbctl create`. In this step I get the warning blaming charset:

> Your current default mysql characters set cannot be used to create DB. Please choice another one from the following list

I don't know why UTF-8 denied by OpenSIPS, just choose _latin1_, which works well for several days testing. If choose utf32 or utf16, should get an error:

> Specified key was too long; max key length is 1000 bytes

Then answer _yes_ for two consecutive questions.


### Configuration

After the database created, modify _/etc/opensips/opensips.cfg_, change the listen line to the desired domain or IP, i.e. `listen=udp:vec.io:5060`.

Then restart OpenSIPS, you can log in to it from any SIP clients with any account/password, cause no authentication configured.

To force authentication, add lines to _/etc/opensips/opensips.cfg_:

```
loadmodule "db_mysql.so"

modparam("usrloc", "db_mode", 2)
modparam("usrloc", "db_url", "mysql://opensips:opensipsrw@localhost/opensips")

loadmodule "auth.so"
loadmodule "auth_db.so"
modparam("auth_db", "calculate_ha1", no)
modparam("auth_db", "password_column", "ha1")
modparam("auth_db", "db_url", "mysql://opensips:opensipsrw@localhost/opensips")

	if (is_method("REGISTER"))
	{
		if (!www_authorize("vec.io", "subscriber")) {
			www_challenge("vec.io", "0");
			exit;
		}
```

A user can be registered with `opensipsctl add cedric@vec.io mypwd`, now only registered users can be used in SIP clients.


Choose a SIP client
-------------------

Compared to servers, it's quite easier to find a proper SIP client. From the [Wikipedia list](http://en.wikipedia.org/wiki/List_of_SIP_software), I decided to use the cross platform linphone and ekiga with pretty UI. The linphone also has a brilliant CLI interface:

```bash
linphonecsh init -C -a -l lin.log -d 6
linphonecsh register --host vec.io --username cedric --password mypwd
```


Read SIP documentation
----------------------

After shocked by the magic of SIP, I decided to master the theory behind it, there are so many related specifications, you may find some useful materials and books recommendations from http://www.siptutorial.net/.
