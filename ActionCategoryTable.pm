# Copyright(c) 2003-2007 Robert L. Brown.  This is licensed software
# only to be used with an explicit right-to-use license from the
# copyright holder.

%::ActionCategoryTable = (
                          table => "action_category",
                          heading => "Action Category",
                          order => "precedence",
                          columns => [
                                      {
                                          column => "id",
                                          heading => "Id",
                                          type => "pk",
                                      },
                                      {
                                          column => "creation",
                                          heading => "Creation",
                                          type => "datetime",
                                      },
                                      {
                                          column => "name",
                                          heading => "Category Name",
                                          type => "text",
                                      },
                                      {
                                          column => "precedence",
                                          heading => "Sort Order",
                                          type => "text",
                                      },
                                      ]
                          );

1;
