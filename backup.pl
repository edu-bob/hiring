#!/usr/bin/perl

use CGI::Carp qw(fatalsToBrowser);

#    Last change: PFB 2002-03-01 17:38:53
# mysql_backup.cgi
###################################################################################
# POD Documentation

=head1 PROGRAM NAME AND AUTHOR

        MySQL Backup v2.5
        by Peter F. Brown
        peterbrown@worldcommunity.com
        Build Date: March 1, 2002

=PURPOSE

        Backs up mysql data safely, using
        'mysqldump', 'select to outfile' or 'normal record selection'.
        Version 2 is a complete rewrite of Version 1,
        which was done as a bash shell script.

        This is my attempt :-) to provide a reasonably
        full featured MySQL backup script that can be
        run from cron or from the shell prompt.

        It provides options to backup all of the databases and tables
        in one particular host, with exception lists. It also
        works around the sql wildcard glitch with _'s etc, in
        database and table names, by not using mysqlshow for
        table names. Instead I use 'show tables'. I did this, because
        mysqlshow db % didn't work under MySQL v3.22.20a, and I wasn't
        able to determine when the % method came into being (under
        which version.) So, in order to make things work for earlier
        versions, I used 'show tables'.

=COPYRIGHT

        Copyright 2002 Peter F. Brown (The World Community Network)
        This program complies with the GNU GENERAL PUBLIC LICENSE
        and is released as "Open Source Software".
        NO WARRANTY IS OFFERED FOR THE USE OF THIS SOFTWARE

=BUG REPORTS AND SUPPORT

        Send bug reports to peterbrown@worldcommunity.com.
        Visit the author's web site at 'worldcommunity.com'
        to view information about support, customer quotes,
        a resume link, and fees for custom Perl/MySQL programming.

=OBTAINING THE LATEST VERSION

        ==> Get the most recent version of this program at:
            http://worldcommunity.com/opensource

=VERSION HISTORY

TODO: (very soon :-)

- a version that works with WinNT's email system (NET::SMTP)
- a method to email each database to a different person
- a method to use different hosts (from a contributor)
- a function to fpt the backup file to a host (from a contributor)

v2.5 - March 1, 2002     - removed the password from the mysqldump and mysqlshow
                           lines if .cnf files are being used, since using the
                           user/pass on the command line shows up in 'ps'.
                           (Thus, it's highly advisable to use a .cnf file!)

                         - added $show_file_list_in_email var, to trim large emails.
                           The file list will not be included in the email unless
                           the var is set to 'yes'.

                         - Added functionality to backup LARGE systems, i.e:
                         - changed the tar method to tar a subdirectory with all
                           the files, so tar doesn't choke if there are too many
                           files. The subdir is removed once the tar file is made,
                           if $delete_text_files is set to yes. If not, the files
                           in old tar_dirs are cleaned out later by clean_old_files.

                         - modified 'ls -la' to use xargs so that large directories
                           don't choke.

v2.4 - June 20, 2001     - A bug fix of a bug fix. Oy.
                           Changed 'w_user' and 'w_password'
                           in the setup section back to 'user' and 'password'
                           to make it more consistent with .cnf files, and to
                           fix a bug I created when I changed it in v2.2
                           (with mysqldump looking for $user)
                           Now, we use $user and $password everywhere.
                           Thanks to our sharp eyed users!

v2.3 - June 5, 2001      - Changed the ~/ for the home directory in the vars
                           $cnf_file, $ENV{'MYSQL_UNIX_PORT'} and $mysql_backup_dir
                           to use absolute paths instead of the ~/. The ~/ didn't
                           work, and is a fine example of the need for testing :-)
                           I thought I was being clever and convenient, but I
                           actually didn't use it on my system (I used the absolute
                           paths instead.) Thanks to Rick Morbey in London.

v2.2 - May 25, 2001      - Bug fix; a typo. Changed 'user' and 'password'
                           in the setup section to 'w_user' and 'w_password'
                           so that the connect_to_db routine works.
                           Thanks to Glen Knoch.

