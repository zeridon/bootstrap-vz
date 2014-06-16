Bootstrap-vz plugin rightscale
==============================

This is the initial version of a bootstrap-vz plugin for integrating rightscale
into your image.

What does this plugin do
========================
This plugin will add the necessary packages to create a RightScale compatible
image.

In details
==========
 * Adds necessary RightScale repositories (and keys)
 * Installs base dependencies
 * Installs latest rightlink for the cloud you are provisioning.

``
	"plugins": {
		"rightscale": {
			"enable": true
		}
	}
``

Supported options
=================
The only currently supported option is: ``enable``. Possible values are:
 * ``true`` - enable Rightscale integration
 * ``false`` - disable Rightscale integration

Supported distributions
=======================
 * precise (12.04)
 * raring (13.10)
 * the debs in fact support almost any Debian/Ubuntu but testing is required

Known Issues
============
This has been tested only with EC2 provider. Some trickery will be required for
others.

TODO
====
 * Make it possible to select speciffic version
 * Do some more tests
