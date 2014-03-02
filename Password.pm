# -*- Mode: perl; indent-tabs-mode: nil -*-
# Copyright(c) 2003-2007 Robert L. Brown.  This is licensed software
# only to be used with an explicit right-to-use license from the
# copyright holder.


package Password;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);

require Exporter;
$VERSION = 1.00;
@ISA = qw(Exporter);

@EXPORT = qw( );

@EXPORT_OK = qw();              # Symbols to export on request

sub encrypt {
    my ($password) = (@_);
    my @saltchars = (0..9, 'A'..'Z', 'a'..'z', '.', '/');
    my $salt = "";
    for ( my $i=0 ; $i < 8 ; ++$i ) {
        $salt .= $saltchars[rand(64)];
    }
    return crypt($password, $salt);
}

sub match
{
    my ($clearpassword, $cryptedpassword) = (@_);
    return crypt($clearpassword, $cryptedpassword) eq $cryptedpassword;
}

1;
