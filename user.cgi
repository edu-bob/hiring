#!/usr/bin/perl -w
# -*- Mode: perl; indent-tabs-mode: nil -*-
# Copyright(c) 2003-2007 Robert L. Brown.  This is licensed software
# only to be used with an explicit right-to-use license from the
# copyright holder.


## Step 1.
## 
## if admin user
##   select user to edit
##   validate against the admin user password
##   submit to step 2
## 
## if no admin user
##   offer to change:
##     password
##     e-mail address
##     e-mail
##   submit to "complete"
## 
## Step 2. (admin user only)
## 
## Offer to change
##   Whole Record.


use strict;
use CGI::Carp qw(fatalsToBrowser);
use Digest::MD5 qw(md5 md5_hex md5_base64);

use CGI qw(:standard *table *ol *ul *Tr *td *li *img *p -nosticky);

require "globals.pl";
use ParamTable;

use Layout;
use Login;
use Database;
use User;
use Application;
use Changes;
use Audit;
use Utility;
use Argcvt;
use Email;

Application::Init();

if ( param("op") ) {
    my $op = param("op");
  SWITCH: {
      $op eq "step2" and do {
          doStep2();
          last SWITCH;
      };
      $op eq "go" and do {
          doGo();
          last SWITCH;
      };
      $op eq "forgot" and do {
          doForgot();
          last SWITCH;
      };
      $op eq 'sendpwemail' and do {
          doPasswordEmail();
          last SWITCH;
      };
      $op eq 'resetpw' and do {
          doPasswordReset();
          last SWITCH;
      };
      $op eq "passwordresetfinish" and do {
          doPasswordResetFinish();
          last SWITCH;
      };
  };
} else {
    doFirstPage();
}
exit(0);

sub doFirstPage
{
    my $self_url = self_url;

    print header;
    print doHeading({-title=>"Manage a User Account"});
    ConnectToDatabase();

  BODY: {

      # There should be no link to this page if the user is not logged in, but a user could bookmark
      # the URL or type it in explicitly and come here, so this check enforces that users must
      # be logged in to manage their account.
      
      if ( !isLoggedIn() ) {
          my $self_url = url(-relative=>1);
          print p(b("You must be logged in to perform this operation: ",
                    a({-href=>"loginout.cgi?link=$self_url"},"Log in")));
          last BODY;
      }
      if ( isAdmin() ) {
          param("op", "step2");
          print Layout::startForm({-action=>url()}), "\n";
          print hidden({-name=>"op", -default=>"step2"}), "\n";

          print start_table({-border=>"0"}), "\n";
          print start_Tr, "\n";
      
          print td({-align=>"right"}, "User name:"), "\n";

          print td(
                   PulldownMenu({
                       -table => \%::UserTable,
                       -column => "name",
                       -name => "id",
                       -default=>getLoginId(),
                       -skipfilters=>["active"],
                   })), "\n";
          print Tr(
                   td(),
                   td( submit({-name=>"Continue"})),
                   );
          print end_table;
      } else {
          doUserForm(getLoginId());
      }
  };
    print Footer, end_html, "\n";
}

##
##  doStep2 - this step handles the admin user after he has selected a user to edit
##

sub doStep2
{
    my $self_url = self_url;
    print header;
    print doHeading({-title=>"Manage a User Account"});
    ConnectToDatabase();
    doUserForm(param("id"));
    print Footer, end_html, "\n";
}

sub doUserForm
{
    my ($user_id) = (@_);
    my $user = User::getRecord($user_id);

  BODY: {

      # There should be no link to this page if the user is not logged in, but a user could bookmark
      # the URL or type it in explicitly and come here, so this check enforces that users must
      # be logged in to manage their account.

      if ( !isLoggedIn() ) {
          my $self_url = url(-relative=>1);
          print p(b("You must be logged in to perform this operation: ",
                    a({-href=>"loginout.cgi?link=$self_url"},"Log in")));
          last BODY;
      }

      param("op", "go");
      print Layout::startForm({-action=>url()}), "\n";
      print hidden({-name=>"op", -default=>"go"}), "\n";

      print start_table({-border=>"0"}), "\n";
      print Tr(
               td({-align=>"right"}, "User name:"), "\n",
               td(User::getName($user)), "\n",
               ), "\n";

      ## If this is the admin user, we need to pass along the login_id.
      ## This is not trusted in the response method for non-admin users
      
      if ( isAdmin() ) {
          print hidden({
              -name=>"id",
              -default=>$user_id,
          });
      }

      ## The old password is only needed if this is not the admin user
      ## Only ask for this if the user has a password defined.

      if ( !isAdmin() ) {
          if ( defined $user->{'password'} ) {
              print Tr(
                       td({-align=>"right"}, "Old password:"), "\n",
                       td(password_field({-name=>"oldpassword", -size=>"16"})), "\n",
                       ), "\n";
          }
      }
      print Tr(
               td({-colspan=>"2"}, hr()),
               ), "\n";

      ## New password

      print Tr(
               td({-align=>"right"}, "New password:"), "\n",
               td(password_field({-name=>"newpassword1", -size=>"16"})), "\n",
               ), "\n";
      print Tr(
               td({-align=>"right"}, "New password again:"), "\n",
               td(password_field({-name=>"newpassword2", -size=>"16"})), "\n",
               ), "\n";
      print Tr(
               td({-colspan=>"2"}, hr()),
               ), "\n";
      print end_table, "\n";
      ## Other fields can only be edited by an admin user

      if ( isAdmin() ) {
          print Layout::doEditForm({
              -table=>\%::UserTable,
              -record=>$user,
              -hide=>['name', 'password'],
              -suffix=>"_x",
          });
      }

      print submit({-name=>"Update"});
      print Layout::endForm;
  };

}