v2.1 - May 23, 2001      - First public release of new Perl version
                         - bug fixes and added some options
                           . changed 'mysqlshow db %' for tables, to 'show tables'
                           . added prefixes to file deletes for safety
                           . fixed error in regex that checked for text file delete
                           . changed %e to %d in date string for file name
                           . added vars for nice, tar, gzip paths
                           . removed &error_message($error_text) from &mail_to,
                             to avoid recursive loop, since &error_message calls &mail_to
                           . fixed error in attached email file path
                           . commented out $dbh->{'PrintError'} = 1; and
                                           $dbh->{'RaiseError'} = 1; so that the script
                                           wouldn't die before emailing the error.
                           . made all vars in &do_backup 'my' to avoid conflicts

v2.0 - February 15, 2001 - completely rewritten as a Perl script
                           . added all core options

v1.0 - January 2, 2000   - written as a simple shell script

=cut

###################################################################################

use DBI;
use POSIX qw(strftime);
use Time::Local;
use Cwd;

no strict 'refs';

# VARIABLE SET UP SECTION
# ..................................

use MIME::Lite;              # if you don't have the MIME::Lite library
                             # (it's at CPAN), then comment out the
                             # line 'use MIME::Lite', and set the variable,
                             # $email_backup (below) to 'no'.
                             # You'll also have to comment out the section
                             # below marked as 'MIME::Lite BLOCK'
                             # MIME::Lite is used to email the tar.gzip file
                             # as an attachment. If you're not doing this,
                             # then you don't need the library.

$db_host                     = 'localhost';
$db_port                     = '3306';
                             # database connection variables

$cnf_file                    = '/dev/null';
                             # use an absolute path; ~/ may not work

$cnf_group                   = 'client';
                             # you can store your user name and
                             # password in your cnf file
                             # or.. you can place the username and
                             # password in this file,
                             # but you should set this to 700 (rwx------)
                             # so that it's more secure.
                             # we assume here that your user name status
                             # equals the functions needed.
                             # (for example, 'select to outfile'
                             # requires file privileges.)

                             # for the purposes of parsing the .cnf file
                             # to get the user and password for mysqlshow,
                             # the $cnf_group is ignored,
                             # so if you have more than one group, it won't work
                             # However, cnf_group is used by the dbh->connect
                             # method below.

                             # Bottom line? Use .my.cnf with only
                             # ONE user and password entry (which is the default)
                             # or set up a special .cnf file just for this program.
                             # the contents should look like this:

                             # CNF FILE CONTENTS:
                             # user=yourusername
                             # password=yourpassword

$user                        = 'hiring';
$password                    = 'modeln';

$extra_dir                   = undef;

$password_location           = 'this_file';
                             # set to 'cnf' or 'this_file' - the
                             # connection subroutine uses this
                             # to decide which method to use.

# $ENV{'MYSQL_UNIX_PORT'}    = "/home/mydomain/mysql/mysql.sock";
                             # use an absolute path; ~/ may not work
                             # $ENV{'MYSQL_UNIX_PORT'} is used because
                             # we have multiple instances of the MySQL
                             # daemon running on our host
                             # (worldcommunity.com) and each instance
                             # has its own mysql.sock file - Therefore
                             # the script needs to find it.
                             # !!! If you use the normal MySQL
                             # installation, then COMMENT OUT this line

# $mailprog                  = "/var/qmail/bin/qmail-inject -h";
# $mailprog                  = '/usr/lib/sendmail -t -oi';
$mailprog                    = '/usr/sbin/sendmail -t -oi';
                             # sendmail is more common

$admin_email_to              = "rbrown\@visiblepath.com";

$admin_email_from            = "mysql\@online.sv.visiblepath.com";
                             # the email for error messages, etc.

$site_name                   = 'PD Hiring';
$subject                     = "DB Backup Done for $site_name";
                             # subject is the email subject

$date_text                   = strftime("%Y-%m-%d_%H.%M.%S", localtime);
                             # the date_text var becomes part of the backup file name
                             # see notes about 'backup_date_string' at end of file

$increments_to_save          = 30;
$seconds_multiplier          = 86400;
$increment_type              = "Day(s)";

