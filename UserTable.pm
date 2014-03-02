# Copyright(c) 2003-2007 Robert L. Brown.  This is licensed software
# only to be used with an explicit right-to-use license from the
# copyright holder.
use User;

%::UserTable = (
		table => "user",
		heading => "User",
		order => "name",
		filters => [
                            {
                                name => "active",
                                active => \&User::isActive,
                                activeSQL => \&User::isActiveSQL,
                            },
                            ],
		columns => [
			    {
				column => "id",
				heading => "ID",
				type => "pk",
			    },
			    {
				column => "name",
				heading => "User",
				type => "text",
				help => "Your full name.",
				validators => [
					       [ 'required' ],
                                               [ 'not equal', [ '"anonymous"' ] ],
					       ],
			    },
			    {
				column => "title",
				heading => "Job Title",
				type => "text",
				help => "Your corporate job title.",
			    },
			    {
				column => "email",
				heading => "E-mail",
				type => "email",
				help=>"Your e-mail address for reminders.",
				validators => [
					       [ 'required' ],
					       [ 'email' ],
					       ],
			    },
			    {
				column => "admin",
				heading => "Is Admin?",
				type => "enum",
				secure => 'admin',
			    },
			    {
				column => "active",
				heading => "Is Active?",
				type => "enum",
			    },
			    {
				column => "password",
				heading => "Password",
				type => "password",
				private => 1,
			    },
			    {
				column => "sendmail",
				heading => "Send e-mail?",
				type => "enum",
				help => "Y or N: send e-mail change notices?",
			    },
			    {
				column => "remind",
				heading => "Send reminders?",
				type => "enum",
				help => "Y or N: send periodic e-mail reminders?",
			    },
			    {
				column => "seesalary",
				heading => "Can see salary data",
				secure => 'admin',
				type => "enum",
				help => "Y or N: can this person see candidate salary info?",
			    },
			    ]
		);
1;
