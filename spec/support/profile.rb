module SpecSupport
  module Profile
    def person_attributes
      {
        given_name: 'Marco',
        surname: 'Polo',
        email: 'marco.polo@cabinetoffice.gov.uk',
        primary_phone_number: '+44-208-123-4567',
        secondary_phone_number: '07777777777',
        location_in_building: '10.999',
        building: Building.take,
        city: City.take,
        description: 'Lorem ipsum dolor sit amet...'
      }
    end

    def complete_profile!(person)
      profile_photo = create(:profile_photo)
      person.update_attributes(
        person_attributes.
          except(:email).
          merge(profile_photo_id: profile_photo.id)
      )
      person.groups << create(:group)
    end

    def fill_in_complete_profile_details
      fill_in 'First name', with: person_attributes[:given_name]
      fill_in 'Surname', with: person_attributes[:surname]
      select_in_team_select 'Digital'
      fill_in 'Main email', with: person_attributes[:email]
      fill_in 'Main phone number', with: person_attributes[:primary_phone_number]
      fill_in 'Alternative phone number', with: person_attributes[:secondary_phone_number]
      fill_in 'Location in building', with: person_attributes[:location_in_building]
      find('#person_building_id').find(:option, person_attributes[:building].address).select_option
      find('#person_city_id').find(:option, person_attributes[:city].name).select_option
      fill_in 'Extra information', with: person_attributes[:description]
      uncheck('Monday')
      uncheck('Friday')
    end

    def check_creation_of_profile_details
      name = "#{person_attributes[:given_name]} #{person_attributes[:surname]}"

      expect(page).to have_title("#{name} - #{ app_title }")
      within('h1') { expect(page).to have_text(name) }
      expect(page).to have_text(person_attributes[:email])
      expect(page).to have_text(person_attributes[:primary_phone_number])
      expect(page).to have_text(person_attributes[:secondary_phone_number])
      expect(page).to have_text(person_attributes[:location_in_building])
      expect(page).to have_text(person_attributes[:building].address)
      expect(page).to have_text(person_attributes[:city].name)
      expect(page).to have_text(person_attributes[:description])

      within('ul.working_days') do
        expect(page).to_not have_selector("li.active[alt='Monday']")
        expect(page).to have_selector("li.active[alt='Tuesday']")
        expect(page).to have_selector("li.active[alt='Wednesday']")
        expect(page).to have_selector("li.active[alt='Thursday']")
        expect(page).to_not have_selector("li.active[alt='Friday']")
        expect(page).to_not have_selector("li.active[alt='Saturday']")
        expect(page).to_not have_selector("li.active[alt='Sunday']")
      end
    end
  end
end