sub doGo
{
    print header;
    ConnectToDatabase();

    my $self_url = self_url;
    print doHeading({-title=>"Manage a User Account"});
        
    my $user_id;
    if ( isAdmin() ) {
        $user_id = param("id");
    } else {
        $user_id = getLoginId();
    }
    my $user = User::getRecord($user_id);
        
    my $oldpassword = param("oldpassword");
    my $newpassword1 = param("newpassword1");
    my $newpassword2 = param("newpassword2");

    my $changes = new Changes;

  BODY: {

      if ( !isLoggedIn() ) {
          my $self_url = url(-relative=>1);
          print p(b("You must be logged in to perform this operation: ",
                    a({-href=>"loginout.cgi?link=$self_url"},"Log in")));
          last BODY;
      }

      # If this user is not an admin user, then they must validate themselves with their old password.

      if ( !isAdmin() ) {
          if ( defined $user->{'password'} &&
               !User::matchPassword($oldpassword,$user->{'password'}) ) {
              print p(b("The password you entered for yourself does not match your saved password.  Go back and try again"));
#              print "<pre>",Data::Dumper->Dump([$user, $oldpassword], ["user", "oldpassword"]), "</pre>";
              last BODY;
          }
      }
      
      if ( $newpassword1 ne $newpassword2 ) {
          print p(b("The two new passwords you entered do not match.  Go back and try again.")), "\n";
          last BODY;
      }
      

      my $new_rec;
      my $encrypted_password = User::cryptPassword($newpassword1);
      $new_rec->{'password'} = $encrypted_password;
      $changes->add({-table=>"user",
                     -row=>"$user_id",
                     -column=>"password",
                     -type=>"CHANGE",
                     -old=>$user->{'password'},
                     -new=>$new_rec->{'password'},
                     -user=>getLoginId(),
                 });

      Database::updateSimpleRecord({
          -table=>\%::UserTable,
          -old=>$user,
          -new=>$new_rec,
      });

      if ( isAdmin() ) {
          $user->{'password'} = $encrypted_password;
          param("password_x", $encrypted_password);
          param("id_x", $user_id);
          Layout::doUpdateFromParams({
              -table=>\%::UserTable,
              -record=>$user,
              -suffix=>"_x",
              -changes=>$changes,
          });
      }
      auditUpdate($changes);
      print $changes->listHTML({-user=>Login::getLoginRec()});

  };
    print Footer, end_html, "\n";
}


##
## Forgot password page
##

sub doForgot
{
    ConnectToDatabase();
    print header;
    my $heading = "Forgot Password";
    print Layout::doForgotPasswordForm({
                                       -heading=>$heading,
                                       });
    print end_html;
}

##
## send password email
##

