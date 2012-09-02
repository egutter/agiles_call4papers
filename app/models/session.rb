class Session < ActiveRecord::Base
  attr_accessible :title, :summary, :description, :mechanics, :benefits,
                  :target_audience, :audience_level_id, :audience_limit,
                  :author_id, :second_author_username, :track_id, :conference_id,
                  :session_type_id, :duration_mins, :experience,
                  :keyword_list, :author_agreement, :image_agreement, :state_event
  attr_trimmed :title, :summary, :description, :mechanics, :benefits,
               :target_audience, :experience

  acts_as_taggable_on :keywords
  acts_as_commentable

  belongs_to :author, :class_name => 'User'
  belongs_to :second_author, :class_name => 'User'
  belongs_to :track
  belongs_to :session_type
  belongs_to :audience_level
  belongs_to :conference

  has_many :reviews
  has_one :review_decision

  validates_presence_of :title, :summary, :description, :benefits, :target_audience,
                        :audience_level_id, :author_id, :track_id, :session_type_id,
                        :experience, :duration_mins, :keyword_list, :conference_id

  validates_presence_of :mechanics, :if => :workshop?
  validates_inclusion_of :duration_mins, :in => [10, 50, 110], :allow_blank => true
  validates_numericality_of :audience_limit, :only_integer => true, :greater_than => 0, :allow_nil => true

  validates_length_of :title, :maximum => 100
  validates_length_of :target_audience, :maximum => 200
  validates_length_of [:benefits, :experience], :maximum => 400
  validates_length_of :summary, :maximum => 800
  validates_length_of :description, :maximum => 2400
  validates_length_of :mechanics, :maximum => 2400, :allow_blank => true

  validates_existence_of :conference, :author
  validates_existence_of :track, :session_type, :audience_level, :allow_blank => true

  validates_each :keyword_list do |record, attr, value|
    record.errors.add(attr, :too_long, :count => 12) if record.keyword_list.size > 12
  end

  validates_each :second_author_username, :allow_blank => true do |record, attr, value|
    record.errors.add(attr, :existence) if record.second_author.nil?
    record.errors.add(attr, :same_author) if record.second_author == record.author
    record.errors.add(attr, :incomplete) if record.second_author.present? && !record.second_author.try(:author?)
  end
  validates_each :duration_mins, :if => :experience_report?, :allow_blank => true do |record, attr, value|
    record.errors.add(attr, :experience_report_talk_duration) if record.session_type.try(:title) == 'session_types.talk.title' && value != 50
  end
  validates_each :duration_mins, :unless => :lightning_talk?, :allow_blank => true do |record, attr, value|
    record.errors.add(attr, :non_lightning_talk_duration) unless [50, 110].include?(value)
  end
  validates_each :duration_mins, :if => :lightning_talk?, :allow_blank => true do |record, attr, value|
    record.errors.add(attr, :lightning_talk_duration) if value != 10
  end
  validates_each :session_type_id, :if => :experience_report? do |record, attr, value|
    record.errors.add(attr, :experience_report_session_type) unless ['session_types.talk.title', 'session_types.lightning_talk.title', 'session_types.experience_reports.title'].include?(record.session_type.try(:title))
  end
  validates_each :author_id, :on => :update do |record, attr, value|
    record.errors.add(attr, :constant) if record.author_id_changed?
  end

  scope :for_conference, lambda { |c| where('conference_id = ?', c.id) }

  scope :for_user, lambda { |u| where('author_id = ? OR second_author_id = ?', u.to_i, u.to_i) }

  scope :for_tracks, lambda { |track_ids| where('track_id IN (?)', track_ids) }

  scope :not_author, lambda { |u| where('author_id <> ? AND (second_author_id IS NULL OR second_author_id <> ?)', u.to_i, u.to_i) }

  scope :reviewed_by, lambda { |u, c| where('reviewer_id = ? AND conference_id = ?', u.id, c.id).joins(:reviews) }

  scope :for_preferences, lambda { |*preferences|
    return where('1 = 2') if preferences.empty?
    clause = preferences.map { |p| "(track_id = ? AND audience_level_id <= ?)" }.join(" OR ")
    args = preferences.map { |p| [p.track_id, p.audience_level_id] }.flatten
    where(clause, *args)
  }

  scope :incomplete_reviews, lambda { |limit| where('reviews_count < ?', limit) }

  scope :sessions_with_outcome, lambda { |outcome, published|
    for_conference(Conference.current).
      joins(:review_decision).
      where(:review_decisions => {:outcome_id => Outcome.find_by_title(outcome).id, :published => published})
  }

  scope :accepted_sessions, lambda { |published|
    sessions_with_outcome('outcomes.accept.title', published)
  }

  def self.for_reviewer(user, conference)
    for_conference(conference).
      incomplete_reviews(3).
      not_author(user.id).
      without_state(:cancelled).
      for_preferences(*user.preferences(conference)).all - reviewed_by(user, conference).all
  end

  state_machine :initial => :created do
    event :reviewing do
      transition [:created, :in_review] => :in_review
    end

    event :cancel do
      transition [:created, :in_review] => :cancelled
    end

    event :tentatively_accept do
      transition [:rejected, :in_review] => :pending_confirmation
    end

    event :accept do
      transition :pending_confirmation => :accepted
    end

    event :reject do
      transition [:pending_confirmation, :in_review] => :rejected
    end

    state :accepted do
      validates_acceptance_of :author_agreement, :accept => true
    end

    state :rejected do
      validates_acceptance_of :author_agreement, :accept => true
    end

  end

  def second_author_username
    @second_author_username || second_author.try(:username)
  end

  def second_author_username=(username)
    @second_author_username = username.try(:strip)
    @second_author_username.tap do
      if @second_author_username.blank?
        self.second_author = nil
      else
        self.second_author = User.find_by_username(@second_author_username)
      end
    end
  end

  def to_param
    title.blank? ? super : "#{id}-#{title.parameterize}"
  end

  def authors
    [author, second_author].compact
  end

  def is_author?(user)
    authors.include?(user)
  end

  def lightning_talk?
    self.session_type.try(:title) == 'session_types.lightning_talk.title'
  end

  def self.approved_authors_to_csv
    File.open('authors_selected.csv', 'w') do |file|
      file.puts "Full name| Email| Company| Country| Bio"
      Session.accepted_sessions(true).map(&:authors).flatten.each { |author|
        file.puts "#{author.full_name}| "+
                    "#{author.email}| "+
                    "#{author.organization}| "+
                    "#{author.country}| "+
                    "#{safe_text(author.bio)}"
      }
    end
  end

  def self.approved_sessions_to_csv
    File.open('approved_sessions.csv', 'w') do |file|
      file.puts "ID| Author| 2nd Author| Title| Summary| AudienceLevel| Session Type| Track| Duration"
      Session.accepted_sessions(true).each { |session|
        file.puts "#{session.id}| #{session.author.full_name}| "+
                    "#{session.second_author.try(:full_name)}| "+
                    "#{safe_text(session.title)}| #{safe_text(session.summary)}| "+
                    "#{I18n.translate session.audience_level.title}| "+
                    "#{I18n.translate session.session_type.title}| "+
                    "#{safe_text(I18n.translate(session.track.title))}| "+
                    "#{session.duration_mins}"
      }
    end
  end

  def self.reviews_to_csv
    recommendation_value = {"recommendation.strong_reject.title" => -2,
                            "recommendation.weak_reject.title" => -1,
                            "recommendation.weak_accept.title" => 1,
                            "recommendation.strong_accept.title" => 2}
    File.open('reviews.csv', 'w') do |file|
      file.puts "ID, Author, 2nd Author, Title, Summary, AudienceLevel, Session Type, Track, Duration, Recommendation SUM, Reviewer 1, Reviewer 2, Reviewer 3"
      for_conference(Conference.current).each { |session|
        recommendation_sum = 0
        reviews = []
        session.reviews.each { |review|
          recommendation_sum += recommendation_value[review.recommendation.title]
          reviews << "#{review.reviewer.full_name} -> #{I18n.translate review.recommendation.title}"
        }
        file.puts "#{session.id}, #{session.author.full_name}, "+
                    "#{session.second_author.try(:full_name)}, "+
                    "#{safe_text(session.title)}, #{safe_text(session.summary.truncate(200))}, "+
                    "#{I18n.translate session.audience_level.title}, "+
                    "#{I18n.translate session.session_type.title}, "+
                    "#{safe_text(I18n.translate(session.track.title))}, "+
                    "#{session.duration_mins}, "+
                    "#{recommendation_sum}, #{reviews.join(',')}"
      }
    end
  end

  def self.safe_text(text)
    text.gsub(',', ';').gsub(/[ \t\r\n\f]/, ' ')
  end


  private
  def workshop?
    self.session_type.try(:title) == 'session_types.workshop.title'
  end

  def experience_report?
    self.session_type.try(:title) == 'session_types.experience_reports.title'
  end
end