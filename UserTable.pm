# Copyright(c) 2003-2007 Robert L. Brown.  This is licensed software
# only to be used with an explicit right-to-use license from the
# copyright holder.
use User;
use OpeningTable;

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
	    heading => "Send E-mail?",
	    type => "enum",
	    help => "Y or N: send e-mail change notices?",
	},
	{
	    column => "remind",
	    heading => "Send Reminders?",
	    type => "enum",
	    help => "Y or N: send periodic e-mail reminders?",
	},
	{
	    column => "seesalary",
	    heading => "Can See Salary Data",
	    secure => 'admin',
	    type => "enum",
	    help => "Y or N: can this person see candidate salary info?",
	},
	{
	    column => 'changestatus',
	    heading => 'Can Change Status?',
	    secure => 'admin',
	    type => 'enum',
	    help => 'Y or N: User can change a candidate\'s status',
	},
	{
	    column => 'validated',
	    heading => 'Account Validated?',
	    secure => 'admin',
	    type => 'enum',
	    help => 'Y or N: This user account has been validated',
	},
	{
	    column => 'passwordkey',
	    heading => 'Change Password Token',
	    secure => 'admin',
	    type => 'text',
	    help => 'MD5 key for enabling the change of the user password',
	},
	{
	    column => "my_opening_id",
	    heading => "Principal Opening",
	    type => "fk",
	    alias => "user_opening",
	    values => {
		table => \%::OpeningTable,
		pk => "id",
		label => "description",
	    },
	}
    ]
    );
1;
