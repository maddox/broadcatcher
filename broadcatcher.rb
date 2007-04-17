#!/usr/local/bin/ruby -rubygems
require 'camping'
require 'camping/session'

Camping.goes :Broadcatcher


module Broadcatcher
  include Camping::Session
end


module Broadcatcher::Models


  class Pass < Base
    belongs_to :quality
    belongs_to :length
    validates_presence_of :title, :length, :season, :quality, :next_episode
  end
  class Quality < Base
    has_many :passes
  end
  class Length < Base
    has_many :passes
  end
  class Setting < Base;end

  class CreateTheBasics < V 1.0
    def self.up
      create_table :broadcatcher_passes do |t|
        t.column :id,           :integer, :null => false
        t.column :quality_id,      :integer, :null => false
        t.column :length_id,       :integer, :null => false
        t.column :title,        :string,  :limit => 255
        t.column :season,       :integer, :null => false
        t.column :next_episode, :integer, :null => false
      end

      create_table :broadcatcher_settings do |t|
        t.column :id,     :integer, :null => false
        t.column :key,    :string, :limit => 255
        t.column :value,  :string, :limit => 255
      end

      create_table :broadcatcher_qualities do |t|
        t.column :id,     :integer, :null => false
        t.column :title,  :string, :limit => 255
        t.column :regex,  :string, :limit => 255
        t.column :multiple, :integer
      end

      create_table :broadcatcher_lengths do |t|
        t.column :id,       :integer, :null => false
        t.column :title,    :string, :limit => 255
        t.column :multiple, :integer
      end

      Setting.create :key => 'download_directory', :value => '/home/username/downloads'
      Setting.create :key => 'newzbin_username', :value => 'your_username'
      Setting.create :key => 'newzbin_password', :value => 'your_password'

      Quality.create :title => 'hdtv', :regex => 'hdtv|pdtv|dsr|dsrip', :multiple => 1
      Quality.create :title => 'hrhd', :regex => 'hr[-|.]', :multiple => 2
      Quality.create :title => '720p', :regex => '720', :multiple => 3

      Length.create :title => '30 mins', :multiple => 1
      Length.create :title => '60 mins', :multiple => 2
      Length.create :title => '90 mins', :multiple => 3
      Length.create :title => '120 mins', :multiple => 4

    end
    def self.down
      drop_table :broadcatcher_passes
      drop_table :broadcatcher_settings
    end
  end
end

module Broadcatcher::Controllers

  # The root slash shows the `index' view.
  class Index < R '/'
    def get
      @passes = Pass.find(:all) 
      render :index 
    end
  end

  class Show < R '/show/(\d+)'
    def get pass_id
      @pass = Pass.find(pass_id)
      render :show 
    end
  end

  class Add < R '/add'
    def get
      @pass = Pass.new
      @qualities = Quality.find(:all)
      @lengths = Length.find(:all, :order => 'multiple')
      render :add 
    end
    
    def post
      pass = Pass.create(:title => input.pass_title, :season => input.pass_season, :length_id => input.pass_length, :next_episode => input.pass_next_episode, :quality_id => input.pass_quality)
      
      redirect Show, pass
    end

  end

  class Edit < R '/edit/(\d+)'
    def get pass_id
      @pass = Pass.find(pass_id)
      @lengths = Length.find(:all, :order => 'multiple')
      @qualities = Quality.find(:all)
      
      render :edit 
    end
    
    def post pass_id
      
      pass = Pass.find(pass_id)
      pass.update_attributes(:title => input.pass_title, :season => input.pass_season, :length_id => input.pass_length, :next_episode => input.pass_next_episode, :quality_id => input.pass_quality)

      redirect Show, pass
    end

  end
  

  class Delete < R '/delete/(\d+)'
    def get pass_id
      @pass = Pass.find(pass_id)
      @pass.destroy
      
      redirect Index      
    end
  end
  
  class Todo < R '/todo'
    def get
      @passes = Pass.find(:all)
      render :todo
    end
  end
  
  class Settings < R '/settings'
    def get
      @settings = {}
      
      Setting.find(:all).each{ |setting| @settings[setting.key] = setting.value}
      render :settings
    end
    
    def post
      Setting.find_by_key('download_directory').update_attributes(:value => input.setting_download_directory)
      Setting.find_by_key('newzbin_username').update_attributes(:value => input.setting_newzbin_username)
      Setting.find_by_key('newzbin_password').update_attributes(:value => input.setting_newzbin_password)

      redirect Settings
    end
  end
  
  class Run < R '/run'
    def get
      Kernel.system(File.join(File.dirname(__FILE__), 'catcher.rb'))
    end
  end
  

