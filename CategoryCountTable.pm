# Copyright(c) 2003-2007 Robert L. Brown.  This is licensed software
# only to be used with an explicit right-to-use license from the
# copyright holder.
use ActionCategoryTable;

%::CategoryCountTable = (
						 table => "category_count",
						 heading => "Category Counts",
						 columns => [
									 {
										 column => "thetime",
										 heading => "Time",
										 type => "datetime",
									 },
									 {
										 column => "count",
										 heading => "Count",
										 type => "text",
									 },
									 {
										 column => "category_id",
										 heading => "Category",
										 type => "fk",
										 nullable => 0,
										 values => {
											 table => \%::ActionCategoryTable,
											 pk => "id",
											 label => "name",
										 },
									 },
									 ]
						 );

1;
