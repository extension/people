# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

module DateTools

  def previous_year_month(year_month)
    previous_month = (Date.strptime(year_month_string(year_month),'%Y-%m') - 1.month)
    [previous_month.year,previous_month.month]
  end

  def next_year_month(year_month)
    next_month = (Date.strptime(year_month_string(year_month),'%Y-%m') + 1.month)
    [next_month.year,next_month.month]
  end

  def year_month_string(year_month)
    "#{year_month[0]}-" + "%02d" % year_month[1]
  end

  def year_months_between_dates(start_date,end_date)
    year_months = []
    # construct a set of year-months given the start and end dates
    the_end = end_date.beginning_of_month
    loop_date = start_date.beginning_of_month
    while loop_date <= the_end
      year_months << [loop_date.year,loop_date.month]
      loop_date = loop_date.next_month
    end
    year_months
  end

  def years_between_dates(start_date,end_date)
    years = []
    end_year = end_date.year
    loop_year = start_date.year
    while loop_year <= end_year
      years << loop_year
      loop_year += 1
    end
    years
  end

  def year_quarters_between_dates(start_date,end_date)
    year_quarters = []
    the_end = end_date.beginning_of_quarter
    loop_date = start_date.beginning_of_quarter
    while loop_date <= the_end
      quarter = (loop_date.month / 3.0).ceil
      year_quarters << [loop_date.year,quarter]
      loop_date = loop_date.months_since(3)
    end
    year_quarters
  end


end
