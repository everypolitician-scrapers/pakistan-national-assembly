#!/bin/env ruby
# encoding: utf-8

require 'scraperwiki'
require 'nokogiri'
require 'date'
require 'open-uri'

# require 'colorize'
require 'pry'
# require 'open-uri/cached'
# OpenURI::Cache.cache_path = '.cache'
require 'scraped_page_archive/open-uri'

class String
  def tidy
    self.gsub(/[[:space:]]+/, ' ').strip
  end
end

def noko_for(url)
  Nokogiri::HTML(open(url).read)
end

def datefrom(date)
  Date.parse(date).to_s
end

def cell(profile, th)
  td = profile.at_xpath(".//th[contains(.,'#{th}')]/following::td") or return ''
  td.text.tidy
end

def scrape_list(page)
  noko = noko_for(page)
  noko.css('table.mytable12 a[href*="profile.php"]/@href').map(&:text).uniq.each do |url|
    scrape_mp(URI.join page, url)
  end
end

def scrape_mp(page)
 noko = noko_for(page)
 profile = noko.css('table.profile_tbl')

 data = {
   id: page.to_s[/uid=(\d+)/, 1],
   name: cell(profile, "Name"),
   patronymic_name: cell(profile, "Father"),
   address: cell(profile, "Permanent Address"),
   phone: cell(profile, "Contact Number").gsub(',', ';'),
   constituency: cell(profile, "Constituency").gsub(/(?<!\s)\(/, ' ('),
   province: cell(profile, "Province"),
   party: cell(profile, "Party"),
   start_date: datefrom(cell(profile, "Oath Taking Date")),
   image: profile.css('img/@src'),
   term: 14,
   source: page.to_s,
 }
 data[:party_id] = data[:party].gsub(/\W+/,'').downcase
 data[:image] &&= URI.join(page, data[:image].text.gsub(' ','%20s')).to_s
 if data[:name].match(/^Mr[ \.] ?/)
   data[:name].sub!(/^Mr[ \.] ?/,'')
   data[:gender] = "male"
 elsif data[:name].match(/^Mr?s[ \.] ?/)
   data[:name].sub!(/^Mr?s[ \.] ?/,'')
   data[:gender] = "female"
 elsif data[:name].match(/^Miss /)
   data[:name].sub!(/^Miss /,'')
   data[:gender] = "female"
 end
 ScraperWiki.save_sqlite([:id, :term], data)
end

scrape_list('http://www.na.gov.pk/en/all_members.php')
