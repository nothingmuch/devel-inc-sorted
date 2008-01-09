#!/usr/bin/perl -w

use strict;

use ExtUtils::MakeMaker;

WriteMakefile(
	NAME         => 'Devel::INC::Sorted',
	VERSION_FROM => 'lib/Devel/INC/Sorted.pm',
	INSTALLDIRS  => 'site',
	SIGN         => 1,
	PL_FILES     => { },
	PREREQ_PM    => {
		'Tie::Array'   => 0,
		'Tie::RefHash' => 0,
	},
);

