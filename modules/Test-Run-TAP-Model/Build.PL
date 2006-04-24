#!/usr/bin/perl -w

use strict;

use Module::Build;

Module::Build->new(
	module_name => 'Test::Run::TAP::Model',
	license => 'perl',
	requires => {
		'perl'				=> '5.8',
	},
	build_requires => {
		'Test::More' => "0.53",
		'Method::Alias' => "0",
        'Test::Run::Obj' => 0,
	},
	create_makefile_pl => 'traditional',
)->create_build_script;

