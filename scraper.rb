#!/bin/env ruby
# encoding: utf-8

require 'scraperwiki'
require 'nokogiri'
require 'date'
require 'open-uri'

require 'colorize'
require 'pry'
require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

def noko_for(url)
  Nokogiri::HTML(open(url).read) 
end

def datefrom(date)
  Date.parse(date).to_s
end

def cell(profile, th)
  td = profile.at_xpath(".//th[contains(.,'#{th}')]/following::td") or return
  td.text.strip
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

 binding.pry
 data = { 
   # id: '2010-' + tds[0].text.strip,
   name: cell(profile, "Name"),
   patronymic_name: cell(profile, "Father"),
   address: cell(profile, "Permanent Address"),
   phone: cell(profile, "Contact Number"),
   constituency: cell(profile, "Constituency"),
   province: cell(profile, "Province"),
   party: cell(profile, "Party"),
   start_date: datefrom(cell(profile, "Oath Taking Date")),
   # image: profile.css('img/@src').text,
   term: 14,
   source: page,
 }
 data[:party_id] = data[:party].gsub(/\W+/,'').downcase
 puts data[:party_id] + "|" + data[:party]
 # ScraperWiki.save_sqlite([:id, :term], data)
end

term = {
  id: 14,
  name: '14th National Assembly',
  start_date: '2013-06-01',
  source: 'https://en.wikipedia.org/w/index.php?title=National_Assembly_of_Pakistan&oldid=663314574',
}
ScraperWiki.save_sqlite([:id], term, 'terms')

scrape_list('http://www.na.gov.pk/en/all_members.php')

