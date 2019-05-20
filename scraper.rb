require "epathway_scraper"

scraper = EpathwayScraper::Scraper.new(
  "https://epathway.monash.vic.gov.au/ePathway/Production"
)

scraper.scrape(list_type: :advertising, with_gets: true) do |record|
  EpathwayScraper.save(record)
end
