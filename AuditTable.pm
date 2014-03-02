# -*- Mode: perl; indent-tabs-mode: nil -*-
# Copyright(c) 2003-2007 Robert L. Brown.  This is licensed software
# only to be used with an explicit right-to-use license from the
# copyright holder.


use strict;

use UserTable;

%::AuditTable = (
                 table => "audit",
                 heading => "Audit Trail",
                 order => "creation",
                 columns => [
                             
                             {
                                 column => "id",
                                 heading => "Id",
                                 type => "pk",
                             },
                             {
                                 column => "user_id",
                                 heading => "User",
                                 type => "fk",
                                 values => {
                                     table => \%::UserTable,
                                     pk => "id",
                                     label => "name",
                                 },
                             },
                             {
                                 column => "creation",
                                 heading => "Creation",
                                 type => "datetime",
                             },
                     {
                         column => "secure",
                         heading => "Visibilty",
                         type => "text",
                     },
                             {
                                 column => "type",
                                 heading => "Type",
                                 type => "enum",
                             },
                             {
                                 column => "dbtable",
                                 heading => "DB Table",
                                 type => "text",
                             },
                             {
                                 column => "row",
                                 heading => "Row ID",
                                 type => "text",
                             },
                             {
                                 column => "dbcolumn",
                                 heading => "DB Column",
                                 type => "text",
                             },
                             {
                                 column => "oldvalue",
                                 heading => "Old Value",
                                 type => "text",
                             },
                             {
                                 column => "newvalue",
                                 heading => "New Value",
                                 type => "text",
                             },
                             {
                                 column => "join_table",
                                 heading => "Table to joind values with",
                                 type => "text",
								 nullable => 1,
                             },
                             {
                                 column => "join_id",
                                 heading => "PK in join_table",
                                 type => "text",
								 nullable => 1,
                             },
                             ],
                 );
1;
