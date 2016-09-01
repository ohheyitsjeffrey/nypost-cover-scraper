module NYpostGrabber

  require 'mechanize'
  require 'active_support'
  require 'active_support/dependencies/autoload' 
  require 'active_support/core_ext'
  require 'pathname'
  require 'date'

  def self.get_new_covers(directory = nil)

    if directory == nil || !File.directory?(directory)
      raise NeedsDirectoryError
    end

    if directory.last != '/'
      directory = directory + "/"
    end

    url = 'http://nypost.com/covers/'  
    agent = Mechanize.new
    agent.user_agent_alias = 'Mac Safari' # its a mac brah
    page  = agent.get url 
    # TODO find a way to make this simpler if possible as it feels sloppy
    url = page.parser.css('#primary > div > div.featured-covers > article:nth-child(1) > div.entry-thumbnail-wrapper > a')
    url = Hash.from_xml(url.to_xml)['a']['href']
    page        = agent.get url
    end_date    = Date.parse('1-1-2002') #last archived covers
    next_page   = ""

    while true
      begin 
        next_page, last_date = get_cover page, agent, directory = directory
        next_date = last_date.prev_day.strftime('%Y-%m-%d')

        page = agent.get next_page 
        # return false if next page is before the last archived day. 
        if File.exists?("#{directory}#{next_date}-front-cover.jpg") && File.exists?("#{directory}#{next_date}-back-cover.jpg") 
          puts "up to date"
          return false
        end
      rescue ArgumentError
        # exit on issues for debugging to avoid infinite loops
        puts "The module Date is throwing a fit for the url  #{next_page}.  Check to make sure those files downloaded."
      end
    end
  end

  def self.get_all_covers(directory = nil)

    if directory == nil || !File.directory?(directory)
      raise NeedsDirectoryError
    end

    if directory.last != '/'
      directory = directory + "/"
    end

    url = 'http://nypost.com/covers/'  
    agent = Mechanize.new
    agent.user_agent_alias = 'Mac Safari' # its a mac brah
    page  = agent.get url 
    # TODO find a way to make this simpler if possible as it feels sloppy
    url = page.parser.css('#primary > div > div.featured-covers > article:nth-child(1) > div.entry-thumbnail-wrapper > a')
    url = Hash.from_xml(url.to_xml)['a']['href']
    page      = agent.get url
    end_date  = Date.parse('1-1-2002') #last archived covers
    next_page = ""

    while true
      begin 
        next_page, last_date = get_cover page, agent, directory = directory
        page  = agent.get next_page 
        # return false if next page is before the last archived day. 
        if last_date == end_date 
          puts "Reached last archived cover on #{end_date}"
          return false
        end
      rescue ArgumentError
        # exit on issues for debugging to avoid infinite loops
        puts "The module Date is throwing a fit for the url  #{next_page}.  Check to make sure those files downloaded."
      end
    end

  end


  def self.get_cover(page, agent, directory = nil)

    date        = Date.parse(page.search('div.title-area-wrapper > div.cover-date-wrapper.desktop > h2').text) 
    date_string = date.strftime('%Y-%m-%d')  
    yesterday   = Hash.from_xml(page.parser.css('header > div.cover-controls-wrapper > div > a.next').to_xml)['a']['href']
    front_src   = Hash.from_xml(page.css('picture.entry-thumbnail.front > source:nth-child(1)').to_xml)['source']['srcset']
    back_src    = Hash.from_xml(page.css('picture.entry-thumbnail.back > source:nth-child(1)').to_xml)['source']['srcset']
    file_path   = Pathname.new(directory)

    if !File.exists?("#{directory}#{date}-front-cover.jpg") && !File.exists?("#{directory}#{date}-back-cover.jpg") 
      puts "Downloading covers for #{date_string}"
      #download front cover
      agent.get(front_src).save "#{directory}#{date}-front-cover.jpg"
      #download back cover
      agent.get(back_src).save "#{directory}#{date}-back-cover.jpg"
    else
      puts "skipping covers for #{date_string} as they already exists"
    end
    return yesterday, date
  end

end

# Throws error if no directory is specified.

class NeedsDirectoryError < StandardError
  def initialize(msg="No directory passed - please specify a directory for the covers.  If you included a directory, make sure it is typed correctly.")
    super
  end
end
