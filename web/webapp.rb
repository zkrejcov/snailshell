require 'sinatra'
require 'data_mapper'
require 'digest/sha1'
require 'sinatra/flash'
require 'sinatra/redirect_with_flash'
require_relative '../client/message'

# these are the default settings for Sinatra
# change for your own host and desired port, if you want to make it accessible
set :bind => 'localhost', :port => 4567

# by default, this uses the awsome lightweight sqlite3 database
# again, change this to whatever suits your needs, beware the needed datamapper
# libs if you do so
DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/snailshell.db")

class User
  include DataMapper::Resource
  property :id, Serial
  property :username, Text, :required => true, :unique => true, :messages => {
      :is_unique => "That username has already been taken."
    }
  property :email, Text, :required => true, :format => /.+@.+\..+/
  property :encrypted_password, Text
  property :salt, Text

  has n, :machines
  has n, :commands
  has n, :emails
end

class Machine
  include DataMapper::Resource
  property :id, Serial
  property :label, Text, :required => true, :unique => :user
  property :mailbox, Text, :required => true, :format => /.+@.+\..+/
  property :hash_key, Text, :required => true

  belongs_to :user
end

class Email
  include DataMapper::Resource
  property :id, Serial
  property :label, Text, :required => true, :unique => :user
  property :mail, Text, :required => true, :format => /.+@.+\..+/
  property :password, Text, :required => true
  property :port, Integer, :required => true, :format => /\d+/, :messages => {
      :format => "Port must be a (natural) number."
    }
  property :host, Text, :required => true
  property :ssl, Boolean, :required => true
  property :domain, Text, :required => true

  belongs_to :user
end

class Command
  include DataMapper::Resource
  property :id, Serial
  property :label, Text, :required => true, :unique => :user
  property :command, Text, :required => true

  belongs_to :user
end

DataMapper.finalize.auto_upgrade!

enable :sessions

# GET

# gotta love IE - or not
get '/*', :agent => /MSIE/ do
  '<body style="background-color: black; color: red; font-size: 2em; text-align:
center"><br /><br /><em style="font-size: 5em; font-weight: bold;">NO IE HERE!</em>
<br />get <a href="http://www.mozilla.org/en-US/firefox/new/">Firefox</a> or
<a href="http://www.google.com/chrome">Chrome</a></body>'
end

get '/' do
  erb :'sessions/home'
end

get '/headquarters' do
  if logged_in?
    @machines = Machine.all :user => current_user, :order => :id.asc
    @emails = Email.all :user => current_user, :order => :id.asc
    @commands = Command.all :user => current_user, :order => :id.asc
    erb :'sessions/headquarters'
  end
end

get '/signup' do
  erb :'users/new'
end

get '/login' do
  erb :'sessions/login'
end

get '/logout' do
  if logged_in?
    session.delete :user_id
    redirect '/', :notice => "You have been logged out."
  end
end

get '/settings' do
  erb :'sessions/settings' if logged_in?
end

get '/machine' do
  @method = "post"
  @title = "New Machine"
  erb :'machines/form' if logged_in?
end

get '/command' do
  @method = "post"
  @title = "New Command"
  erb :'commands/form' if logged_in?
end

get '/email' do
  @method = "post"
  @title = "New Email"
  erb :'emails/form' if logged_in?
end

get '/machine/:id' do
  if logged_in?
    @machine = Machine.get(params[:id])
    @title = "Edit Machine"
    @method = "put"
    erb :'machines/form'
  end
end

get '/command/:id' do
  if logged_in?
    @command = Command.get(params[:id])
    @title = "Edit Command"
    @method = "put"
    erb :'commands/form'
  end
end

get '/email/:id' do
  if logged_in?
    @email = Email.get(params[:id])
    @title = "Edit Email"
    @method = "put"
    erb :'emails/form'
  end
end

get '/machine/:id/delete' do
  if logged_in?
    @machine = Machine.get(params[:id])
    erb :'machines/delete'
  end
end

get '/command/:id/delete' do
  if logged_in?
    @command = Command.get(params[:id])
    erb :'commands/delete'
  end
end

get '/email/:id/delete' do
  if logged_in?
    @email = Email.get(params[:id])
    erb :'emails/delete'
  end
end

# POST
post '/login' do
  user = User.first(:username => params[:username])
  unless user
    redirect '/login', :error => "Wrong username or password."
  end
  if user.encrypted_password == encrypt_password(params[:password], user.salt)
    session[:user_id] = user.id
    redirect '/', :notice => "Welcome home, #{user.username}."
  else
    redirect '/login', :error => "Wrong username or password."
  end
end

post '/signup' do
  if params[:password] != params[:password_confirmation]
    redirect '/signup', :error => "Password and its confirmation does not match."
  end
    user = User.new
    user.username = params[:username]
    user.email = params[:email]
    user.salt = user.email+Time.now.to_s
    user.encrypted_password = encrypt_password(params[:password], user.salt)
    if user.save
      redirect '/', :notice => "User succesfully created."
    else
      notice = "Couldn't create such user.<ul>"
      user.errors.each do |error|
        notice += "<li>#{error[0]}</li>"
      end
      notice += "</ul>"
      redirect '/signup', :error => notice
    end
end

post '/machine' do
  machine = Machine.new
  machine.label = params[:label]
  machine.mailbox = params[:mailbox]
  machine.hash_key = params[:hash_key]
  machine.user = current_user
  if machine.save
    redirect '/headquarters', :notice => "Machine succesfully created."
  else
    notice = "Couldn't create such machine.<ul>"
    machine.errors.each do |error|
      notice += "<li>#{error[0]}</li>"
    end
    notice += "</ul>"
    redirect '/machine', :error => notice
  end
