$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/unit'
require './snailshell'

class SnailshellTest < Test::Unit::TestCase

#  def test_add_email
#    SnailShell::EmailProfiles.new.add_profile
#  end
#
#  def test_add_mailbox
#    SnailShell::MailboxProfiles.new.add_profile
#  end
#
#  def test_trust_sig
#    SnailShell::Security.set_up_trusted("signature")
#  end
#
#  def test_trust_sig_label
#    SnailShell::Security.set_up_trusted("label", "signature")
#  end
#
#  def test_trust_show
#    SnailShell::Security.show_trusted
#  end
#
#  def test_remove_mailbox
#    SnailShell::MailboxProfiles.new.remove_profile "label"
#  end
#
#  def test_list_mailboxes
#    SnailShell::MailboxProfiles.new.show_profiles
#  end
#
#  def test_remove_email
#    SnailShell::EmailProfiles.new.remove_profile "label"
#  end
#
#  def test_list_emailes
#    SnailShell::EmailProfiles.new.show_profiles
#  end
#
#  def test1_send_mail
#    puts "SEND MAIL TEST"
#    SnailShell::Mail.send_mail
#  end

  def test2_send_command
    puts "SEND COMMAND TEST"
    SnailShell::Mail.send_mail "pwd", "testmail", "testmail"
  end

  def test3_run_daemon
    puts "RUN DAEMON TEST"
    run_daemon
  end

  def test4_kill_daemons
    puts "KILL DAEMON TEST"
    sleep(10)
    kill_daemons
  end

#  def test_trust_all
#    SnailShell::Security.set_up_trusted("")
#  end
#
#  def test_trust_all_for_profile
#    SnailShell::Security.set_up_trusted("label", "")
#  end
end
