require 'csv'

class Person < ActiveRecord::Base
  include Concerns::Acquisition
  include Concerns::Activation
  include Concerns::Completion
  include Concerns::WorkDays
  include Concerns::ExposeMandatoryFields
  belongs_to :profile_photo

  belongs_to :city
  belongs_to :building

  extend FriendlyId
  friendly_id :slug_source, use: :slugged

  def slug_source
    email.present? ? email.split(/@/).first : name
  end

  include Concerns::Searchable

  def as_indexed_json(_options = {})
    as_json(
      only: [:tags, :description, :location_in_building, :staff_nr],
      methods: [:name, :role_and_group, :community_name, :building_value, :city_value]
    )
  end

  has_paper_trail class_name: 'Version',
                  ignore: [:updated_at, :created_at, :id, :slug, :login_count, :last_login_at]

  def changes_for_paper_trail
    super.tap { |changes|
      changes['image'].map! { |img| img.url && File.basename(img.url) } if changes.key?('image')
    }
  end

  include Concerns::Sanitizable
  sanitize_fields :given_name, :surname, strip: true
  sanitize_fields :email, strip: true, downcase: true

  attr_accessor :crop_x, :crop_y, :crop_w, :crop_h
  after_save :crop_profile_photo

  def crop_profile_photo
    profile_photo.crop crop_x, crop_y, crop_w, crop_h if crop_x.present?
  end

  mount_uploader :legacy_image, ImageUploader, mount_on: :image, mount_as: :image

  def profile_image
    if profile_photo
      profile_photo.image
    elsif attributes['image']
      legacy_image
    else
      nil
    end
  end

  def profile_image_source(version = :medium)
    self.profile_photo.try(:image).try(version) || 'medium_no_photo.png'
  end

  validates :given_name, presence: true, on: [:create, :update]
  validates :surname, presence: true
  validates :email,
    presence: true, uniqueness: { case_sensitive: false }, email: true
  validates :secondary_email, email: true, allow_blank: true

  has_many :memberships,
    -> { includes(:group).order('groups.name') },
    dependent: :destroy
  has_many :groups, through: :memberships
  belongs_to :community

  accepts_nested_attributes_for :memberships,
    allow_destroy: true,
    reject_if: proc { |membership| membership['group_id'].blank? }

  default_scope { order(surname: :asc, given_name: :asc) }

  def self.namesakes(person)
    where(surname: person.surname, given_name: person.given_name).where.not(id: person.id)
  end

  def self.all_in_groups(group_ids)
    query = <<-SQL
      SELECT DISTINCT p.*,
        string_agg(CASE role WHEN '' THEN NULL ELSE role END, ', ' ORDER BY role) AS role_names
      FROM memberships m, people p
      WHERE m.person_id = p.id AND m.group_id in (?)
      GROUP BY p.id
      ORDER BY surname ASC, given_name ASC;
    SQL
    find_by_sql([query, group_ids])
  end

  def self.count_in_groups(group_ids, excluded_group_ids: [])
    excluded_ids = if excluded_group_ids.present?
                     Person.in_groups(excluded_group_ids).pluck(:id)
                   else
                     []
                   end

    Person.in_groups(group_ids).where.not(id: excluded_ids).count
  end

  private

  def self.in_groups(group_ids)
    Person.includes(:memberships).
        where("memberships.group_id": group_ids)
  end

  def self.leaders_in_groups_by_creation_date(group_ids)
    Person.includes(:memberships).
        where("memberships.group_id": group_ids).where("memberships.leader": true).sort_by(&:created_at)
  end

  def self.leaders_in_groups_by_surname(group_ids)
    Person.includes(:memberships).
        where("memberships.group_id": group_ids).where("memberships.leader": true).sort_by(&:surname)
  end

  public

  def self.to_csv
    CSV.generate do |csv|
      csv << [:id, :friendly_id, :given_name, :surname, :email, :primary_phone_number, :secondary_phone_number]
      all.each do |person|
        csv << [person.id, person.friendly_id, person.given_name, person.surname, person.email, person.primary_phone_number, person.secondary_phone_number]
      end
    end
  end

  def to_csv
    CSV.generate do |csv|
      csv << [:id, :friendly_id, :given_name, :surname, :email, :primary_phone_number, :secondary_phone_number]
      csv << [id, friendly_id, given_name, surname, email, primary_phone_number, secondary_phone_number]
    end
  end

  def to_s
    name
  end

  def role_and_group
    memberships.map(&:indexed_fields).join('; ')
  end

  def path
    groups.any? ? groups.first.path + [self] : [self]
  end

  def phone
    [primary_phone_number, secondary_phone_number].find(&:present?)
  end

  delegate :name, to: :community, prefix: true, allow_nil: true
  delegate :address, to: :building, prefix: true, allow_nil: true
  delegate :name,    to: :city,     prefix: true, allow_nil: true

  include Concerns::ConcatenatedFields
  concatenated_field :name, :given_name, :surname, join_with: ' '
  concatenated_field :location, :location_in_building, :building_value, :city_value, join_with: ', '

  def to_s
    name
  end

  def building_value
    custom_building.presence || building_address
  end

  def city_value
    custom_city.presence || city_name
  end

  def at_permitted_domain?
    EmailAddress.new(email).permitted_domain?
  end

  def notify_of_change?(person_responsible)
    at_permitted_domain? && person_responsible.try(:email) != email
  end

  def can_be_edited_by?(user)
    return true if groups.empty?

    @_can_edit ||= PolicyValidator.new(groups.first).validate(user)
  end

  def is? person
    person && person.email == self.email
  end
end
