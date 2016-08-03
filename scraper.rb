require 'scraperwiki'
require 'mechanize'

agent = Mechanize.new

def scrape_page(page)
  table = page.at("table.ContentPanel")
  tr_elems = table.search("tr")

  tr_elems.each_with_index do |tr, index|
    next if index == 0 #Skipping the first beacause it's got <th> not <td>

    this_application_details = tr.css('td a')[0].attributes['href']
    this_application_link = base_url + this_application_details.to_s

    day, month, year = tr.search("td")[3].inner_text.split("/").map{|s| s.to_i}

    record = {
      "info_url" => this_application_link,
      "comment_url" => 'mailto:mail@monash.vic.gov.au',
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
  result_page_extension = "/EnquirySummaryView.aspx?PageNumber=#{no}"
  results_page_url = base_url + result_page_extension
  page = agent.get(results_page_url)
  puts "Scraping page #{no} of " + number_pages.to_s + "..."
  scrape_page(page, base_url)
end