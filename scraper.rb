require "epathway_scraper"

scraper = EpathwayScraper::Scraper.new(
  "https://epathway.monash.vic.gov.au/ePathway/Production"
)

agent = scraper.agent

base_url = "https://epathway.monash.vic.gov.au/ePathway/Production/Web/GeneralEnquiry/"

page = scraper.pick_type_of_search(:advertising)

# Now do the paging magic
number_pages = scraper.extract_total_number_of_pages(page)

(1..number_pages).each do |no|
  results_page_url = base_url + "EnquirySummaryView.aspx?PageNumber=#{no}"
  page = agent.get(results_page_url)
  puts "Scraping page #{no} of " + number_pages.to_s + "..."
  scraper.scrape_index_page(page) do |record|
    EpathwayScraper.save(record)
  end
end