$seconds_to_save             = $increments_to_save * $seconds_multiplier;
                             # increment_type is used for the text output,
                             # and has no impact on the math.

                             # one could set increment type to "Minute(s)"
                             # or "Hour(s)" or "Day(s)" or "Week(s)", etc.
                             # Just set the seconds_to_save number to
                             # the correct number of seconds, i.e:

                             # minute: 60 / hour: 3600 / day: 86400
                             # week: 604800

                             # these variables control how many increments
                             # (e.g. 'days') worth of
                             # backup files to save. Files with
                             # timestamps older than this will be deleted each time
                             # the script is run. Note that the file modification
                             # time is used - NOT the file name.
                             # This may have to be modified on non-Linux boxes.

$delete_text_files           = 'yes';
                             # set delete_text_files to 'yes' if you want to
                             # delete the intermediate data text files,
                             # and only keep the tar.gzip files.
                             # I recommend this, because the text files can be large.

$email_backup                = 'yes';
                             # set email_backup to 'yes' if you want to email the
                             # tar.gzip file to the email_admin
                             # note that it might be large!
                             # However, the backup is useless if your machine
                             # crashes before you copy the data OFF of your machine!!!
                             # Thus, I recommend emailing it.
                             # I go as far as copying my desktop hard drive to a
                             # backup drive, and then storing the backup drive in
                             # a safe deposit box at the bank.
                             # DATA IS REALLY HARD TO REPLACE.

$show_file_list_in_email     = 'yes';
                             # for large directories this should be set to 'no'

# $fpt_backup                # this is on the todo list.

# mysqlshow and mysqldump variables
# ..................................

@selected_databases          = qw[hiring];

$process_all_databases       = 'no';
                             # @selected_databases is ignored if you set
                             # process_all_databases to 'yes'
                             # Many servers with virtual hosts allow you
                             # to see all of the databases while only giving
                             # you access to your own database. In that case,
                             # place the name of your database in the
                             # @selected_databases array.

                             # Someone else might want to process all of the
                             # databases, with possible exceptions. If so,
                             # place the databases to skip in the
                             # skip_databases array below.

@skip_databases              = qw[];
                             # Note: skip_databases is only parsed
                             # if process_all_databases is set to 'yes'
                             # Leave it blank if you don't want to use it., i.e:
                             # qw[];

@skip_tables                 = qw[];
                             # skip_tables is always parsed.
                             # Leave it blank if you don't want to use it., i.e:
                             # qw[];

$tar_options                 = '-ph';
                             # hardcoded options include 'c, f'
                             # p = retain permissions
                             # v = verbose (can be set below)

if ( $show_file_list_in_email eq 'yes' )
      {
      $tar_options .= ' -v';
      }

$mysqlbin                    = '/usr/bin';
$nice_cmd                    = '/bin/nice';
$tar_cmd                     = '/bin/tar';
$gzip_cmd                    = '/bin/gzip';

$mysqlshow                   = "$mysqlbin/mysqlshow";

$mysql_backup_dir            = '/online/BACKUPS';
                             # use an absolute path; ~/ may not work
                             # the backup dir should normally be
                             # OUTSIDE of your web document root
                             # this directory must be writable by the script.

$file_prefix                 = 'bak.mysql';
                             # the file prefix is also used to match files
                             # for the deletion of old files. It's a real
                             # 'PREFIX', it will be placed at the front of
                             # each file name

$mysql_dump_file_ext       = 'txt';
$mysqldump_params          = '--quick --add-drop-table -c -l';
                             # I used '-v' (for verbose on this, and it
                             # crashed. still checking this...)

$backup_type                 = 'mysqldump';
# $backup_type               = 'outfile';
# $backup_type               = 'normal_select';

                             # set $backup_type to one of these 3 types:

                             # 'mysqldump'
                             # 'outfile'
                             # 'normal_select'

                             # (mysqldump is the best choice, followed by outfile)

                             # ! NOTE: for the 'outfile' method,
                             # you must have MySQL file privilege
                             # status, or the file will not be written
                             # (it will be 0 bytes long)

                             # 'normal_select' uses a normal
                             # select/write process; it's clunky,
                             # but some hosts don't provide access to
                             # mysqldump or 'select into outfile'
                             # (sometimes mysqldump is on a different
                             # server, and sometimes a user doesn't have
                             # 'file_privileges' for mysql.)

                             # NOTE: for LARGE data sets, 'normal_select'
                             # may not work well, because of memory problems