end

post '/command' do
  command = Command.new
  command.label = params[:label]
  command.command = params[:command]
  command.user = current_user
  if command.save
    redirect '/headquarters', :notice => "Command succesfully created."
  else
    notice = "Couldn't create such command.<ul>"
    command.errors.each do |error|
      notice += "<li>#{error[0]}</li>"
    end
    notice += "</ul>"
    redirect '/command', :error => notice
  end
end

post '/email' do
  email = Email.new
  email.label = params[:label]
  email.mail = params[:email]
  email.password = params[:password]
  email.port = params[:port].to_i
  email.host = params[:host]
  email.ssl = !!params[:ssl]
  email.domain = params[:domain]
  email.user = current_user
  if email.save
    redirect '/headquarters', :notice => "Email succesfully created."
  else
    notice = "Couldn't create such email.<ul>"
    email.errors.each do |error|
      notice += "<li>#{error[0]}</li>"
    end
    notice += "</ul>"
    redirect '/email', :error => notice
  end
end

post '/headquarters' do
  begin
    email = Email.get(params[:email_id].to_i)
    command = Command.get(params[:command_id].to_i)
    to = Machine.get(params[:machine_id].to_i)
    send_command(email, to, command)
    redirect '/headquarters', :notice => "Command sent."
  rescue => e
    logger.error e
    redirect '/headquarters', :error => "Command could not be sent."
  end
end

# PUT
put '/machine/:id' do
  machine = Machine.get(params[:id])
  machine.label = params[:label]
  machine.mailbox = params[:mailbox]
  machine.hash_key = params[:hash_key]
  if machine.save
    redirect '/headquarters', :notice => "Machine succesfully updated."
  else
    @method = "put"
    notice = "Couldn't update this machine."
    email.errors.each do |error|
      notice += "<li>#{error[0]}</li>"
    end
    notice += "</ul>"
    redirect "/machine/#{params[:id]}", :error => notice
  end
end

put '/command/:id' do
  command = Command.get(params[:id])
  command.label = params[:label]
  command.command = params[:command]
  if command.save
    redirect '/headquarters', :notice => "Command succesfully updated."
  else
    @method = "put"
    notice = "Couldn't update this command."
    email.errors.each do |error|
      notice += "<li>#{error[0]}</li>"
    end
    notice += "</ul>"
    redirect "/command/#{params[:id]}", :error => notice
  end
end

put '/email/:id' do
  email = Email.get(params[:id])
  email.label = params[:label]
  email.mail = params[:email]
  email.password = params[:password]
  email.port = params[:port].to_i
  email.host = params[:host]
  email.ssl = !!params[:ssl]
  email.domain = params[:domain]
  if email.save
    redirect '/headquarters', :notice => "Email succesfully updated."
  else
    @method = "put"
    notice = "Couldn't update this email."
    email.errors.each do |error|
      notice += "<li>#{error[0]}</li>"
    end
    notice += "</ul>"
    redirect "/email/#{params[:id]}", :error => notice
  end
end

put '/settings' do
  if params[:change] == "password"
    do_pwd_change
  else
    do_email_change
  end
  redirect '/', :notice => "Profile updated."
end

# DELETE
delete '/machine/:id' do
  Machine.get(params[:id]).destroy
  redirect '/headquarters', :notice => "Machine deleted."
end

delete '/command/:id' do
  Command.get(params[:id]).destroy
  redirect '/headquarters', :notice => "Command deleted."
end

delete '/email/:id' do
  Email.get(params[:id]).destroy
  redirect '/headquarters', :notice => "Email deleted."
end

# HELPERS
def encrypt_password(password, salt)
  Digest::SHA1.new.hexdigest(password + salt)
end

def logged_in?
  id = session[:user_id]
  unless id
    redirect '/', :error => "You must log in first."
    pass
  end
  id
end

def current_user
  User.get(session[:user_id])
end

def send_command(from, to, command)
  hash = SnailShell::Utils.count_hash(command.command, to.hash_key)

  SnailShell::Message.send_over_smtp(from.host, from.port, from.ssl,
    from.domain, from.password, from.mail, to.mailbox, command.command, hash)
end

def first_8_chars(multiline_string)
  parts = multiline_string.split
  final = parts[0][0,8]
  final += " ..." if parts.length>1 || parts[0].length>10

  final
end

def do_pwd_change
  user = current_user
  if user.encrypted_password == encrypt_password(params[:old_password], user.salt)
    if params[:new_password] == params[:new_password_confirmation]
      user.salt = user.email+Time.now.to_s
      user.encrypted_password = encrypt_password(params[:new_password], user.salt)
      unless user.save
        notice = "Couldn't update profile."
        user.errors.each do |error|
          notice += "<li>#{error[0]}</li>"
        end
        notice += "</ul>"
        redirect '/settings', :error => notice
      end
    else
      redirect '/settings', :error => "Passwords do not match."
    end
  else
    redirect '/settings', :error => "Wrong password."
  end
end

def do_email_change
  user = current_user
  if user.encrypted_password == encrypt_password(params[:password], user.salt)
    user.email = params[:email]
    unless user.save
      notice = "Couldn't update profile."
      user.errors.each do |error|
        notice += "<li>#{error[0]}</li>"
      end
      notice += "</ul>"
      redirect '/settings', :error => notice
    end
  else
    redirect '/settings', :error => "Wrong password."
  end
end
