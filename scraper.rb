require 'scraperwiki'
require 'mechanize'

agent = Mechanize.new

def scrape_page(page)
  table = page.at("table.ContentPanel")
  
  table.search("tr")[1..-1].each do |tr|
    day, month, year = tr.search("td")[3].inner_text.split("/").map{|s| s.to_i}
    default_url = "https://epathway.monash.vic.gov.au/ePathway/Production/Web/GeneralEnquiry/EnquiryLists.aspx?ModuleCode=LAP"
    
    record = {
      "info_url" => default_url,
      "comment_url" => default_url,
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

base_url = "https://epathway.monash.vic.gov.au/ePathway/Production/Web/GeneralEnquiry/"
entry_form_url_ext = "/EnquiryLists.aspx?ModuleCode=LAP"
first_page_url = base_url + entry_form_url_ext

# Get first page with radio buttons.
page = agent.get(first_page_url)
form = page.forms.first
form.radiobuttons[0].check
page = form.submit(form.button_with(:value => "Next"))

# Now do the paging magic
number_pages =  page.at("#ctl00_MainBodyContent_mPagingControl_pageNumberLabel").inner_text.split(" ")[3].to_i

(1..number_pages).each do |no|
  url = "https://epathway.monash.vic.gov.au/ePathway/Production/Web/GeneralEnquiry/EnquirySummaryView.aspx?PageNumber=#{no}"
  page = agent.get(url)
  puts "Scraping page #{no} of " + number_pages.to_s + "..."
  scrape_page(page)
end