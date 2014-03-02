# Copyright(c) 2003-2007 Robert L. Brown.  This is licensed software
# only to be used with an explicit right-to-use license from the
# copyright holder.
%::RecruiterTable = (
                     table => "recruiter",
                     heading => "Recruiters",
                     order => "name",
                     label => "name",
                     display => \&Recruiter::display,
                     filters => [
                                 {
                                     name => "active",
                                     active => \&Recruiter::isActive,
                                     activeSQL => \&Recruiter::isActiveSQL,
                                 },
                                 ],
                     columns => [
                                 {
                                     column => "id",
                                     heading => "ID",
                                     type => "pk",
                                     hide => 1,
                                 },
                                 {
                                     column => "creation",
                                     heading => "Creation",
                                     type => "datetime",
                                     hide => 1,
                                 },
                                 {
                                     column => "name",
                                     heading => "Name",
                                     width => 32,
                                     type => "text",
                                     labels => \&Recruiter::menuLabels,
				     validators => [
						    [ 'required' ],
						    ],
                                 },
                                 {
                                     column => "agency",
                                     heading => "Agency",
                                     width => 40,
                                     type => "text",
                                 },
                                 {
                                     column => "email",
                                     heading => "E-mail",
                                     type => "email",
 				     validators => [
						    [ "emptyOK" ],
						    [ "email" ],
						    ],
                                     },
                                 {
                                     column => "address1",
                                     heading => "Address Line 1",
                                     width => 40,
                                     type => "text",
                                 },
                                 {
                                     column => "address2",
                                     heading => "Address Line 2",
                                     width => 40,
                                     type => "text",
                                 },
                                 {
                                     column => "city",
                                     heading => "City",
                                     type => "text",
                                 },
                                 {
                                     column => "state",
                                     heading => "State",
                                     type => "text",
                                     width => 12,
                                 },
                                 {
                                     column => "zipcode",
                                     heading => "Zip Code",
                                     type => "text",
                                     width => 14,
                                 },
                                 {
                                     column => "phone",
                                     heading => "Phone",
                                     type => "phone",
                                 },
                                 {
                                     column => "cell",
                                     heading => "Cell Phone",
                                     type => "phone",
                                 },
                                 {
                                     column => "fax",
                                     heading => "Fax",
                                     type => "phone",
                                 },
                                 {
                                     column => "active",
                                     heading => "Is Active?",
                                     type => "enum",
                                 },
                                 {
                                     column => "contract",
                                     heading => "Contract",
                                     type => "fk",
                                     hide => 1,   # XXX temporary
                                     values => {
                                         table => \%::DocumentTable,
                                         pk => "id",
                                         label => "???",
                                     },
                                 },
                                 {
                                     column => "notes",
                                     heading => "Notes",
                                     type => "bigtext",
                                 },
                                 ],
                     );


1;
