# Copyright(c) 2003-2007 Robert L. Brown.  This is licensed software
# only to be used with an explicit right-to-use license from the
# copyright holder.
%::TempDirTable = (
				   table => "temp_dir",
				   heading => "Temporary Directories",
				   columns => [
							   {
								   column => "id",
								   heading => "ID",
								   type => "pk",
							   },
							   {
								   column => "creation",
								   heading => "Creation",
								   type => "datetime",
							   },
							   {
								   column => "name",
								   heading => "Name",
								   type => "text",
							   },
							   ],
				   );
1;
