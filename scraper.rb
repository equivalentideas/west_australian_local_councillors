# This is a template for a Ruby scraper on morph.io (https://morph.io)
# including some code snippets below that you should find helpful

require 'scraperwiki'
require 'mechanize'

# Remove councillor whatnot
def simplify_name(text)
  if text.split(" ").first =~ /(Cr|Ald|Mr)/
    text.split(" ")[1..-1].join(" ")
  else
    text
  end
end

def create_id(council, name)
  components = council + "/" + name
  components.downcase.gsub(" ","_")
end

def scrape_council_page(page)
  council = page.at(:h1).text + " Council"
  puts "Scraping councillors for #{council}"

  council_data_keys = page.at("h1 + div").search(:strong)
  council_email = council_data_keys.select {|key| key.text.include? "Email:" }[0].next_sibling.text
  council_website = council_data_keys.select {|key| key.text.include? "site:" }[0].next_sibling[:href]

  mayor_name = simplify_name(council_data_keys.select {|key| key.text.include? "Mayor:" }[0].next_sibling.text)
  deputy_mayor_name = simplify_name(council_data_keys.select {|key| key.text.include? "Deputy" }[0].next_sibling.text)

  councillor_table = page.at(:table)
  councillors = councillor_table.search(:tr)[1..-1]
  councillors.each do |councillor_element|
    name = simplify_name(councillor_element.at(:td).text)

    executive = ""
    if name.eql? mayor_name
      executive = "Mayor"
    elsif name.eql? deputy_mayor_name
      executive = "Deputy Mayor"
    end

    p councillor = {
      name: name,
      executive: executive,
      council: council,
      council_website: council_website,
      id: create_id(council, name),
      council_email: council_email,
      term_ends: councillor_element.search(:td).last.text
    }

    ScraperWiki.save_sqlite([:id], councillor)
  end
end

agent = Mechanize.new
index_page = agent.get("http://www.dpac.tas.gov.au/divisions/local_government/local_government_directory/councils")
index_page.at(:table).search(:a).each do |a|
  scrape_council_page(agent.get(a[:href]))
end
