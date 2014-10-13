require 'rails_helper'

RSpec.describe ReminderMailer do

  describe '.inadequate_profile' do
    let(:person) { create(:person, email: 'test.user@digital.justice.gov.uk') }
    let(:mail) { described_class.inadequate_profile(person).deliver }

    it 'sets the sender' do
      expect(mail.from).to include(Rails.configuration.support_email)
    end

    it 'sets the correct recipient' do
      expect(mail.to).to include(person.email)
    end

    it 'sets the subject' do
      expect(mail.subject).to have_text('Reminder: update your profile today')
    end

    it 'describes the profile completion score' do
      expect(mail.body).to have_text("profile is #{ person.completion_score }% complete")
    end

    it 'includes the token url with desired path' do
      expect(mail.body).to have_text(token_url(Token.last, desired_path: "/people/#{ person.to_param }/edit"))
    end
  end

  describe '.reported_profile' do
    let(:subject) { create(:person, surname: 'subject-person') }
    let(:reported_profile) do
      ReportedProfile.create(
        subject: subject,
        notifier: create(:person, surname: 'notifier-person'),
        recipient_email: 'recipient@example.com',
        reason_for_reporting: 'something',
        additional_details: 'more info')
    end

    let(:mail) { described_class.reported_profile(reported_profile).deliver }

    it 'sets the recipient' do
      expect(mail.to).to include('recipient@example.com')
    end

    it 'sets the subject' do
      expect(mail.subject).to have_text('A People Finder profile has been reported')
    end

    it 'includes the notifier' do
      expect(mail.body).to have_text('notifier-person has said that ')
    end

    it 'includes the subject' do
      expect(mail.body).to have_text('the information on subject-person')
    end

    it 'includes the subject url' do
      expect(mail.body).to have_text(person_url(subject))
    end
  end
end