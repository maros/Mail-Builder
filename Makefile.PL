# Load the Module::Install bundled in ./inc/
use strict;
use inc::Module::Install;

my $from = 'lib/Mail/Builder.pm';

# Define metadata
name            'Mail-Builder';
all_from        $from;
readme_from     $from;
readme_markdown_from $from;


perl_version    '5.008';

# Specific dependencies
requires        'MIME::Tools'           => '5.4';
requires        'Email::Valid'          => 0;
requires        'Class::Accessor'       => 0;
requires        'HTML::TreeBuilder'     => '3.00';
requires        'MIME::Types'           => 0;
requires        'Email::MessageID'      => 0;
requires        'Encode'                => 0;
requires        'Text::Table'           => 0;
requires        'IO::Lines'             => 0;
requires        'version'               => 0;
requires        'parent'                => 0;

build_requires  'Test::Pod'             => 0;
build_requires  'Test::Pod::Coverage'   => 0;

repository 'git://github.com/maros/Mail-Builder.git';

WriteAll;