class AddRegion < ActiveRecord::Migration
  def change
    create_table :extension_regions do |t|
      t.string     "shortname"
      t.string     "label"
      t.string     "association_url"
      t.timestamps
    end

    create_table :institutional_regions do |t|
      t.integer    "extension_region_id"
      t.integer    "institution_id"
      t.datetime   "created_at"
    end

    add_index "institutional_regions", ["extension_region_id", "institution_id"], :name => 'region_ndx', :unique => true


    # seed regions
    ExtensionRegion.reset_column_information
    ExtensionRegion.create(shortname: '1890', label: '1890', association_url: 'http://1890aea.org/')
    ExtensionRegion.create(shortname: 'northcentral', label: 'North Central', association_url: 'http://www.nccea.org/')
    ExtensionRegion.create(shortname: 'northeast', label: 'Northeast', association_url: 'http://northeastextension.org/')
    ExtensionRegion.create(shortname: 'southern', label: 'Southern', association_url: 'http://asred.msstate.edu/')
    ExtensionRegion.create(shortname: 'western', label: 'Western', association_url: 'http://extension.oregonstate.edu/weda/')

    # associate institutions
    execute "INSERT INTO institutional_regions (extension_region_id,institution_id,created_at) SELECT 1,241,NOW()" # Alabama A & M University
    execute "INSERT INTO institutional_regions (extension_region_id,institution_id,created_at) SELECT 1,273,NOW()" # Alcorn State University
    execute "INSERT INTO institutional_regions (extension_region_id,institution_id,created_at) SELECT 4,242,NOW()" # Auburn University
    execute "INSERT INTO institutional_regions (extension_region_id,institution_id,created_at) SELECT 4,293,NOW()" # Clemson University
    execute "INSERT INTO institutional_regions (extension_region_id,institution_id,created_at) SELECT 5,312,NOW()" # College of Micronesia
    execute "INSERT INTO institutional_regions (extension_region_id,institution_id,created_at) SELECT 5,248,NOW()" # Colorado State University
    execute "INSERT INTO institutional_regions (extension_region_id,institution_id,created_at) SELECT 2,298,NOW()" # Cooperative Extension Program at Prairie View
    execute "INSERT INTO institutional_regions (extension_region_id,institution_id,created_at) SELECT 3,283,NOW()" # Cornell University
    execute "INSERT INTO institutional_regions (extension_region_id,institution_id,created_at) SELECT 1,251,NOW()" # Delaware State University
    execute "INSERT INTO institutional_regions (extension_region_id,institution_id,created_at) SELECT 1,253,NOW()" # Florida A & M University
    execute "INSERT INTO institutional_regions (extension_region_id,institution_id,created_at) SELECT 1,255,NOW()" # Fort Valley State University
    execute "INSERT INTO institutional_regions (extension_region_id,institution_id,created_at) SELECT 2,261,NOW()" # Iowa State University
    execute "INSERT INTO institutional_regions (extension_region_id,institution_id,created_at) SELECT 2,262,NOW()" # Kansas State University
    execute "INSERT INTO institutional_regions (extension_region_id,institution_id,created_at) SELECT 1,263,NOW()" # Kentucky State University
    execute "INSERT INTO institutional_regions (extension_region_id,institution_id,created_at) SELECT 1,288,NOW()" # Langston University
    execute "INSERT INTO institutional_regions (extension_region_id,institution_id,created_at) SELECT 1,275,NOW()" # Lincoln University of Missouri
    execute "INSERT INTO institutional_regions (extension_region_id,institution_id,created_at) SELECT 4,265,NOW()" # Louisiana State University
    execute "INSERT INTO institutional_regions (extension_region_id,institution_id,created_at) SELECT 2,271,NOW()" # Michigan State University
    execute "INSERT INTO institutional_regions (extension_region_id,institution_id,created_at) SELECT 4,274,NOW()" # Mississippi State University
    execute "INSERT INTO institutional_regions (extension_region_id,institution_id,created_at) SELECT 5,277,NOW()" # Montana State University
    execute "INSERT INTO institutional_regions (extension_region_id,institution_id,created_at) SELECT 5,282,NOW()" # New Mexico State University
    execute "INSERT INTO institutional_regions (extension_region_id,institution_id,created_at) SELECT 1,284,NOW()" # North Carolina A & T State University
    execute "INSERT INTO institutional_regions (extension_region_id,institution_id,created_at) SELECT 4,285,NOW()" # North Carolina State University
    execute "INSERT INTO institutional_regions (extension_region_id,institution_id,created_at) SELECT 2,286,NOW()" # North Dakota State University
    execute "INSERT INTO institutional_regions (extension_region_id,institution_id,created_at) SELECT 4,289,NOW()" # Oklahoma State University
    execute "INSERT INTO institutional_regions (extension_region_id,institution_id,created_at) SELECT 5,290,NOW()" # Oregon State University
    execute "INSERT INTO institutional_regions (extension_region_id,institution_id,created_at) SELECT 3,291,NOW()" # Pennsylvania State University
    execute "INSERT INTO institutional_regions (extension_region_id,institution_id,created_at) SELECT 2,260,NOW()" # Purdue University
    execute "INSERT INTO institutional_regions (extension_region_id,institution_id,created_at) SELECT 3,281,NOW()" # "Rutgers, State University of New Jersey"
    execute "INSERT INTO institutional_regions (extension_region_id,institution_id,created_at) SELECT 1,294,NOW()" # South Carolina State University
    execute "INSERT INTO institutional_regions (extension_region_id,institution_id,created_at) SELECT 2,295,NOW()" # South Dakota State University
    execute "INSERT INTO institutional_regions (extension_region_id,institution_id,created_at) SELECT 1,266,NOW()" # Southern University A&M College
    execute "INSERT INTO institutional_regions (extension_region_id,institution_id,created_at) SELECT 1,296,NOW()" # Tennessee State University
    execute "INSERT INTO institutional_regions (extension_region_id,institution_id,created_at) SELECT 4,299,NOW()" # Texas A&M AgriLife Extension Service
    execute "INSERT INTO institutional_regions (extension_region_id,institution_id,created_at) SELECT 4,316,NOW()" # Texas A&M AgriLife Research
    execute "INSERT INTO institutional_regions (extension_region_id,institution_id,created_at) SELECT 4,1593,NOW()" # Texas A&M University
    execute "INSERT INTO institutional_regions (extension_region_id,institution_id,created_at) SELECT 2,287,NOW()" # The Ohio State University
    execute "INSERT INTO institutional_regions (extension_region_id,institution_id,created_at) SELECT 1,243,NOW()" # Tuskegee University
    execute "INSERT INTO institutional_regions (extension_region_id,institution_id,created_at) SELECT 5,244,NOW()" # University of Alaska
    execute "INSERT INTO institutional_regions (extension_region_id,institution_id,created_at) SELECT 5,245,NOW()" # University of Arizona
    execute "INSERT INTO institutional_regions (extension_region_id,institution_id,created_at) SELECT 4,246,NOW()" # University of Arkansas
    execute "INSERT INTO institutional_regions (extension_region_id,institution_id,created_at) SELECT 1,247,NOW()" # "University of Arkansas, Pine Bluff"
    execute "INSERT INTO institutional_regions (extension_region_id,institution_id,created_at) SELECT 5,313,NOW()" # University of California
    execute "INSERT INTO institutional_regions (extension_region_id,institution_id,created_at) SELECT 3,249,NOW()" # University of Connecticut
    execute "INSERT INTO institutional_regions (extension_region_id,institution_id,created_at) SELECT 3,250,NOW()" # University of Delaware
    execute "INSERT INTO institutional_regions (extension_region_id,institution_id,created_at) SELECT 3,252,NOW()" # University of District of Columbia
    execute "INSERT INTO institutional_regions (extension_region_id,institution_id,created_at) SELECT 4,254,NOW()" # University of Florida
    execute "INSERT INTO institutional_regions (extension_region_id,institution_id,created_at) SELECT 4,256,NOW()" # University of Georgia
    execute "INSERT INTO institutional_regions (extension_region_id,institution_id,created_at) SELECT 5,311,NOW()" # University of Guam
    execute "INSERT INTO institutional_regions (extension_region_id,institution_id,created_at) SELECT 5,257,NOW()" # University of Hawaii
    execute "INSERT INTO institutional_regions (extension_region_id,institution_id,created_at) SELECT 5,258,NOW()" # University of Idaho
    execute "INSERT INTO institutional_regions (extension_region_id,institution_id,created_at) SELECT 2,259,NOW()" # University of Illinois
    execute "INSERT INTO institutional_regions (extension_region_id,institution_id,created_at) SELECT 4,264,NOW()" # University of Kentucky
    execute "INSERT INTO institutional_regions (extension_region_id,institution_id,created_at) SELECT 3,267,NOW()" # University of Maine
    execute "INSERT INTO institutional_regions (extension_region_id,institution_id,created_at) SELECT 3,268,NOW()" # University of Maryland
    execute "INSERT INTO institutional_regions (extension_region_id,institution_id,created_at) SELECT 1,269,NOW()" # "University of Maryland, Eastern Shore"
    execute "INSERT INTO institutional_regions (extension_region_id,institution_id,created_at) SELECT 3,270,NOW()" # University of Massachusetts
    execute "INSERT INTO institutional_regions (extension_region_id,institution_id,created_at) SELECT 2,272,NOW()" # University of Minnesota
    execute "INSERT INTO institutional_regions (extension_region_id,institution_id,created_at) SELECT 2,276,NOW()" # University of Missouri
    execute "INSERT INTO institutional_regions (extension_region_id,institution_id,created_at) SELECT 2,278,NOW()" # University of Nebraska
    execute "INSERT INTO institutional_regions (extension_region_id,institution_id,created_at) SELECT 5,279,NOW()" # University of Nevada Reno
    execute "INSERT INTO institutional_regions (extension_region_id,institution_id,created_at) SELECT 3,280,NOW()" # University of New Hampshire
    execute "INSERT INTO institutional_regions (extension_region_id,institution_id,created_at) SELECT 4,309,NOW()" # University of Puerto Rico
    execute "INSERT INTO institutional_regions (extension_region_id,institution_id,created_at) SELECT 3,292,NOW()" # University of Rhode Island
    execute "INSERT INTO institutional_regions (extension_region_id,institution_id,created_at) SELECT 4,297,NOW()" # University of Tennessee
    execute "INSERT INTO institutional_regions (extension_region_id,institution_id,created_at) SELECT 4,310,NOW()" # University of the Virgin Islands
    execute "INSERT INTO institutional_regions (extension_region_id,institution_id,created_at) SELECT 3,301,NOW()" # University of Vermont
    execute "INSERT INTO institutional_regions (extension_region_id,institution_id,created_at) SELECT 2,307,NOW()" # University of Wisconsin
    execute "INSERT INTO institutional_regions (extension_region_id,institution_id,created_at) SELECT 5,308,NOW()" # University of Wyoming
    execute "INSERT INTO institutional_regions (extension_region_id,institution_id,created_at) SELECT 5,300,NOW()" # Utah State University
    execute "INSERT INTO institutional_regions (extension_region_id,institution_id,created_at) SELECT 4,302,NOW()" # Virginia Polytechnic Institute and State University
    execute "INSERT INTO institutional_regions (extension_region_id,institution_id,created_at) SELECT 1,303,NOW()" # Virginia State University
    execute "INSERT INTO institutional_regions (extension_region_id,institution_id,created_at) SELECT 5,304,NOW()" # Washington State University
    execute "INSERT INTO institutional_regions (extension_region_id,institution_id,created_at) SELECT 1,305,NOW()" # West Virginia State University
    execute "INSERT INTO institutional_regions (extension_region_id,institution_id,created_at) SELECT 3,306,NOW()" # West Virginia University
    execute "INSERT INTO institutional_regions (extension_region_id,institution_id,created_at) SELECT 1,1798,NOW()" # Central State University

    # lincoln double-region
    execute "INSERT INTO institutional_regions (extension_region_id,institution_id,created_at) SELECT 2,275,NOW()" # Lincoln University of Missouri

  end

end
