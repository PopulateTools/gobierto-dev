module GobiertoAdmin
  module GobiertoCalendars
    class EventsController < BaseController

      before_action :load_collection, only: [:new, :edit, :create, :update, :index]
      before_action :load_person, only: [:new, :edit, :create, :update, :index]
      before_action :person_allowed!, if: :person_collection?
      before_action :manage_event_allowed!, only: [:new, :edit, :create, :update, :index]

      attr_reader :collection

      def index
        @preview_item = collection
        @events_presenter = GobiertoAdmin::GobiertoCalendars::EventsPresenter.new(collection)
        @events = ::GobiertoCalendars::Event.by_collection(collection).sorted
        @archived_events = current_site.events
                                       .only_archived
                                       .where(collection: collection)
                                       .sorted
                                       .page(params[:archived_events_page])
                                       .per(::GobiertoCalendars::Event::ADMIN_PAGE_SIZE)

        case params[:scope]
        when "pending"
          @events = @events.pending
        when "published"
          @events = @events.published
        when "past"
          @events = @events.past
        else
          @events = @events.upcoming
        end

        @events = @events.page(params[:events_page]).per(::GobiertoCalendars::Event::ADMIN_PAGE_SIZE)
      end

      def new
        @event_form = EventForm.new(collection_id: collection.id)
        @attendees = get_attendees
        @event_states = get_calendar_event_states
      end

      def edit
        load_event(preview: true)
        @event_states = get_calendar_event_states
        @attendees = get_attendees

        @event_form = EventForm.new(
          @event.attributes.except(*ignored_event_attributes).merge(collection_id: collection.id)
        )
      end

      def create
        @event_form = EventForm.new(
          event_params.merge(collection_id: collection.id, admin_id: current_admin.id, site_id: current_site.id)
        )

        if @event_form.save
          redirect_to(
            edit_admin_calendars_event_path(@event_form.event, collection_id: collection),
            notice: t(".success_html", link: @event_form.to_url(preview: true, admin: current_admin))
          )
        else
          @attendees = get_attendees
          @event_states = get_calendar_event_states
          render :new
        end
      end

      def update
        load_event(preview: true)

        @event_form = EventForm.new(event_params.merge(
          id: params[:id],
          admin_id: current_admin.id,
          site_id: current_site.id,
          collection_id: collection.id,
          external_id: @event.external_id
        ))

        if @event_form.save
          redirect_to(
            edit_admin_calendars_event_path(@event, collection_id: collection),
            notice: t(".success_html", link: @event_form.to_url(preview: true, admin: current_admin))
          )
        else
          @attendees = get_attendees
          @event_states = get_calendar_event_states
          render :edit
        end
      end

      def destroy
        load_event
        @event.destroy
        process = find_process if params[:process_id]

        redirect_to admin_common_collection_path(@event.collection), notice: t(".success")
      end

      def recover
        @event = find_archived_event
        @event.restore

        process = find_process if params[:process_id]

        redirect_to admin_common_collection_path(@event.collection), notice: t(".success")
      end

      private

      def load_collection
        @collection = current_site.collections.find(params[:collection_id])
      end

      def load_person
        if person_collection?
          @person = collection_container
        end
      end

      def find_process
        current_site.processes.find(params[:process_id])
      end

      def load_event(opts = {})
        @event = current_site.events.find params[:id]
        @preview_item = @event if opts[:preview]
      end

      def find_archived_event
        current_site.events.with_archived.find(params[:event_id])
      end

      def get_attendees
        person_id = person_collection? ? collection_container.id : 0
        current_site.people
          .where.not(id: person_id)
          .active
          .select(:id, :name)
      end

      def person_collection?
        collection_container.is_a?(::GobiertoPeople::Person)
      end

      def collection_container
        collection&.container
      end

      def get_calendar_event_states
        ::GobiertoCalendars::Event.states
      end

      def event_params
        params.require(:event).permit(
          :starts_at,
          :ends_at,
          :state,
          :slug,
          :attachment_ids,
          locations_attributes: [:id, :name, :address, :lat, :lng, :_destroy],
          attendees_attributes: [:id, :person_id, :name, :charge, :_destroy],
          title_translations: [*I18n.available_locales],
          description_source_translations: [*I18n.available_locales],
          description_translations: [*I18n.available_locales]
        )
      end

      def ignored_event_attributes
        %w(created_at updated_at title description external_id site_id collection_id
           archived_at)
      end

      def manage_event_allowed!
        event_policy = GobiertoCalendars::EventPolicy.new(
                         current_site: current_site,
                         current_admin: current_admin,
                         event: try(:@event),
                         collection_id: try(:@collection) ? collection.id : nil
                       )

        if !event_policy.manage? || (try(:@collection).container.nil? if try(:@collection))
          redirect_to(admin_root_path, alert: t('gobierto_admin.admin_unauthorized')) and return false
        end
      end

      def person_allowed!
        check_gobierto_people_permissions!
        check_person_permissions!
      end

      def check_gobierto_people_permissions!
        module_enabled!(current_site, "GobiertoPeople")
        module_allowed!(current_admin, "GobiertoPeople")
      end

      def check_person_permissions!
        person_policy = GobiertoPeople::PersonPolicy.new(current_admin: current_admin, current_site: current_site, person: @person)
        if !person_policy.manage?
          redirect_to admin_people_people_path, alert: t('gobierto_admin.admin_unauthorized')
        end
      end

    end
  end
end