sub doPasswordEmail
{
    ConnectToDatabase();
    print header;

    my $login_name = param("login_name");
    print doHeading({-title=>"Sending password reset email"});
    my ($rec, $user_id);
  BODY: {
      if ( $login_name ) {
          my $recs;
          if ( $login_name =~ /@/ ) {
              $recs = getRecordsMatch({
                  -table=>\%::UserTable,
                  -column => 'email',
                  -value => $login_name,
                                      });
          } else {
              $recs = getRecordsMatch({
                  -table=>\%::UserTable,
                  -column => 'name',
                  -value => $login_name
                                      });
          }
          if ( $recs && scalar @$recs > 0 ) {
              $rec = $recs->[0];
              $user_id = $rec->{'id'};
          } else {
              $rec = undef;
          }
      } else { 
          print Utility::redError("Something went wrong - no user name present");
          last BODY;
      }
      if ( !$rec ) {
          print Utility::errorMessage("Sorry, \"$login_name\" is not a known user"), "\n";
          last BODY;
      }

      my $changes = new Changes;

      ## Generate a reset password token, and log the audit record for it

      my $token = Digest::MD5::md5_hex(rand);

      my $new_rec;
      $new_rec->{'passwordkey'} = $token;
      $changes->add({-table=>"user",
                     -row=>"$user_id",
                     -column=>"passwordkey",
                     -type=>"CHANGE",
                     -old=>$rec->{'passwordkey'},
                     -new=>$new_rec->{'passwordkey'},
                     -user=>getLoginId(),
                 });

      Database::updateSimpleRecord({
          -table=>\%::UserTable,
          -old=>$rec,
          -new=>$new_rec,
      });
      auditUpdate($changes);

      ## Generate the password reset URL and email it to that user

      my $url = Layout::fullURL("user.cgi?op=resetpw;token=$token");

      my $body = "";
      my $boundary = "**__**__**__**__**__";

      $body .= "This is a multipart message in MIME format.\n\n";
      $body .= "--$boundary\n";
      
      my $m = new CGI;
      $body .= $m->header;

      my $me = Param::getValueByName("title") || "Candidate Tracker";

      $body .= p("The $me received a request to send you a password reset link.");
      $body .= p("If you didn't request it, delete this message.  Otherwise, click on the link below.") . "\n";
      $body .= p("This link can be used exactly once.");
      $body .= p(a({-href=>$url}, "Reset password for $rec->{'name'}")) . br . "\n";
      $body .= "\n--$boundary--\n";

#      print p("BODY"), $body;

      print p("Go check email for $rec->{'email'} and click on the link in the message.");
      print p("Please note that the link in the email will expire as soon as you have used it once.");

      my $from = Param::getValueByName("e-mail-from");
      if ( !defined $from ) {
          $from = $::EMAIL_FROM;
      }
      
      Email::sendHtmlEmail({
          -from => $from,
          -to => $rec->{'email'},
          -subject => "Password reset for $me",
          -boundary => $boundary,
          -body => $body,
                           });

    };

    print end_html;
    
}

##
## Process a reset password request
##

sub doPasswordReset()
{
    ConnectToDatabase();
    print header;

    my $token = param("token");

    my $rec = User::getRecordBy({
        -column => "passwordkey",
        -value => $token,
                                });

  BODY: {
      if ( !$rec ) {
          print Utility::errorMessage("There is no user holding this password reset token.");
          last BODY;
      };
      
      my $heading = "Reset password for $rec->{'name'}";

      my $result = "";
      $result .= doHeading({
          -title => $heading,
                           });

      $result .= Layout::startForm({
          -action => "user.cgi",
          -name => "passwordform",
                                   }) . "\n";
      param("op", "passwordresetfinish");
      $result .= hidden({-name => "op", -default => "passwordresetfinish"}) . "\n";
      $result .= hidden({-name => "token", -default => $token}) . "\n";

      $result .= start_table({-border=>"0"}) . "\n";
      
      $result .= Tr(
          td({-align=>"right", -id=>"passleft"}, "New password: "),
          td(password_field({-name=>"password", -id=>"passright"})),
          ) . "\n";
      
      $result .= Tr(
          td("&nbsp;"),
          td(submit({-name => "submit", -value => "Set" })),
          ) . "\n";
      

      $result .= end_table . "\n";
      
      $result .= Layout::endForm . "\n";
      
      $result .= end_table;

      print $result;
    };
    print end_html;
}

sub doPasswordResetFinish()
{
    ConnectToDatabase();
    print header;

    my $changes = new Changes;

    my $token = param("token");

    my $rec = User::getRecordBy({
        -column => "passwordkey",
        -value => $token,
                                });

  BODY: {
      if ( !$rec ) {
          print Utility::errorMessage("There is no user holding this password reset token.");
          last BODY;
      };
      print doHeading({
          -title => "Password Reset for $rec->{'name'}",
                      });

      my $user_id = $rec->{'id'};

      my $new_rec;
      $new_rec->{'passwordkey'} = undef;
      $changes->add({-table=>"user",
                     -row=>$user_id,
                     -column=>"passwordkey",
                     -type=>"CHANGE",
                     -old=>$rec->{'passwordkey'},
                     -new=>$new_rec->{'passwordkey'},
                     -user=>getLoginId(),
                    });


      my $pw = param("password");
      $new_rec->{'password'} = User::cryptPassword($pw);
      $changes->add({-table=>"user",
                     -row=>$user_id,
                     -column=>"password",
                     -type=>"CHANGE",
                     -old=>$rec->{'password'},
                     -new=>$new_rec->{'password'},
                     -user=>getLoginId(),
                    });


      Database::updateSimpleRecord({
          -table=>\%::UserTable,
          -old=>$rec,
          -new=>$new_rec,
      });

      auditUpdate($changes);
#      print $changes->listHTML();

#      print dumpQueries();

      print p("Completed.  Please log in using the new password."), "\n";
    };
    print Footer({-url=>url( -base => 1)}), end_html, "\n";
}
