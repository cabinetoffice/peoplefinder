require 'rails_helper'

RSpec.describe Person, type: :model do
  include PermittedDomainHelper
  include BuildingsHelper
  include CitiesHelper

  let(:person) { build(:person) }
  it { should validate_presence_of(:given_name).on(:update) }
  it { should validate_presence_of(:surname) }
  it { should validate_presence_of(:email) }
  it { should validate_uniqueness_of(:email).case_insensitive }
  it { should have_many(:groups) }

  describe '.name' do
    context 'with a given_name and surname' do
      let(:person) { build(:person, given_name: 'Jon', surname: 'von Brown') }

      it 'concatenates given_name and surname' do
        expect(person.name).to eql('Jon von Brown')
      end
    end

    context 'with a surname only' do
      let(:person) { build(:person, given_name: '', surname: 'von Brown') }

      it 'uses the surname' do
        expect(person.name).to eql('von Brown')
      end
    end
  end

  describe '.all_in_groups' do
    let(:groups) { create_list(:group, 3) }
    let(:people) { create_list(:person, 3) }

    it 'returns all people in any listed groups and .count_in_groups returns correct count' do
      people.zip(groups).each do |person, group|
        create :membership, person: person, group: group
      end
      group_ids = groups.take(2)
      result = described_class.all_in_groups(group_ids)
      expect(result).to include(people[0])
      expect(result).to include(people[1])
      expect(result).not_to include(people[2])

      people_count = described_class.count_in_groups(group_ids)
      expect(people_count).to eq(2)
    end

    it 'concatenates all roles alphabetically with commas' do
      create :membership, person: people[0], group: groups[0], role: 'Prison chaplain'
      create :membership, person: people[0], group: groups[1], role: 'Head of crime'
      result = described_class.all_in_groups(groups.take(2))
      expect(result[0].role_names).to eq('Head of crime, Prison chaplain')
    end

    it 'omits blank roles' do
      create :membership, person: people[0], group: groups[0], role: 'Prison chaplain'
      create :membership, person: people[0], group: groups[1], role: ''
      result = described_class.all_in_groups(groups.take(2))
      expect(result[0].role_names).to eq('Prison chaplain')
    end

    it 'includes each person only once' do
      create :membership, person: people[0], group: groups[0], role: 'Prison chaplain'
      create :membership, person: people[0], group: groups[1], role: 'Head of crime'
      result = described_class.all_in_groups(groups.take(2))
      expect(result.length).to eq(1)
    end
  end

  context 'slug' do
    it 'generates from the first part of the email address if present' do
      person = create(:person, email: 'user.example@cabinetoffice.gov.uk')
      person.reload
      expect(person.slug).to eql('user-example')
    end
  end

  context 'search' do
    it 'deletes indexes' do
      expect(described_class.__elasticsearch__).to receive(:delete_index!).
        with(index: 'test_people')
      described_class.delete_indexes
    end
  end

  context 'elasticsearch indexing helpers' do
    before do
      person.save!
      digital_services = create(:group, name: 'Digital Services')
      estates = create(:group, name: 'Estates')
      person.memberships.create(group: estates, role: 'Cleaner')
      person.memberships.create(group: digital_services, role: 'Designer')
    end

    it 'writes the role and group as a string' do
      expect(person.role_and_group).to match(/Digital Services, Designer/)
      expect(person.role_and_group).to match(/Estates, Cleaner/)
    end
  end

  context 'path' do
    let(:person) { described_class.new }

    context 'when there are no memberships' do
      it 'contains only itself' do
        expect(person.path).to eql([person])
      end
    end

    context 'when there is one membership' do
      it 'contains the group path' do
        group_a = build(:group)
        group_b = build(:group)
        allow(group_b).to receive(:path) { [group_a, group_b] }
        person.groups << group_b
        expect(person.path).to eql([group_a, group_b, person])
      end
    end

    context 'when there are multiple group memberships' do
      let(:groups) { 4.times.map { build(:group) } }

      before do
        allow(groups[1]).to receive(:path) { [groups[0], groups[1]] }
        allow(groups[3]).to receive(:path) { [groups[2], groups[3]] }
        person.groups << groups[1]
        person.groups << groups[3]
      end

      it 'uses the first group path' do
        expect(person.path).to eql([groups[0], groups[1], person])
      end
    end
  end

  describe '.phone' do
    let(:person) { create(:person) }
    let(:primary_phone_number) { '0207-123-4567' }
    let(:secondary_phone_number) { '0208-999-8888' }

    context 'with a primary and secondary phone' do
      before do
        person.primary_phone_number = primary_phone_number
        person.secondary_phone_number = secondary_phone_number
      end

      it 'uses the primary phone number' do
        expect(person.phone).to eql(primary_phone_number)
      end
    end

    context 'with a blank primary and a valid secondary phone' do
      before do
        person.primary_phone_number = ''
        person.secondary_phone_number = secondary_phone_number
      end

      it 'uses the secondary phone number' do
        expect(person.phone).to eql(secondary_phone_number)
      end
    end
  end

  describe '#location' do
    it 'concatenates location_in_building, location, and city' do
      person.location_in_building = '99.99'
      building = Building.take
      person.building = building
      person.city = City.where(name: 'London').first
      expect(person.location).to eq("99.99, #{building.address}, London")
    end

    it 'skips blank fields' do
      person.location_in_building = 'At home'
      person.building = Building.create(address: '')
      person.city = nil
      expect(person.location).to eq('At home')
    end
  end

  describe '#notify_of_change?' do
    context 'when the email is invalid' do
      before do
        person.email = 'invalid'
      end

      it 'is false' do
        expect(person.notify_of_change?(build(:person))).
          to be_falsy
      end
    end

    context 'when the email is valid' do
      it 'is true if there is no reponsible person' do
        rp = nil
        expect(person.notify_of_change?(rp)).to be_truthy
      end

      it 'is false if the reponsible person is this person' do
        rp = person
        expect(person.notify_of_change?(rp)).to be_falsy
      end

      it 'is true if the reponsible person is a third party' do
        rp = build(:person)
        expect(person.notify_of_change?(rp)).to be_truthy
      end
    end
  end

  describe 'profile_image' do
    context 'when there is a profile photo' do
      it 'delegates to the profile photo' do
        profile_photo = create(:profile_photo)
        person.profile_photo = profile_photo
        expect(person.profile_image).to eq(profile_photo.image)
      end
    end

    context 'when there is a legacy image but no profile photo' do
      it 'returns the mounted uploader' do
        person.assign_attributes image: 'cats.gif'
        expect(person.profile_image).to be_kind_of(ImageUploader)
      end
    end

    context 'when there is no image' do
      it 'returns nil' do
        person.assign_attributes image: nil
        expect(person.profile_image).to be_nil
      end
    end
  end

  describe '#is?' do
    context 'given another person' do
      it 'returns false' do
        other_person = create(:person, email: 'test.user@cabinetoffice.gov.uk')
        expect(person.is?(other_person)).to be false
      end
    end

    context 'given a person with matching email' do
      it 'returns true' do
        email = 'test.user@cabinetoffice.gov.uk'
        person.email = email
        other_person = create(:person, email: email)
        expect(person.is?(other_person)).to be true
      end
    end
  end

end