$backup_field_terminate    = '|';
$backup_field_enclosed_by  = '';
$backup_line_terminate     = "\n";
                             # params for 'normal_select' file writing
                             # note that the "\n" must be interpolated
                             # via " double quotes or the qq method

$outfile_params            = qq~ fields terminated by '|' lines terminated by '\n' ~;
                             # params for 'select * from $table_name
                             # into $outfile ($outfile is created in
                             # the backup routine)

$chmod_backup_file         = 'yes'; # set to 'yes' if you want to use it
                             # (you DO NOT want to set the backup file to 600
                             # unless you can ftp in as the user that
                             # the script runs as.)

# end of mysqldump variables
# ...........................

# END OF SETUP VARIABLES

###################################################################################
# YOU NORMALLY WON'T HAVE TO MODIFY ANYTHING BELOW THIS LINE
###################################################################################

chdir ("$mysql_backup_dir");

# now make a tar sub directory for this backup

$tar_dir = $file_prefix . "." . $date_text;
mkdir $tar_dir, 0777;
chdir ("$tar_dir");

print qq~Processing Backups in $mysql_backup_dir/$tar_dir\n~;

$body_text  = "Processing Backups in $mysql_backup_dir/$tar_dir\n\n";
$body_text .= "Databases / Tables:\n";

# get username and password for mysqlshow, from .cnf file
#............................................................................

