#!/usr/bin/perl -w

use strict;

use Module::Build;

Module::Build->new(
	module_name => 'Tie::RefHash::Weak',
	license => 'perl',
	requires => {
		'perl'	=> '>= 5.6', # no weak refs before this
		'Scalar::Util' => 0,
		'Tie::RefHash' => '1.34', # use refaddr instead of overload::StrVal
	},
	build_requires => {
		'Test::More' => 0,
	},
	create_makefile_pl => 'traditional',
	sign => 1,
)->create_build_script;
