class Time
  def self.beginning_of_week(week_number, year = Time.now.year)
    Date.commercial(year, week_number, 1).to_time
  end

  def self.end_of_week(week_number, year = Time.now.year)
    Date.commercial(year, week_number, 7).to_time
  end

  def round(sec = 1)
    down = self - (to_i % sec)
    up = down + sec

    difference_down = self - down
    difference_up = up - self

    difference_down < difference_up ? down : up
  end

  def is_today?
    now = Time.now
    now.mday == day && now.month == month && now.year == year
  end

  def is_in_this_month?
    now = Time.now
    now.month == month && now.year == year
  end

  def is_in_previous_month?
    prev_month = Date.today.prev_month
    prev_month.month == month && prev_month.year == year
  end

  def prev_second(offset = 1)
    Time.at(to_i - 1 * offset)
  end

  def next_second(offset = 1)
    Time.at(to_i + 1 * offset)
  end

  def prev_minute(offset = 1)
    Time.at(to_i - 60 * offset)
  end

  def next_minute(offset = 1)
    Time.at(to_i + 60 * offset)
  end

  def prev_hour(offset = 1)
    Time.at(to_i - 3600 * offset)
  end

  def next_hour(offset = 1)
    Time.at(to_i + 3600 * offset)
  end

  def prev_day(offset = 1)
    Time.at(to_i - 86_400 * offset)
  end

  def next_day(offset = 1)
    Time.at(to_i + 86_400 * offset)
  end

  def beginning_of_day
    Time.strptime(strftime('%d/%m/%Y'), '%d/%m/%Y') rescue nil
  end

  def end_of_day
    Time.strptime("#{strftime('%d/%m/%Y')} 23:59:59", '%d/%m/%Y %H:%M:%S') rescue nil
  end

  def range_include_sunday?(end_date)
    start_date = self
    return true if start_date.wday.zero? || end_date.wday.zero? # wday return index day of week, start from 0 is sunday

    return true if ((end_date.to_i - start_date.to_i) / 86_400) >= 7 # case start date and end date over a week

    (end_date.wday - start_date.wday).negative?
  end

  def week_number
    strftime('%V').to_i # Week number of the week-based year (01..53)
  end

  def to_sql_datetime
    strftime('%Y-%m-%d %H:%M:%S')
  end

  def to_vn_datetime
    strftime('%d/%m/%Y %H:%M:%S')
  end

  def to_ms
    (to_f * 1000).to_i
  end

  def distance_ms(end_time)
    end_time.to_ms - to_ms
  end
end