if ( $password_location eq 'cnf' )
        {
        # open file
        unless ( open(CNF_FILE, "$cnf_file" ))
                {
                &error_message(qq~Error!\n
                Can't open File $cnf_file.~);
                }

        # $cnf_group is ignored;
        # so if you have more than one group, it won't work
        # see notes above. We're looking for: $user=$password

        while ( <CNF_FILE> )
                {
                chomp;
                s/#.*//;
                s/^\s+//;
                s/\s+$//;
                next unless length;
                my ($var, $value) = split(/\s*=\s*/, $_, 2);
                $$var = $value;
                }

        close(CNF_FILE);
        }

# test and create the initial database array
# first convert the exception database and table arrays
# to hashes for speed searching
#............................................................................

%skip_databases = ();
%skip_tables    = ();

foreach my $database_name ( @skip_databases )
        {
        $skip_databases{$database_name} = $database_name;
        }

foreach my $table_name ( @skip_tables )
        {
        $skip_tables{$table_name} = $table_name;
        }

# test to see if we should process all databases

if ( $process_all_databases eq 'yes' )
        {
        if ( $password_location eq 'cnf' )
            {
            @databases = `$mysqlshow`;
            }
        else
            {
            @databases = `$mysqlshow --user=$user --password=$password`;
            }

        chomp ( @databases );
        }
else
        {
        @databases = @selected_databases;
        }

# here's where the backup is actually done
#............................................................................

foreach $db_main ( @databases )
        {
        if ( $db_main =~ /Databases/ )   {next;}
        if ( $db_main !~ /\w+/ )         {next;}
        $db_main =~ s/\|//g;
        $db_main =~ s/\s+//g;

        if ( $process_all_databases eq 'yes' and exists $skip_databases{$db_main} )
                {
                print "\nSkipping: [$db_main\]\n";
                $body_text .= "\nSkipping: [$db_main\]\n";
                next;
                }

        # connect to db
        &connect_to_db($db_main);

        print "\nDatabase: [$db_main\]\n";
        $body_text .= "\nDatabase: [$db_main\]\n";

        # now grab table names for this databases
        # we use 'show tables' to avoid problems with mysqlshow % with older versions
        # ............................................................................

        # switched from this method (see above)
        # @tables = `$mysqlshow --user=$user --password=$password $db_main`;

        $sth = $dbh->prepare("show tables") or &error_message(qq~Error!\n
                                               Can't execute the query: $DBI::errstr~);
        
        $rv = $sth->execute or &error_message(qq~Error!\n
                               Can't execute the query: $DBI::errstr~);
        
        while ( ( $table_name ) = $sth->fetchrow_array ) 
                {
                if ( exists $skip_tables{$table_name} )
                        {
                        print "\nSkipping: [$table_name\]\n";
                        $body_text .= "\nSkipping: [$table_name\]\n";
                        next;
                        }

                print " " x 10 . "table: [$table_name\]\n";

                if ( $show_file_list_in_email eq 'yes' )
                        {
                        $body_text .= " " x 10 . "table: [$table_name\]\n";
                        }

                # now backup the table

                $backup_text = &do_backup($db_main, $table_name);

                if ( $show_file_list_in_email eq 'yes' )
                        {
                        $body_text .= $backup_text;
                        }
                }

        # disconnect from each database
        &logout;

        }


#
# Now check for the extra directory to back up
#

if ( $extra_dir ) {
	$body_text .= "\nTarring up $extra_dir files:\n";
	print "\nTarring up $extra_dir files:\n";
	$backup_tar_file = $mysql_backup_dir . "/" . "FILES.tar";
	$body_text .= `$nice_cmd $tar_cmd $tar_options -c -f $backup_tar_file $extra_dir`;
}

# now tar and compress
#............................................................................

chdir ("$mysql_backup_dir");

print qq~\nTarring and Gzipping Files:\n~;
$body_text .= "\nTarring and Gzipping Files:\n";

$backup_tar_file = $mysql_backup_dir . "/" . $file_prefix . "." . $date_text . "_.tar";

$body_text .= `$nice_cmd $tar_cmd $tar_options -c -f $backup_tar_file $tar_dir`;
$body_text .= `$nice_cmd $gzip_cmd $backup_tar_file`;

$backup_gzip_file = $backup_tar_file . ".gz";

if ( $chmod_backup_file eq 'yes' )
        {
        chmod 0600, $backup_gzip_file;
        }

$body_text .= "\nCreated Tar.Gzip File: $backup_gzip_file\n";

# now check option to delete text files
#............................................................................

if ( $delete_text_files eq 'yes' )
        {
        chdir ("$tar_dir");

        my $print_text = '';

        $print_text   .= "\nRemoving Intermediate files\n";
        $print_text   .= "Directory: $mysql_backup_dir/$tar_dir\n";
        $print_text   .= "File Spec: $file_prefix\.$date_text\_*.$mysql_dump_file_ext\n";

        $num_to_delete = `find $mysql_backup_dir -name "$file_prefix\.$date_text\_*.$mysql_dump_file_ext" -print | wc -l`;
        $print_text   .= "\nNumber of Files to be removed: $num_to_delete\n\n";

        # now delete files

        $delete = `find $mysql_backup_dir -name "$file_prefix\.$date_text\_*.$mysql_dump_file_ext" -print | xargs rm`;

        # check if all gone
        $num_deleted = `find $mysql_backup_dir -name "$file_prefix\.$date_text\_*.$mysql_dump_file_ext" -print | wc -l`;

        if ( $num_deleted == 0 )
            {
            $print_text .= "\nFiles Removed.\n";
            }
        else
            {
            $print_text .= "\nProblem Removing Files - $num_deleted files still exist.\n";
            }

        chdir ("$mysql_backup_dir");
        $removed_dir = `rm -r $tar_dir`;

        $print_text .= "\nRemoved temporary tar dir: $tar_dir\n";

        print $print_text;

        $body_text .= $print_text;
        }

# now clean old files from main dir (gzip files)
# includes old tar_dirs

&clean_old_files("$mysql_backup_dir");

# now email admin notification of backup, with attached file option
#............................................................................

$body_text .= "\n\nDone!\n\n";

if ( $email_backup eq 'yes' )
        {
        # MIME::Lite BLOCK
        # comment this block out if you don't have MIME::Lite installed

        MIME::Lite->send('sendmail', "$mailprog");

        # Create a new multipart message:
        $msg = new MIME::Lite
                    From    =>"$admin_email_from",
                    To      =>"$admin_email_to",
                    Subject =>"$subject",
                    Type    =>"multipart/mixed";
        
        # Add parts
        attach $msg
                    Type     =>"TEXT",
                    Data     =>"\nTar.Gzip File\n[$backup_gzip_file]\nAttached\n$body_text";
        
        attach $msg
                    Type     =>"x-gzip",
                    Encoding =>"base64",
                    Path     =>"$backup_gzip_file";
                    Filename =>"$backup_gzip_file";
        
        $msg->send || &error_message(qq~Error!\n\nError in Mailing Program!~);

        # comment out the block above if you don't have MIME::Lite installed
        }
else
        {
        # just send notice, without attachment
        &mail_to($admin_email_to, $admin_email_from, $subject, $body_text, $admin_email_from);
        }

print "\nE-mailing confirmation to $admin_email_to\n\n";

print "Done!\n";

exit;

###################################################################################
# connect_to_db
sub connect_to_db
{

# &connect_to_db($db_main);

my ($db_main) = @_;

if ( $password_location eq 'this_file' )
        {
        $dbh = DBI->connect("DBI:mysql:$db_main:$db_host:$db_port", $user, $password)
                || &error_message(qq~Error!\n
                You were unable to connect to the database.\n
                $DBI::errstr~);
        }

elsif ( $password_location eq 'cnf' )
        {
        $dbh = DBI->connect("DBI:mysql:$db_main:$db_host:$db_port"
                             . ";mysql_read_default_file=$cnf_file"
                             . ";mysql_read_default_group=$cnf_group",
                             $user, $password)
                             || &error_message(qq~Error!\n
                             You were unable to connect to the database.\n
                             $DBI::errstr~);
        }
else
        {
        &error_message(qq~Error!\n
                        ... connecting to the Database.\n
                        You were unable to connect to the database.
                        Please check your setup.
                        ~);

        }

# $dbh->{'PrintError'} = 1;
# $dbh->{'RaiseError'} = 1;

}
###################################################################################
# logout
sub logout
{
    
warn $DBI::errstr if $DBI::err;
if ( $dbh ){$rcdb = $dbh->disconnect;}
    
}
###################################################################################
# error_message
sub error_message
{

# &error_message($error_text);

my ($error_text) = @_;

my $subject = "$site_name MySQL Backup Error";

&mail_to($admin_email_to, $admin_email_from, $subject, $error_text, $admin_email_from);

print qq~
\n
$subject\n
$error_text\n
~;

exit;
  
}
###################################################################################
# mail_to
sub mail_to
{

# &mail_to($email_to, $email_from, $subject, $mail_body, $reply_to);

my ($email_to, $email_from, $subject, $mail_body, $reply_to) = @_;

if ( $reply_to !~ /\@/ ){$reply_to = $email_from;}

open (MAIL, "|$mailprog") || die print "Error!\n\nCan't open $mailprog!";

print MAIL "To: $email_to\n";
print MAIL "From: $email_from\n";
print MAIL "Subject: $subject\n";
print MAIL "Reply-To: $reply_to\n";
print MAIL "\n";
print MAIL "$mail_body";
print MAIL "\n";
close (MAIL);

}
###################################################################################
# do_backup
sub do_backup
{

# &do_backup($db_main, $table_name);

my ($db_main, $table_name) = @_;
my $response_text = '';

my $sth, $rv, $backup_file, $mysqldumpcommand;
my $backup_str, $row_string, $field_value;
my $len_field_terminate;
my @row;

$backup_file = $file_prefix . "." . $date_text . "_" . $db_main . "." . $table_name . "." . $mysql_dump_file_ext;

if ( $backup_type eq 'mysqldump' )
        {
        if ( $password_location eq 'cnf' )
            {
            $mysqldumpcommand  = "$mysqlbin/mysqldump $mysqldump_params";
            }
        else
            {
            $mysqldumpcommand  = "$mysqlbin/mysqldump --user=$user --password=$password $mysqldump_params";
            }
#	print "Command: $mysqldumpcommand $db_main $table_name > $backup_file\n";

        $response_text    .= `$mysqldumpcommand $db_main $table_name > $backup_file`;
        }
elsif ( $backup_type eq 'outfile' )
        {
	    $backup_str = "select * from $table_name into outfile '$backup_file' $outfile_params";

        $response_text    .= `$mysqldumpcommand $db_main $table_name > $backup_file`;
        }
elsif ( $backup_type eq 'outfile' )
        {
        $backup_str = "select * from $table_name into outfile '$backup_file' $outfile_params";

        $sth =  $dbh->do("$backup_str")
                      or &error_message("Error!\n\nCan't backup data: $DBI::errstr");

        }
else
        {
        unless ( open(FILE, ">$backup_file" ))
                {
                &error_message("Error!\n\nCan't open File $backup_file.");
                }

        $sth  = $dbh->prepare("select * from $table_name")
                or &error_message("Error!\n\nCan't do select for backup: $DBI::errstr");

        $rv   = $sth->execute
                or &error_message("Error!\n\nCan't execute the query: $DBI::errstr");

        while ( @row = $sth->fetchrow_array )
                {
                $row_string = '';

                foreach $field_value (@row)
                        {
                        $row_string .= $backup_field_enclosed_by .
                                       $field_value .
                                       $backup_field_enclosed_by .
                                       $backup_field_terminate;
                        }
                
                $len_field_terminate = length($backup_field_terminate);
                if ( substr($row_string,-$len_field_terminate,$len_field_terminate) eq $backup_field_terminate)
                        {
                        substr($row_string, -$len_field_terminate,$len_field_terminate) = '';
                        }

                $row_string .= $backup_line_terminate;

                print FILE $row_string;
                }        

        close(FILE);

        }

if ( $chmod_backup_file eq 'yes' )
        {
        chmod 0600, $backup_file;
        }

$response_text .= '                 File: ';
$response_text .= `ls -la $backup_file`;

return ($response_text);    
    
}
###################################################################################
# clean_old_files
sub clean_old_files
{

# $mysql_backup_dir
# $seconds_to_save  = $increments_to_save * $seconds_multiplier;

# call this subroutine with the '$full_dir_name'

my ($full_dir_name) = @_;

unless ( -e $full_dir_name ){return;}

$save_time  = time() - $seconds_to_save;
$old_files  = 0;

print qq~\nRemoving Files Older than $increments_to_save $increment_type\n~;
$body_text .= "\nRemoving Files Older than $increments_to_save $increment_type\n";
$body_text .= "\nFiles to be removed:\n\n";

opendir (DIRHANDLE, $full_dir_name);

# we use $file_prefix to make it safer; we don't want to delete
# any files except those matching the file spec

@filelist = grep { /^$file_prefix\./ } readdir(DIRHANDLE);

closedir (DIRHANDLE);

@sortlist   = sort(@filelist);

my $file_count = @sortlist;
my $file_msg   = "File Count in Backup Dir: $file_count \n";
print $file_msg;

$body_text .= $file_msg;

# loop through directory
foreach $infile (@sortlist)
        {
        $infile = "$full_dir_name/$infile";

        ($modtime) = (stat($infile))[9];

        if ( $modtime < $save_time )
                {
                # file is older, so delete it
                $old_files++;
        
                # check if file is a directory
                if ( -d $infile )
                    {
                    $body_text .= "\n - Deleting Tar Subdir: $infile -\n";
                    $deleted_dir = `rm -r -v $infile`;
                    if ( $deleted_dir eq "$infile" )
                        {
                        $body_text .= "\n - Deleted Tar Subdir Correctly.\n";
                        }
                    else
                        {
                        $body_text .= "\n - Problem Deleting Tar Subdir.\n";
                        }
                    }
                else
                    {
                    $body_text    .= "\n" . `ls -la $infile`;
                    $delete_count  = unlink "$infile";
        
                    if ( ! -e $infile and $delete_count == 1 )
                            {
                            $body_text .= "$delete_count File Removed: ($infile\)\n";
                            }
                    else
                            {
                            $body_text .= "\nProblem Removing File: $infile\n";
                            }
                    }
                }
        else
                {
                $body_text .= "\n- Keeping: $infile -\n";
                }

        }
    
}
###################################################################################
# backup_date_string notes
    
# this is a handy method to initialize date display
# it requires the POSIX and Time::Local calls above
# I use this because I got tired of messing with date routines

# strftime notes:
# %A - full weekday name
# %B - full month name
# %m - month as a decimal number (range 01 to 12).
# %d - day with leading zero
# %Y - 4 digit year
# %H - hour as a decimal number using a 24-hour clock (range 00 to 23).
# %l - hour using 12 hour clock, with no leading zero
# %M - minute as decimal, 00-59
# %S - second as a decimal number (range 00 to 61).
# %p - AM or PM
# %Z - time zone letters

# e.g: $backup_date_string = strftime("%Y-%m-%d_%H.%M.%S", localtime);

###################################################################################

