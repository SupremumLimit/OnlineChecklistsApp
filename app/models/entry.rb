class Entry < ActiveRecord::Base
  scope :between_dates, lambda { |from, to| where("created_at >= ? AND created_at <= ?", from.to_s, to.to_s) }
  scope :for_checklist, lambda { |checklist_id| where("checklist_id = ?", checklist_id) }
  scope :for_user, lambda { |user_id| where("user_id = ?", user_id) }
  scope :within_one_year, lambda { |today| where("created_at > ?", today - 1.year)}
  scope :monthly_counts, :select => "count(id), extract(month from date_trunc('month', created_at)) as month,
         extract(year from date_trunc('month', created_at)) as year",  :group => "date_trunc('month', created_at)",
        :order => "date_trunc('month', created_at)"

#  select extract(month from date_trunc('month', created_at)),
#         extract(year from date_trunc('month', created_at)), count(*) from entries group by date_trunc('month', created_at);

  belongs_to :checklist
  belongs_to :user
  belongs_to :account

  validates :checklist_id, presence: true, numericality: true
  validates :user_id, presence: true, numericality: true

  def user_name
    user.safe_name
  end

  def checklist_name
    checklist.name
  end

  def display_time
    created_at.strftime("%H:%M")
  end

  def self.get_entries_by_day(entries)
    entries.group_by {|entry|               # group entries by date - produces a hash of entry arrays with dates as keys

      entry.created_at.to_date

    }.inject({}) {|hash, entries_for_date|

      # Format keys (which are dates) for display, and filter out unnecessary attributes from the entries
      # the result is still a hash of entry arrays with formatted dates as keys
      hash[entries_for_date.first.strftime("%A, %d %b %Y")] = entries_for_date.last.map { |e|
        {for: e.for, checklist_name: e.checklist_name, user_name: e.user_name, display_time: e.display_time}
      }; hash

    }
  end

  def self.transpose_counts(counts)
    counts.group_by {|row|

      [row.month, row.year]

    }.map {|date, counts|

      [Date.new(date.last.to_i, date.first.to_i, 1).end_of_month, counts.map(&:count)].flatten

    }
  end

end
