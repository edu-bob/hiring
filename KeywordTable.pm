# Copyright(c) 2003-2007 Robert L. Brown.  This is licensed software
# only to be used with an explicit right-to-use license from the
# copyright holder.
%::KeywordTable = (
		    table => "keyword",
		    heading => "Keyword",
		    columns => [
				{
				    column => "id",
				    heading => "Id",
				    type => "pk",
				},
				{
				    column => "keyword",
				    heading => "Keyword",
				    type => "text",
				    width => "32",
				},
				{
				    column => "description",
				    heading => "Description",
				    type => "text",
				    width => "100",
				},
				]
		    );
1;
