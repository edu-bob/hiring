# Copyright(c) 2003-2007 Robert L. Brown.  This is licensed software
# only to be used with an explicit right-to-use license from the
# copyright holder.
use ActionTable;
use UserTable;
use OpeningTable;
use CcTable;
use RecruiterTable;

%::CandidateTable = (
		     table => "candidate",
		     heading => "Candidate",
		     columns => [
				 {
				     column => "id",
				     heading => "Id",
				     type => "pk",
				     hide => 1,
				 },
				 {
				     column => "creation",
				     heading => "Creation",
				     type => "datetime",
				     secure => 'admin',
				 },
				 {
				     column => "name",
				     heading => "Name",
				     type => "text",
				     width => 32,
				     validators => [
						    [ 'required' ],
						    ],
                                     },
				 {
				     column => "status",
				     heading => "Status",
				     type => "enum",
				     default => ['NEW', 'ACTIVE'],
				 },
				 {
				     column => "referrer_type",
				     heading => "Referrer Type",
				     type => "enum",
                                     switch => 1,
                                     group => "referrer",
				 },
				 {
				     column => "referrer",
				     heading => "Referrer",
				     type => "text",
                                     group => "referrer",
                                     help => "The name of the person who referred this candidate to us.",
				 },
				 {
				     column => "recruiter_id",
				     heading => "Recruiter",
				     type => "fk",
				     nullable => 1,
				     editable => 1,
				     values => {
					 table => \%::RecruiterTable,
					 pk => "id",
					 label => "name",
				     },
				     group => "referrer",
                                 },
				 {
				     column => "recruiter_ref",
				     heading => "Recruiter reference #",
                                     type => "text",
                                     width => 16,
                                     group => "referrer",
                                     help => "The recruiter's reference number for this candidate, if any.",
                                 },
				 {
				     column => "external",
				     heading => "Source Link",
				     type => "url",
				     width => 32,
				     help => "A full URL to an external system from which this candidate came."
				     },
				 {
				     column => "resumeurl",
				     heading => "Online resume URL",
				     type => "url",
				     width => 32,
				     help => "A full URL to an external page containing the resume."
				     },
				 {
				     column => "portfolio",
				     heading => "Portfolio Link",
				     type => "url",
				     width => 32,
				     help => "A full URL to an external system having the art or code portfolio."
				     },
				 {
				     column => "homephone",
				     heading => "Home Phone",
				     type => "phone",
				 },
				 {
				     column => "workphone",
				     heading => "Work Phone",
				     type => "phone",
				 },
				 {
				     column => "cellphone",
				     heading => "Cell Phone",
				     type => "phone",
				 },
				 {
				     column => "homeemail",
				     heading => "Home E-mail",
				     type => "email",
				     validators => [
						    [ "emptyOK" ],
						    [ "email" ],
						    ],
				     help => "Personal e-mail address.  Multiples can be entered if separated by comma or semicolon.",
                                     },
				 {
				     column => "workemail",
				     heading => "Work E-mail",
				     type => "email",
				     validators => [
						    [ "emptyOK" ],
						    [ "email" ],
						    ],
                                     },
			 {
			     column => 'salary',
			     heading => 'Salary Requirements',
			     type => 'text',
			     secure => 'seesalary',
			     help => "Salary expectations",
			 },
				 {
				     column => "hide",
				     heading => "Hide",
				     type => "text",
				     secure => 'admin',
                                     help => "Set to 1 if this candidate should be hidden (except to admins).",
				 },
				 {
				     column => "modtime",
				     heading => "Last Modification",
				     type => "datetime",
				     hide => 1,
				 },
				 {
				     column => "opening_id",
				     heading => "Opening",
				     type => "fk",
				     nullable => 1,
				     changeHook => \&Candidate::changeOpening,
				     values => {
					 table => \%::OpeningTable,
					 pk => "id",
					 label => "description",
				     },
				     validators => [
                                                    [ "index non-zero" ],
                                                    ],
                                     },
				 {
				     column => "action_id",
				     heading => "Next Action",
				     nullable => 1,
				     type => "fk",
				     values => {
					 table => \%::ActionTable,
					 pk => "id",
					 label => "action",
				     },
				 },
				 {
				     column => "owner_id",
				     heading => "Owner",
				     nullable => 1,
				     type => "fk",
				     values => {
					 table => \%::UserTable,
					 pk => "id",
					 label => "name",
				     },
				 },
				 ],
		     rels => [
			      {
				  type => "N-N",
				  heading => "CC",
				  table => \%::CcTable,
				  column => ["candidate_id","user_id"],
				  hashkey => "cc",
				  help => "Select users to be CC'd on changes", 
                                  widget => "Left/Right",
			      }
			      ],
                     groups => {
                         referrer => {
                             switch => "referrer_type",
                             cases => [
                                       {
                                           value => [
                                                     'INTERNAL',
                                                     'WEBSITE',
                                                     'ADVERTISEMENT',
                                                     'BOARDS',
                                                     'OTHER',
                                                     ],
                                               column => "referrer"
                                           },
                                       {
                                           value => [
                                                     'RECRUITER',
                                                     ],
                                               column => "recruiter_id"
                                           },
                                      {
                                           value => [
                                                     'RECRUITER',
                                                     ],
                                               column => "recruiter_ref"
                                           },
                                       ],
                                           },
                                           },
		     );
1;
