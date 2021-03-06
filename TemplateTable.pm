# Copyright(c) 2003-2007 Robert L. Brown.  This is licensed software
# only to be used with an explicit right-to-use license from the
# copyright holder.
%::TemplateTable = (
                 table => "template",
                 heading => "Template Files",
                 columns => [
                             {
                                 column => "id",
                                 heading => "ID",
                                 type => "pk",
                             },
                             {
                                 column => "name",
                                 heading => "Template Name",
                                 type => "text",
                             },
                             {
                                 column => "table_name",
                                 heading => "Table That This Template Applies To",
                                 type => "text",
                             },
                             {
                                 column => "column_name",
                                 heading => "Column That This Template Applies To",
                                 type => "text",
                             },
			     {
				 column => "template",
				 heading => "Template",
				 type => "bigtext",
				 rows=>"20",
			     },
                             ]
                 );
1;
