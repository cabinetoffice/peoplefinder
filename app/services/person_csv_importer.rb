require 'csv'
require 'forwardable'

class PersonCsvImporter
  extend Forwardable

  COLUMNS = %i[
    given_name
    surname
    email
    profile_photo
    staff_nr
    secondary_phone_number
  ]

  ErrorRow = Struct.new(:line_number, :raw, :messages) do
    def to_s
      'line %d "%s": %s' % [line_number, raw, messages.join(', ')]
    end
  end

  attr_reader :errors

  def initialize(serialized, creation_options = {})
    @parser = parse_csv(serialized)
    @creation_options = creation_options
    @valid = nil
  end

  def valid?
    return @valid unless @valid.nil?
    @errors = missing_columns.any? ? column_errors : row_errors
    @valid = @errors.empty?
  end

  def import
    return nil unless valid?

    people.each do |person|
      PersonCreator.new(person, nil).create!
    end
    people.length
  end

private

  def_delegators :@parser, :records, :header

  def clean_fields(hash)
    hash.
      merge(email: EmailExtractor.new.extract(hash[:email])).
      merge(profile_photo: ProfilePhoto.find_by(id: hash[:profile_photo]))
  end

  def parse_csv(serialized)
    PersonCsvParser.new(serialized)
  end

  def people
    @people ||= records.map { |record|
      Person.new(@creation_options.merge(clean_fields(record.fields)))
    }
  end

  def missing_columns
    COLUMNS - header.columns
  end

  def row_errors
    people.zip(records).map { |person, record|
      if person.valid?
        nil
      else
        ErrorRow.new(
          record.line_number, record.original, person.errors.full_messages
        )
      end
    }.compact
  end

  def column_errors
    missing_columns.map { |column|
      ErrorRow.new(1, header.original, ["#{column} column is missing"])
    }
  end
end
