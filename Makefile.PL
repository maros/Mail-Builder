# Load the Module::Install bundled in ./inc/
use strict;
use inc::Module::Install;

# Define metadata
name            'Mail-Builder';
all_from        'lib/Mail/Builder.pm';

perl_version    '5.000';

# Specific dependencies
requires        'MIME::Tools'           => '5.4';
requires        'Email::Valid'          => 0;
requires        'Class::Accessor'       => 0;
requires        'HTML::TreeBuilder'     => '3.00';
requires        'MIME::Types'           => 0;
requires        'Email::MessageID'      => 0;
requires        'Encode'                => 0;
requires        'Text::Table'           => 0;
build_requires  'Test::Pod'             => 0;
build_requires  'Test::Pod::Coverage'   => 0;

WriteAll;