#!/usr/bin/env ruby
#
#  Created by Jon Maddox on 2007-04-10.
#  Copyright (c) 2007. All rights reserved.

require 'rubygems'
require 'active_record'
require File.dirname(__FILE__) + '/newzbin.rb'


ActiveRecord::Base.establish_connection( 
  :adapter => "sqlite3", 
  :dbfile => File.join(File.dirname(__FILE__), 'broadcatcher.db')
) 

# models
class Pass < ActiveRecord::Base
  belongs_to :quality
  belongs_to :length
  set_table_name 'broadcatcher_passes'
end 
class Setting < ActiveRecord::Base
  set_table_name 'broadcatcher_settings'
end 
class Quality < ActiveRecord::Base
  has_many :passes
  set_table_name 'broadcatcher_qualities'
end 
class Length < ActiveRecord::Base
  has_many :passes
  set_table_name 'broadcatcher_lengths'
end

class Fixnum
  def massage
    self < 10 ? "0#{self}" : self 
  end
end


# suck in user configuration preferences
CONFIG = {}
Setting.find(:all).each{ |setting| CONFIG[setting.key] = setting.value}

# set up season passes
passes = Pass.find(:all)

# get instance of newzbin library
newzbin = Newzbin::Connection.new(CONFIG["newzbin_username"], CONFIG["newzbin_password"])

FILE_SIZE = {:larger_than => 105, :smaller_than => 250}



#lets look for the newest episode for each
until passes.size == 0
  pass = passes.pop

  puts "#{pass.title} - #{pass.season}x#{pass.next_episode.massage} in #{pass.quality.title} quality"

  case pass.quality.title
  when "720p"
    options = {:category =>8, :ps_rb_video_format => 131072}
    
  when /hrhd|hdtv/ss
    larger_than = FILE_SIZE[:larger_than] * pass.length.multiple * pass.quality.multiple
    smaller_than = FILE_SIZE[:smaller_than] * pass.length.multiple * pass.quality.multiple
    
    options = {:category => 8, :u_post_larger_than=> larger_than, :u_post_smaller_than => smaller_than, :ps_rb_video_format => 16}
  end
  
  nzbs = newzbin.search(options.merge(:q => "#{pass.title.to_s} - #{pass.season}x#{pass.next_episode.massage}"))
  puts "#{nzbs.size} Found"  
  
  if nzbs.size > 0
    nzb = nzbs.first
    response = newzbin.get_nzb(nzb.id)

    # download_nzb(report[:report_id], "#{report[:title]}")
    found = true
    case response["x-dnzb-rcode"].to_i
    when 200
      puts "NZB downloaded OK"
      File.new("#{CONFIG["download_directory"]}/#{nzb.title}.nzb", 'w').puts(response.body)  
      pass.update_attributes(:next_episode => pass.next_episode.to_i + 1) 
    when 450
      puts "pushing pass back onto stack"
      passes.push pass
      puts "sleeping for 60 seconds to be nice to newzbin"
      sleep(60)
    else 
      puts "ERROR #{response["x-dnzb-rcode"]}: #{response["x-dnzb-rtext"]}"
    end
  end
  puts
end
