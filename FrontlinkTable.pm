# Copyright(c) 2003-2007 Robert L. Brown.  This is licensed software
# only to be used with an explicit right-to-use license from the
# copyright holder.
%::FrontlinkTable = (
		      table => "frontlink",
		      heading => "Related Links",
		      columns => [
				  {
				      column => "id",
				      heading => "Id",
				      type => "pk",
				  },
				  {
				      column => "description",
				      heading => "Description",
				      width => "80",
				      type => "text",
				  },
				  {
				      column => "url",
				      width => "80",
				      heading => "URL",
				      type => "text",
				  },
				  {
				      column => "side",
				      heading => "Table Side",
				      type => "enum",
				  },
				  ],
		      );

1;
