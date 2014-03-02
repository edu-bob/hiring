# Copyright(c) 2003-2007 Robert L. Brown.  This is licensed software
# only to be used with an explicit right-to-use license from the
# copyright holder.

use ActionCategoryTable;

%::ActionTable = (
                  table => "action",
                  heading => "Next Action",
                  order => "precedence",
                  columns => [
                              {
                                  column => "id",
                                  heading => "Id",
                                  type => "pk",
                              },
                              {
                                  column => "action",
                                  heading => "Action",
                                  type => "text",
                                  help => "A short description of the next action to take for a candidate."
                                  },
                              {
                                  column => "precedence",
                                  heading => "Precedence",
                                  type => "text",
                                  help => "The order position of this action.  A candidate's sequence of next actions follows the numeric oder of this value among all of the actions.",
                              },
                              {
                                  column => "category_id",
                                  heading => "Action Category",
                                  type => "fk",
                                  nullable => 1,
                                  values => {
                                      table => \%::ActionCategoryTable,
                                      pk => "id",
                                      label => "name",
                                  },
                              },
                              
                              ]
                  );
1;
