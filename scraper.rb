require "epathway_scraper"

scraper = EpathwayScraper.scrape_and_save(
  "https://epathway.monash.vic.gov.au/ePathway/Production",
  list_type: :advertising
)
