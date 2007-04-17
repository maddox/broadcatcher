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


  class Style < R '/styles.css'
    def get
      @headers["Content-Type"] = "text/css; charset=utf-8"
        @body = %{

          /* Main Tags */

          body {
          	font-size: 62.5%; /* Resets 1em to 10px */
          	font-family: 'Lucida Grande', Verdana, Arial, Sans-Serif;
          	background-color: #9da08f;
          	color: #333;
          	margin: 0;
          	}


          a{
            color: #fbd819;
            text-decoration: none;
          }

          a:hover{
            color: #fa5c4b;
          }

          table {
          	margin:				0;
          	width:				100%;
          	border:				none;
          	border-collapse:	collapse;
          	font-size:			1em;
          	}

          	table td {
          	padding:			0;
          	}

          	table th {
          	text-align:			left;
          	}


          /* Structure */

          #wrapper{

          }

          #header{
            background-color: #000;
            padding: .5em;
            border-bottom: 4px solid #4c4c4c;
            margin-bottom: 2em;
            }
            #header h1{
              color: #fbd819;
              margin: 0;
              font-size: 2.4em;
              margin-left: 1em;
            }
            #header h1 a{
              font-weight: normal;
            	border: 0;
            	text-decoration: none;
            }
            #header ul{
              display: inline;
            	list-style: none;
            	padding: 0;
            	margin: 0;
            	margin-top: 0.9em;
            	float: right;
            }
            	#header ul li{
            		padding: 0;
            		margin: 0;
            	  margin-right: 1em;
            	  float: left;

            	}
            	#header ul li a{
            	  display: block;
            	}


          #content{
            padding: 0 20px;
            font-size: 14px;

          }
          
          

          ul#nav{
            margin: auto;
            list-style: none;
            text-align: center;
          }
            ul#nav li{
              width: 300px;
              margin: auto;
              border: 3px #000000 solid;
              margin-bottom: 5px;
            }
            ul#nav li a{
              color: #0f0f0f;
              background-color: #8e9e9f;
              padding: 10px;
              font-size: 20px;
              display: block;
            }
            ul#nav li a:hover{
              background-color: #818f91;
            }
            
            
            .data_table {
            	margin:				0 0 1em 0;
            	font-size: 16px;
            	}

            .data_table th,
            .data_table td {
            	padding:			3px 10px;
            	}

            .data_table th {
            	color:				#fff;
            	background-color:			#58564f;
            	}

            .data_table th:last-child {
            	background-color: 		#58564f;
            }

            .data_table td {
            	background:			#fff;
            	border-bottom:		#ccb 1px solid;
            	}

            	.data_table tr:last-child td {
            	border-bottom:		none;
            	}

            	.data_table tr.alt td {
            	background:			#eee;
            	}

            .data_table .totals th,
            .data_table .totals td {
            	border-top:			#d6d5c7 1px solid;
            	border-left:		#d6d5c7 1px solid;
            	color:				#fff;
            	text-align:			right;
            	background:			#332;
            	}


            	.data_table tr td.empty,
            	.data_table tr.totals td.empty  {
            	border: 			none;
            	background:			transparent;
            	}

            	.data_table tr td{
            		vertical-align: middle;
            	}
              
              .data_table td a{
                color: #58564f;
              }


          /* Various Helper Classes */

          .alignright {
          	float: right;
          	}

          .centered {
          	text-align: center;
          	}

          .alignleft {
          	float: left
          	}

          img.centered {
          	display: block;
          	margin-left: auto;
          	margin-right: auto;
          	}

          img.spaced {
          	padding: 4px;
          	margin: 4px;
          	}

          img.alignright {
          	padding: 4px;
          	margin: 0 0 2px 7px;
          	display: inline;
          	}

          img.alignleft {
          	padding: 4px;
          	margin: 0 7px 2px 0;
          	display: inline;
          	}

          .clearfix:after {
            content: "."; 
            display: block; 
            height: 0; 
            clear: both; 
            visibility: hidden;
          }

          /* Typography & Colors */

          .red{
          	color: #fbd819;
          }


          input.long{
            width: 80%;
          }

          input.medium{
            width: 25em;
          }
          
          input.small{
            width: 5em;
          }


          input.large{
            font-size: 2em;
          }



        }
    end
  end

  # The root slash shows the `index' view.
  class Index < R '/'
    def get
      render :index 
    end
  end

  # The root slash shows the `index' view.
  class List < R '/list'
    def get
      @passes = Pass.find(:all) 
      render :list 
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
      pass = Pass.create(input)
      redirect List
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
      pass = pass.update_attributes(input)

      redirect List
    end

  end
  

  class Delete < R '/delete/(\d+)'
    def get pass_id
      @pass = Pass.find(pass_id)
      @pass.destroy
      
      redirect List
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
      head do
        title "TV Station" 
        link :rel => 'stylesheet', :type => 'text/css', :href => '/styles.css', :media => 'all'
      end
      body do
        div(:id => 'header', :class => 'clearfix') do 
          _sub_nav
          h1 {a 'TV Station', :href => R(Index) }
        end
        div(:id => 'content') do
          self << yield
        end
      end 
    end
  end

  # The `index' view.  Inside your views, you express
  # the HTML in Ruby.  See http://code.whytheluckystiff.net/markaby/.
  def index
    _nav
  end

  def list
    p { a 'New Season Pass', :href => R(Add) }
    table(:class => 'data_table') do
      tr do
        th 'Show'
        th 'Duration'
        th 'Quality'
        th 'Next Episode'
        th 'Manage'
      end
      @passes.each do |pass|
        tr do
          td {a(:href => R(Show, pass)){ pass.title}}
          td pass.length.title
          td pass.quality.title
          td pass.next_episode
          td {a(:href => R(Edit, pass)){'Edit'} + " / " + a(:href => R(Delete, pass)){'Delete'} }
        end
      end
    end
    
    
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
      p do
        label 'Download Directory', :for => 'setting_download_directory'; br
        input :name => 'setting_download_directory', :type => 'text', :value => @settings["download_directory"]; br
      end

      p do
        label 'Newzbin Username', :for => 'setting_newzbin_username'; br
        input :name => 'setting_newzbin_username', :type => 'text', :value => @settings["newzbin_username"]; br
      end

      p do
        label 'Newzbin Password', :for => 'setting_newzbin_password'; br
        input :name => 'setting_newzbin_password', :type => 'password', :value => @settings["newzbin_password"]; br
      end

      p do
        input( :type => 'submit', :value => 'Save Changes') + " or " + a(:href => R(Index)){'cancel'}
      end
    end
  end
  
  # partials
  
  def _sub_nav
    ul do
      li { a 'Settings', :href => R(Settings)}
    end
  end


  def _nav
    ul(:id => 'nav') do
      li { a 'Season Passes', :href => R(List)}
      li { a 'To Do', :href => R(Todo)}
      li { a 'Run Scan', :href => R(Run)}
      li { a 'Settings', :href => R(Settings)}
    end
  end
  
  def _form
    form({:method => 'post'}) do
      p do
        label 'Title', :for => 'title'; br
        input :name => 'title', :type => 'text', :value => pass.title; br
      end

      p do
        label 'Season', :for => 'season'; br
        input :name => 'season', :class => 'small', :type => 'text', :value => pass.season;
      end

      p do
        label 'Length', :for => 'length_id'; br
        collection_select(pass, 'length_id', @lengths, 'id', 'title')
      end

      p do
        label 'Quality', :for => 'quality_id'; br
        collection_select(pass, 'quality_id', @qualities, 'id', 'title')
      end

      p do
        label 'Next Episode', :for => 'next_episode'; br
        input :name => 'next_episode', :class => 'small', :type => 'text', :value => pass.next_episode; br
      end

      p do
        if @pass.new_record?
          input(:type => 'submit', :value => 'Create Season Pass') + " or " + a(:href => R(List)){'cancel'}
        else
          input(:type => 'submit', :value => 'Save Changes') + " or " + a(:href => R(List)){'cancel'}
        end
        
      end
    end
    
  end
  
  # helpers
  
  def collection_select(object, method, collection, value_method, text_method)
    select :name => "#{method}" do
      collection.each do |item|
        if item.send(value_method) == object.send(method)
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



