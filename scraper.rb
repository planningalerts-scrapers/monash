require 'scraperwiki'
require 'mechanize'

agent = Mechanize.new

def scrape_page(page, url)
  table = page.at("table.ContentPanel")
  
  table.search("tr")[1..-1].each do |tr|
    day, month, year = tr.search("td")[3].inner_text.split("/").map{|s| s.to_i}
    
    record = {
      "info_url" => url,
      "comment_url" => url,
      "council_reference" => tr.at("td a").inner_text,
      "address" => tr.search("td")[1].inner_text,
      "description" => tr.search("td")[2].inner_text,
      "date_received" => Date.new(year, month, day).to_s,
      "date_scraped" => Date.today.to_s
    }
    
    # Check if record already exists
    if (ScraperWiki.select("* from data where `council_reference`='#{record['council_reference']}'").empty? rescue true)
      ScraperWiki.save_sqlite(['council_reference'], record)
    else
      puts "Skipping already saved record " + record['council_reference']
    end
  end
end

# Load summary page.
url = "https://epathway.monash.vic.gov.au/ePathway/Production/Web/GeneralEnquiry/EnquiryLists.aspx?ModuleCode=LAP"
page = agent.get(url)

# Now do the paging magic
number_pages =  page.at("#ctl00_MainBodyContent_mPagingControl_pageNumberLabel").inner_text.split(" ")[3].to_i

(1..number_pages).each do |no|
  url = "https://epathway.monash.vic.gov.au/ePathway/Production/Web/GeneralEnquiry/EnquirySummaryView.aspx?PageNumber=#{no}"
  page = agent.get(url)
  puts "Scraping page #{no} of " + number_pages.to_s + "..."
  scrape_page(page, url)
end
