# This is a template for a Ruby scraper on morph.io (https://morph.io)
# including some code snippets below that you should find helpful

require 'scraperwiki'
require 'pry'
require 'csv'

# This is the CSV export URL for the spreadsheet provided by the fine folks at  dlgc.wa.gov.au:
# https://docs.google.com/spreadsheets/d/1J1SShMPYBuGVAHY7LfDiTiHV72Tph8ObxbhlCoo7nn8/edit#gid=1431929499
def google_sheets_export_url
  "https://docs.google.com/spreadsheets/d/1J1SShMPYBuGVAHY7LfDiTiHV72Tph8ObxbhlCoo7nn8/export?format=csv&id=1J1SShMPYBuGVAHY7LfDiTiHV72Tph8ObxbhlCoo7nn8&gid=1431929499"
end

def parse_name(text)
  text.sub(/\((M|F)\)$/, "").strip.split(", ").reverse.join(" ").strip
end

# Remove councillor whatnot
def simplify_name(text)
  text.gsub!(/[[:space:]]/, " ")
  text.strip!
  if text.start_with?("Cr", "Ald")
    text.sub(/^(Cr|Ald)\W/, "")
  else
    text
  end
end

def create_id(council, name)
  components = council + "/" + name
  components.downcase.gsub(" ","_")
end

CSV.parse(open(google_sheets_export_url).read)[1..-1].each do |row|
  name = parse_name(row[2])

  council = row.first + " Council"

  gender = if row[2].end_with? "(F)"
    "female"
  elsif row[2].end_with? "(M)"
    "male"
  else
    nil
  end

  p councillor = {
    name: name,
    executive: row[1] =~ /(mayor){1}/i ? "Mayor" : nil,
    council: council,
    ward: row[1],
    id: create_id(council, name),
    gender: gender
  }

  ScraperWiki.save_sqlite([:id], councillor)
end
