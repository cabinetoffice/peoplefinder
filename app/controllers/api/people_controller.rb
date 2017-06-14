module Api
  class PeopleController < ApplicationController
    before_action :set_person, only: [:show]

    # GET /people
    def all
        @people = Person.all
        respond_to do |format|
          format.json { render json: @people}
          format.csv { send_data @people.to_csv}
        end
    end

    # GET /people/1
    def show
      respond_to do |format|
        format.json { render json: @person}
        format.csv { send_data @person.to_csv}
      end
    end

  private

    # Use callbacks to share common setup or constraints between actions.
    def set_person
      @person = Person.friendly.includes(:groups).find(params[:id])
    end
  end
end
