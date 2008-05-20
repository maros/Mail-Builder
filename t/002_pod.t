# -*- perl -*-

# t/002_pod.t - check pod

use Test::Pod tests => 7;

pod_file_ok( "lib/Mail/Builder.pm", "Valid POD file" );
pod_file_ok( "lib/Mail/Builder/Address.pm", "Valid POD file" );
pod_file_ok( "lib/Mail/Builder/Image.pm", "Valid POD file" );
pod_file_ok( "lib/Mail/Builder/Attachment.pm", "Valid POD file" );
pod_file_ok( "lib/Mail/Builder/Attachment/File.pm", "Valid POD file" );
pod_file_ok( "lib/Mail/Builder/Attachment/Data.pm", "Valid POD file" );
pod_file_ok( "lib/Mail/Builder/List.pm", "Valid POD file" );