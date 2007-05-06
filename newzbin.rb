####### Newzbin API
### http://v3.newzbin.com

# open a new newzbin connection, and search it with the method provided. Pass it vars to narrow the search
# Download the nzb using the provided get_nzb method
#
# newz = Newzbin::Connection.new('username', 'password')
# nzbs = newz.search(:q => 'casino royale', :ps_rb_video_format => 131072)
#
# puts nzbs.inspect
# 
# newz.get_nzb(nzbs.first.id)



require 'rubygems'
require 'net/http'
require 'cgi'
require 'xmlsimple'

module Newzbin
  
  class Connection

    def initialize(username=nil, password=nil)
      @host = 'http://v3.newzbin.com'
      @search = '/search/query'
      @dnzb = '/dnzb/'
      @username = username
      @password = password
    end

    def http_get(url)
      Net::HTTP.get_response(URI.parse(url)).body.to_s
    end

    def request_url(params)
      params.delete_if {|key, value| (value == nil || value == '') }
      
      url = "#{@host}#{@search}?searchaction=Search&fpn=p&feed=rss"
      params.each_key do |key| url += "&#{key}=" + CGI::escape(params[key].to_s) end if params
      url
    end

    def search(params)
      nzbs = []
      response = XmlSimple.xml_in(http_get(request_url(params)), { 'ForceArray' => false })
      
      case response["channel"]["item"].class.name
      when "Array"
        response["channel"]["item"].each { |item| nzbs << Nzb.new(item)}
      when "Hash"
        nzbs << Nzb.new(response["channel"]["item"])
      end
      
      nzbs

    end

    def get_nzb(id)
      Net::HTTP.post_form(URI.parse("#{@host}#{@dnzb}"),{:username => @username, :password => @password, :reportid => id})

      # responses
      # x-dnzb-rcode, x-dnzb-rtext
      # 200, ok
      # 450, 5 nzbs per minute please
      # else, else
    end
  end
  
  

  class Nzb
    attr_accessor :pub_date, :size_in_bytes, :category, :title, :id

    def initialize(details)
      @pub_date = details["pubDate"]
      @size_in_bytes = details["size"]["content"]
      @category = details["category"]
      @title = details["title"]
      @id = details["id"]
    end
  end
    
end