end

module Broadcatcher::Views

  # If you have a `layout' method like this, it
  # will wrap the HTML in the other methods.  The
  # `self << yield' is where the HTML is inserted.
  def layout
    html do
      title { 'My HomePage' }
      body { self << yield + _nav }
    end
  end

  # The `index' view.  Inside your views, you express
  # the HTML in Ruby.  See http://code.whytheluckystiff.net/markaby/.
  def index
    

    h1 do
      "Season Passes"
    end
    
    ul do
      @passes.each do |pass|
        li do 
          a pass.title, :href => R(Show, pass) 
        end
      end
    end
    
    p { a 'New Season Pass', :href => R(Add) }
    
    
  end

  # The `sample' view.
  def show
    
    h1 { @pass.title}
    
    dl do
      dt { "Season" }
      dd { pass.season }
      dt { "Next Episode" }
      dd { pass.next_episode }
      dt { "Length" }
      dd { pass.length.title }
      dt { "Quality" }
      dd { pass.quality.title }
    end
    
    a 'Edit', :href => R(Edit, pass)
    br
    a 'Delete', :href => R(Delete, pass) 
    

  end

  def add
    h1 { 'Create a new Season Pass'}
    _form
  end

  def edit
    h1 { 'Edit a Season Pass'}
    _form
  end
  
  def todo
    h1 'To Do'
    
    @passes.each do |pass|
      p "#{pass.title} - Episode #{pass.next_episode}"
    end
  end
  
  def settings
    h1 'Settings'
    
    form({:method => 'post'}) do
      label 'Download Directory', :for => 'setting_download_directory'; br
      input :name => 'setting_download_directory', :type => 'text', :value => @settings["download_directory"]; br

      label 'Newzbin Username', :for => 'setting_newzbin_username'; br
      input :name => 'setting_newzbin_username', :type => 'text', :value => @settings["newzbin_username"]; br

      label 'Newzbin Password', :for => 'setting_newzbin_password'; br
      input :name => 'setting_newzbin_password', :type => 'password', :value => @settings["newzbin_password"]; br

      input :type => 'submit'
    end
  end
  
  # partials
  
  def _nav
    ul do
      li { a 'Season Passes', :href => R(Index)}
      li { a 'To Do', :href => R(Todo)}
      li { a 'Run Scan', :href => R(Run)}
      li { a 'Settings', :href => R(Settings)}
    end
  end
  
  def _form
    form({:method => 'post'}) do
      label 'Title', :for => 'pass_title'; br
      input :name => 'pass_title', :type => 'text', :value => pass.title; br

      label 'Season', :for => 'pass_season'; br
      input :name => 'pass_season', :type => 'text', :value => pass.season; br

      label 'Length', :for => 'pass_length'; br
      collection_select(pass, :length, @lengths, 'id', 'title')
      br

      label 'Quality', :for => 'pass_quality'; br
      collection_select(pass, :quality, @qualities, 'id', 'title')
      br
      
      label 'Next Episode', :for => 'pass_next_episode'; br
      input :name => 'pass_next_episode', :type => 'text', :value => pass.next_episode; br

      input :type => 'hidden', :name => 'pass_id', :value => pass.object_id
      input :type => 'submit'
    end
    
  end
  
  # helpers
  
  def collection_select(object, method, collection, value_method, text_method)
    select :name => "#{object.class.name.split(/::/).last.downcase}_#{method}" do
      collection.each do |item|
        if item.send(value_method) == object.send(method).object_id
          option(:value => item.send(value_method), :selected => 'selected') { item.send(text_method) }
        else
          option(:value => item.send(value_method)) { item.send(text_method) }
        end
      end
    end
    
  end



end

def Broadcatcher.create
  Camping::Models::Session.create_schema
  Broadcatcher::Models.create_schema :assume => (Broadcatcher::Models::Pass.table_exists? ? 1.0 : 0.0)
end




if __FILE__ == $0
  require 'mongrel/camping'

  Broadcatcher::Models::Base.establish_connection :adapter => 'sqlite3', :dbfile => 'broadcatcher.db'
  Broadcatcher::Models::Base.logger = Logger.new('broadcatcher.log')
  Broadcatcher::Models::Base.threaded_connections = false
  Broadcatcher.create 

  server = Mongrel::Camping::start("127.0.0.1",3301,"/", Broadcatcher)
  puts "Broadcatcher is running at http://127.0.0.:3301/"
  server.run.join
end



