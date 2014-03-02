# Copyright(c) 2003-2007 Robert L. Brown.  This is licensed software
# only to be used with an explicit right-to-use license from the
# copyright holder.
%::ParamTable = (
                 table => "param",
                 heading => "Parameters",
                 columns => [
                             {
                                 column => "id",
                                 heading => "ID",
                                 type => "pk",
                             },
                             {
                                 column => "name",
                                 heading => "Name",
                                 type => "text",
                             },
                             {
                                 column => "value",
                                 heading => "Value",
                                 type => "text",
                                 width => "32",
                             },
                             ]
                 );
1;
