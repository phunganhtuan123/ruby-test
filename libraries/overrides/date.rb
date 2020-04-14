# frozen_string_literal: true

class Date
  class << self
    def beginning_of_week(year: today.year, cweek: today.cweek)
      commercial(year, cweek, 1) # 1 is beginning_of_week
    end

    def end_of_week(year: today.year, cweek: today.cweek)
      commercial(year, cweek, 7) # 7 is end_of_week
    end

    def vn_cweek(year: today.year, cweek: today.cweek)
      vn_beginning_of_week = beginning_of_week(year: year, cweek: cweek).to_vn_date
      vn_end_of_week = end_of_week(year: year, cweek: cweek).to_vn_date
      "Tuần #{cweek}\n(#{vn_beginning_of_week} - #{vn_end_of_week})"
    end
  end

  def monday_of_week
    # https://stackoverflow.com/questions/6858908/how-can-i-get-the-current-weekday-beginning-in-ruby
    self - (wday - 1) % 7
  end

  def prev_monday
    (monday_of_week - 1).monday_of_week
  end

  def friday_of_week
    monday_of_week + 4
  end

  def next_friday
    (friday_of_week + 3).friday_of_week
  end

  def after_friday_of_week?
    wday >= 5
  end

  def to_vn_date
    strftime('%d/%m/%Y')
  end

  def prev_week
    self - 7
  end

  def next_week
    self + 7
  end
end
