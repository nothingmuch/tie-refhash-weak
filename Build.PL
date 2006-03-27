#!/usr/bin/perl -w

use strict;

use Module::Build;

Module::Build->new(
	module_name => 'Tie::RefHash::Weak',
	license => 'perl',
	requires => {
		'perl'	=> '>= 5.6', # no weak refs before this
		'Scalar::Util' => 0,
	},
	build_requires => {
		'Test::More' => 0,
	},
	create_makefile_pl => 'traditional',
	sign => 1,
)->create_build_script;
