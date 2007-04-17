#!/usr/bin/env ruby
#
#  Created by Jon Maddox on 2007-04-10.
#  Copyright (c) 2007. All rights reserved.

require 'rubygems'
require 'active_record'
require 'net/http'
require 'hpricot'
require 'open-uri'
require 'uri'
require 'logger'


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


# download the nzb with the DNZB feature - http://docs.newzbin.com/index.php/Newzbin:DirectNZB
def download_nzb(report_id, filename = report_id )
  response = Net::HTTP.post_form(URI.parse('http://v3.newzbin.com/dnzb/'),
                            {'username'=> CONFIG["newzbin_username"], 'password'=> CONFIG["newzbin_password"], 'reportid' => report_id})
  case response
  when Net::HTTPSuccess
    File.new("#{CONFIG["download_directory"]}/#{filename}.nzb", 'w').puts(response.body)  
  end
    
  response
end

def find_report(doc)
  title = doc.search('td.title/a').first.innerHTML
  report_id = doc.search('td.title/a').first.attributes['href'].split('/')[3]
  LOGGER.info "Found #{title} at #{report_id} "

  {:title => title, :report_id => report_id}
end

LOGGER = Logger.new(File.join(File.dirname(__FILE__), 'catcher.log'), 10, 1024000)

# suck in user configuration preferences
CONFIG = {}
Setting.find(:all).each{ |setting| CONFIG[setting.key] = setting.value}

FILE_SIZE = {:larger_than => 105, :smaller_than => 250}

# set up season passes
passes = Pass.find(:all)
LOGGER.info ""
LOGGER.info ""
LOGGER.info "Starting Search " + DateTime.now.to_s

#lets look for the newest episode for each
until passes.size == 0
  pass = passes.pop
  
  puts "Looking for #{pass.title} - #{pass.season}x#{pass.next_episode.massage} in #{pass.quality.title} quality"
  found = false
  
  # figure out what size file we're looking for
  larger_than = FILE_SIZE[:larger_than] * pass.length.multiple * pass.quality.multiple
  smaller_than = FILE_SIZE[:smaller_than] * pass.length.multiple * pass.quality.multiple
  
  # get the search results
  doc = Hpricot(open("http://v3.newzbin.com/search?q=%5E%22#{pass.title.to_s.gsub(/ /, '+')}+-+#{pass.season}x#{pass.next_episode.massage}%22&searchaction=Search&fpn=p&group=alt.binaries.multimedia&emu_subcat=-1&u_post_larger_than=#{larger_than}&u_post_smaller_than=#{smaller_than}&u_nfo_posts_only=0&u_url_posts_only=0&u_comment_posts_only=0&u_v3_retention=5184000&sort=ps_edit_date&order=desc&emu_subcat_done=-1"))
  results = doc.search("//table[@summary='Post query results']")
  
  # loop through the results
  (results/'tr').each do |tr|
    
    if tr.innerHTML.match(%r{#{pass.quality.regex}})
      report = find_report(tr) 
      response = download_nzb(report[:report_id], "#{report[:title]}")
      found = true
      case response["x-dnzb-rcode"].to_i
      when 200
        puts "NZB downloaded OK"
        pass.update_attributes(:next_episode => pass.next_episode.to_i + 1) 
      when 450
        puts "pushing pass back onto stack"
        passes.push pass
        puts "sleeping for 60 seconds to be nice to newzbin"
        sleep(60)
      else 
        puts "ERROR #{response["x-dnzb-rcode"]}: #{response["x-dnzb-rtext"]}"
      end
      
      break
    end
    
  end
  puts "not found" unless found
    
end



LOGGER.info "Finished with search"
