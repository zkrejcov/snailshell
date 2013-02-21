SnailShell
==========
`<joke>`SuperNatural, Awsome, Incredible, Longdistance Shell (over
mail)`</joke>`

It uses 
- net/pop for checking the mailbox,
- net/smtp for sending the commands in the first place (and status updates)
- open4 for executing the command sent and getting the exit code, errors, output, pid
- openssl, openssl/digest for MAC
- optparse for parsing the commandline options/arguments

What you need to make it work
-----------------------------
- Ruby, obviously
- the code, again, obviously
- a few more libraries (gems or rpms - which worked better for me)
  - for the web part:
    - sinatra
    - sinatra-redirect-with-flash
    - sinatra-flash
    - data_mapper and its db mapper:
    - dm-sqlite-adapter (or the one for the db of your choice)
  - for the client part of the project:
    - nothing I can think of now
- a database of your choice for the web part (which is just a Sinatra exercise
  and not needed), the code is set to use sqlite3

How to run it
-------------
The web part is simple - `ruby webapp.rb` will run the webapp with the default settings. 
If you want to run in on a diferent host, port, db... well change that in the code - it's 
the first few lines, nothing hard.

The client part has a few more options. If you just do `ruby snailshell.rb`, it won't do 
anything. You can get complete usage info with the `-h` switch. With `-d` switch, you will 
tell it to start the daemon in the background. It will print out the pid and also save it 
to .daemon file. This way, when you want to kill the daemon with the `-D` switch, or all 
of them if you started multiple (heaven knows why), it will read the pids form that file, 
kill all the daemons and delete the file.
To be able to send and receive commands by email, you have to first set some up.
You can do that either manually, since the configuration files are simple plaintext 
properties files (please keep the format if you do so), or you can use the client again, 
with the right switches (see the usage message). You might have noticed it is possible to 
set more than one mailbox to send commands to - while that is true, only the first one in 
the list will be watched by the daemon.
If you want to send a command, you have again a few options how to do that, though I'd 
advise not to use Gmail for authoring, since it likes to format it and sends a quite ugly 
html. You can use the client to send a nice plaintext message, you can even save
your favourite commands in the `commands` folder and then just give the client
the filename.
All the important stuff is logged to `log/error.log`, `log/mail.log` and `log/daemon.log`.
A lot of the settings can be found and changed in the utils.rb file - the log and 
settings files location, daemon pid file and the default subject for the commands sent 
out are there.
