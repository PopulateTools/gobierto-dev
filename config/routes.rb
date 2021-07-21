# frozen_string_literal: true

require "sidekiq/web"

Rails.application.routes.draw do

  if Rails.env.test?
    get("/populate_data_mock/datasets/*dataset_file", to: "stubbed_external_request#populate_data_indicator")
    get("/bubbles_file_mock/bubbles.json", to: "stubbed_external_request#bubbles_file")
  end

  unless Rails.env.production?
    get "/sandbox" => "sandbox#index"
    get "/sandbox/*template" => "sandbox#show"
  end

  scope ENV.fetch("GOBIERTO_ROOT_URL_PATH", "") do
    # The root page is kind of dynamic
    constraints GobiertoSiteConstraint.new do
      root "meta_welcome#index"
    end

    # Admin module
    namespace :gobierto_admin, as: :admin, path: :admin do
      get "/" => "welcome#index", as: :root

      resource :sessions, only: [:new, :create, :destroy]
      resource :custom_session, only: [:new, :create, :destroy]
      resources :sites, only: [:index, :new, :create, :edit, :update, :destroy]
      namespace :gobierto_core do
        resources :templates, only: [:index] do
          get :edit
        end
        resources :site_templates, only: [:create, :update, :destroy]
      end

      namespace :sites do
        resource :sessions, only: [:create, :destroy]
      end

      resources :admins, only: [:index, :show, :new, :create, :edit, :update] do
        resources :api_tokens, only: [:new, :create, :edit, :update, :destroy], controller: "admins/api_tokens"
      end

      resources :admin_groups, only: [:index, :new, :create, :edit, :update] do
        resources :admins, only: [:index, :new, :create, :destroy], controller: "admin_groups/admins"
      end

      namespace :admin do
        resource :invitations, only: [:new, :create]
        resource :invitation_acceptances, only: [:show]
        resource :passwords, only: [:new, :create, :edit, :update]
        resource :settings, only: [:edit, :update]
      end

      resources :users, only: [:index, :show, :edit, :update] do
        resource :welcome_messages, only: [:create], controller: "users/welcome_messages"
        resource :passwords, only: [:new, :create], controller: "users/passwords"
        resources :api_tokens, only: [:new, :create, :edit, :update, :destroy], controller: "users/api_tokens"
      end

      namespace :census do
        resource :imports, only: [:new, :create]
      end

      resources :activities, only: [:index]

      namespace :gobierto_budgets do
        resources :options, only: [:index] do
          collection do
            put :update
            put :update_annual_data
          end
        end
        resources :feedback, only: [:index]
      end

      namespace :gobierto_people, as: :people, path: :people do
        resources :people, only: [:index, :new, :create, :edit, :update] do
          collection do
            resource :people_sort, only: [:create], controller: "people/people_sort", path: :people_sort
          end
          resources :person_events, only: [:new, :create, :edit, :update], controller: "people/person_events", as: :events, path: :events
          resources :person_statements, only: [:index, :new, :create, :edit, :update], controller: "people/person_statements", as: :statements, path: :statements
          resources :person_posts, only: [:index, :new, :create, :edit, :update], controller: "people/person_posts", as: :posts, path: :blog
        end

        namespace :configuration do
          resource :settings, only: [:edit, :update], path: :settings
        end

        resource :file_attachments, only: [:create]
      end

      namespace :gobierto_participation, as: :participation, path: :participation do
        get "/" => "welcome#index"

        resources :processes, only: [:index, :new, :edit, :create, :update, :destroy] do
          put :recover
          post :update_current_stage
          resources :process_stages, only: [:create, :destroy, :edit, :index, :new, :update], controller: "processes/process_stages", as: :process_stages, path: :process_stages do
            resources :pages, only: [:new, :create, :edit, :update], controller: "processes/process_stage_pages", as: :process_stage_page, path: :process_stage_page
            collection do
              resource :process_stage_sort, only: [:create], controller: "processes/process_stages_sort", path: :process_stages_sort
            end
          end
          resources :file_attachments, only: [:index], controller: "processes/process_file_attachments", as: :file_attachments, path: :file_attachments
          resources :events, only: [:index], controller: "processes/process_events", as: :events, path: :events
          resources :pages, only: [:index], controller: "processes/process_pages", as: :pages, path: :pages
          resources :polls, only: [:index, :new, :edit, :create, :update, :destroy], controller: "processes/polls" do
            resources :answers, only: [:index], controller: "processes/poll_answers"
            put :recover
          end
          resources :contribution_containers, only: [:new, :edit, :create, :update, :index, :show, :destroy], controller: "processes/process_contribution_containers", as: :contribution_containers, path: :contribution_containers do
            put :recover
          end
        end

        namespace :configuration do
          resource :settings, only: [:edit, :update], path: :settings
        end
      end

      namespace :gobierto_citizens_charters, as: :citizens_charters, path: :citizens_charters do
        get "/" => "services#index"

        resources :services do
          put :recover
        end
        resources :charters do
          resources :commitments, except: [:show], controller: "charters/commitments", as: :commitments, path: :commitments
          resources :editions, only: [:index], controller: "charters/editions", as: :editions, path: :editions
          resources :editions_intervals, controller: "charters/editions_intervals", as: :editions_intervals, path: :editions_intervals
          put :recover
        end
        namespace :configuration do
          resource :settings, only: [:edit, :update]
        end

        # API
        namespace :api do
          resources :charters, only: [] do
            resources :editions, except: [:show, :new, :edit]
            resources :commitments, only: [:index]
          end
        end
      end

      namespace :gobierto_common, as: :common, path: nil do
        resources :collections, only: [:show, :new, :create, :edit, :update]
        resources :content_blocks, only: [:new, :create, :edit, :update, :destroy]
        resources :vocabularies do
          resources :terms, shallow: true, controller: "ordered_terms", except: [:show] do
            collection do
              resource :terms_sort, only: [:create], controller: "ordered_terms_sort"
            end
          end
        end

        namespace :custom_fields do
          post "create_option", controller: "custom_fields"
          resources :module_resources, only: [:index, :show], param: :name do
            resources :instance_level_resources, only: [:index, :show]
            resources :custom_fields, shallow: true, except: [:show], path: "" do
              collection do
                resource :sort, only: [:create], controller: "sort"
              end
            end
          end
        end

        namespace :api do
          resources :vocabularies, only: [:show] do
            resources :terms, only: [:create]
          end
        end
      end

      namespace :gobierto_plans, as: :plans, path: :plans do
        resources :plans, except: [:show], path: "" do
          resources :categories do
            collection do
              get :accumulated_values
            end
          end

          resources :dashboards, only: [:index, :destroy] do
            collection do
              get :list
            end
          end

          resources :projects do
            member do
              post :publish
              post :unpublish
            end
          end
          get :import_csv
          get :export_csv, defaults: { format: "csv" }
          get :export_indicator_csv, defaults: { format: "csv" }
          delete :delete_contents
          put :recover
          patch :import_data
          patch :import_table_custom_fields
        end
        resources :plan_types, except: [:show], path: :plan_types do
          put :recover
        end
      end

      namespace :gobierto_cms, as: :cms, path: :cms do
        resources :pages, only: [:index, :new, :edit, :create, :update, :destroy] do
          put :recover
        end
        resources :sections, only: [:index, :new, :edit, :create, :update, :show] do
          resources :section_items, only: [:index, :create, :destroy, :update, :show]
          get :pages
        end
      end

      namespace :gobierto_attachments, as: :attachments, path: :attachments do
        resources :file_attachments, only: [:index, :create, :new, :edit, :update, :destroy] do
          put :recover
        end
        namespace :api do
          resources :attachments, only: [:index, :show, :create, :update, :destroy]
          post "/attachings" => "attachings#create"
          delete "/attachings" => "attachings#destroy"
        end
      end

      namespace :gobierto_calendars, as: :calendars do
        resources :events do
          put :recover
        end
        resources :collections, only: [:index]
        resources :calendar_configurations, only: [:edit, :update], controller: "calendar_configuration", as: :configurations, path: :configurations do
          member do
            put 'sync_calendars'
          end
        end
      end

      namespace :gobierto_investments, as: :investments do
        resources :projects
      end

      namespace :gobierto_data, as: :data do
        resources :datasets

        namespace :configuration do
          resource :settings, only: [:edit, :update], path: :settings
        end
      end

      namespace :gobierto_observatory, as: :observatory do
        namespace :configuration do
          resource :settings, only: [:edit, :update], path: :settings
        end
      end

      namespace :gobierto_visualizations, as: :visualizations do
        namespace :configuration do
          resource :settings, only: [:edit, :update], path: :settings
        end
      end

      namespace :gobierto_dashboards, as: :dashboards do
        get "/modal" => "dashboards#modal"
      end
    end

    # User module
    namespace :user do
      constraints GobiertoSiteConstraint.new do
        get "/" => "welcome#index", as: :root

        resource :sessions, only: [:new, :create, :destroy]
        resource :custom_session, only: [:new, :create, :destroy] do
          collection do
            post :auth_callback
          end
        end
        resource :registrations, only: [:create]
        resource :confirmations, only: [:new, :create]
        resource :passwords, only: [:create, :edit, :update]
        resource :census_verifications, only: [:new, :create], path: :verifications
        resource :settings, only: [:show, :update]
        resource :subscription_preferences, only: [:update]

        resources :subscriptions, only: [:index, :create, :destroy]
        resources :notifications, only: [:index]
      end
    end

    # Gobierto People module
    namespace :gobierto_people, path: "/" do
      constraints GobiertoSiteConstraint.new do
        localized do
          get "people_and_agendas", to: "welcome#index", as: :root

          # Agendas
          resources :person_events, only: [:index], as: :events, path: "agendas"
          resources :government_party_person_events, only: [:index], as: :government_party_events, path: "agendas/gobierno"
          resources :opposition_party_person_events, only: [:index], as: :opposition_party_events, path: "agendas/oposicion"
          resources :executive_category_person_events, only: [:index], as: :executive_category_events, path: "agendas/directivos"

          resources :past_person_events, only: [:index], as: :past_events, path: "agendas/eventos-pasados"
          resources :government_party_past_person_events, only: [:index], as: :government_party_past_events, path: "agendas/gobierno/eventos-pasados"
          resources :opposition_party_past_person_events, only: [:index], as: :opposition_party_past_events, path: "agendas/oposicion/eventos-pasados"
          resources :executive_category_past_person_events, only: [:index], as: :executive_category_past_events, path: "agendas/directivos/eventos-pasados"

          resources :people_past_person_events, only: [:index], controller: "people/past_person_events", as: :person_past_events, path: "agendas/:container_slug/eventos-pasados"
          resources :people_person_events, only: [:index, :show], controller: "people/person_events", as: :person_events, path: "agendas/:container_slug", param: :slug

          # Officials
          resources :people, only: [:index], path: :people

          resources :government_party_people, only: [:index], path: :people_government
          resources :opposition_party_people, only: [:index], path: :people_opposition
          resources :executive_category_people, only: [:index], path: :people_managers

          # Blogs
          resources :person_posts, only: [:index], as: :posts, path: :posts
          resources :person_post_tags, only: [:show], as: :post_tags, path: :post_tags

          resources :people_person_post_tags, only: [:show], controller: "people/person_post_tags", as: :person_post_tags, path: :person_post_tags
          resources :people_person_posts, only: [:index, :show], controller: "people/person_posts", as: :person_posts, path: :person_posts, param: :slug

          # Statements
          resources :person_statements, only: [:index], as: :statements, path: :statements
          resources :people_person_statements, only: [:index, :show], controller: "people/person_statements", as: :person_statements, path: :person_statements, param: :slug

          # Political Groups
          resources :political_group, only: [:show], path: :political_groups, param: :slug do
            resources :people, only: [:index], controller: "political_groups/people", path: "/"
          end

          # Departments
          resources :departments, only: [:index, :show], path: :departments
          resources :department_people, only: [:index], controller: "departments/people", path: :department_people

          # Interest groups
          resources :interest_groups, only: [:index, :show], path: :interest_groups

          # Gifts
          resources :person_gifts, only: [:index], as: :gifts, path: "obsequios-y-regalos"

          # Trips
          resources :person_trips, only: [:index], as: :trips, path: "viajes-y-desplazamientos"

          # Invitations
          resources :person_invitations, only: [:index], as: :invitations, path: "invitaciones"

          # People
          resources :people, only: [:show], path: :people, param: :slug do
            resource :person_bio, only: [:show], controller: "people/person_bio", as: :bio, path: :bio
            resources :gifts, only: [:index, :show], controller: "people/gifts", path: :gifts
            resources :trips, only: [:index, :show], controller: "people/trips", path: :trips
            resources :invitations, only: [:index, :show], controller: "people/invitations", path: :invitations
            resources :person_messages, only: [:create], controller: "people/person_messages", as: :messages, path: :messages, param: :slug do
              collection do
                get "/" => "people/person_messages#new", as: :new
              end
            end
          end
        end

        resources :people, only: [], path: "personas", param: :slug do
          resource :google_calendar_calendars, only: [:edit, :update], controller: "people/google_calendar/calendars", as: :google_calendar_calendars
        end

        # API
        namespace :api, path: "gobierto_people/api" do
          namespace :v1 do
            resources :interest_groups, only: :index
            resources :departments, only: :index
            resources :people, only: :index
          end
        end
      end

      # Google calendar integration hook
      resource :google_calendar_authorization, only: [:new], controller: "people/google_calendar/authorization", as: :google_calendar_authorization
    end

    # Gobierto Budgets module
    namespace :gobierto_budgets, path: "presupuestos" do
      constraints GobiertoSiteConstraint.new do
        root "sites#show"

        resources :featured_budget_lines, only: [:show]

        get "resumen(/:year)" => "budgets#index", as: :budgets
        get "partidas/:year/:area_name/:kind" => "budget_lines#index", as: :budget_lines
        get "partidas/:id/:year/:area_name/:kind" => "budget_lines#show", as: :budget_line
        get "budget_line_descendants/:year/:area_name/:kind" => "budget_line_descendants#index", as: :budget_line_descendants
        get "ejecucion(/:year)" => "budgets_execution#index", as: :budgets_execution
        get "guia" => "budgets#guide", as: :budgets_guide
        get "elaboracion" => "budgets_elaboration#index", as: :budgets_elaboration
        get "budgets/treemap(/:year)" => "budget_lines#treemap", as: :budget_lines_treemap

        get "all_categories/:year" => "search#all_categories", as: :search_all_categories

        get "feedback/step1" => "feedback#step1", as: :feedback_step1
        get "feedback/step2" => "feedback#step2", as: :feedback_step2
        get "feedback/step3" => "feedback#step3", as: :feedback_step3
        post "feedback/follow" => "feedback#follow", as: :feedback_follow
        get "feedback/load_ask_more_information" => "feedback#load_ask_more_information", as: :feedback_load_ask_more_information
        get "recibo" => "receipts#show", as: :receipt
        get "proveedores-facturas" => "providers#index", as: :providers
        get "indicadores(/:year)" => "indicators#index", as: :indicators

        namespace :api do
          get "/categories" => "categories#index"
          get "/categories/:area/:kind" => "categories#index"
          get "/data/available_years" => "data#available_years", as: :available_years
          get "/data/budget_lines/:area/*id" => "data#budget_line", as: :budget_line
          get "/data/widget/budget/:organization_id/:year/:code/:area/:kind" => "data#budget", as: :data_budget
          get "/data/widget/budget_per_inhabitant/:organization_id/:year/:code/:area/:kind" => "data#budget_per_inhabitant", as: :data_budget_per_inhabitant
          get "/data/lines/:organization_id/:year/:what" => "data#lines", as: :data_lines
          get "/data/lines/budget_line/:organization_id/:year/:what/:kind/:code/:area" => "data#lines", as: :data_lines_budget_line
          get "/data/widget/budget_execution_comparison/:organization_id/:year/:kind/:area" => "data#budget_execution_comparison", as: :data_budget_execution_comparison
        end
      end
    end

    # Gobierto Observatory module
    namespace :gobierto_observatory, path: "observatorio" do
      constraints GobiertoSiteConstraint.new do
        root "observatory#index"
        get "mapa" => "observatory#demography_map", as: :map
      end
    end

    # Gobierto Plans module
    namespace :gobierto_plans, path: "planes" do
      constraints GobiertoSiteConstraint.new do
        get "/" => "plan_types#index", as: :root
        get ":slug(/:year)/ods/:sdg_slug" => "plan_types#sdg", as: :plan_sdg
        get ":slug(/:year)" => "plan_types#show", as: :plan
        get ":slug(/:year)/categoria/:id" => "plan_types#show", as: :category
        get ":slug(/:year)/proyecto/:id" => "plan_types#show", as: :project
        get ":slug(/:year)/tabla/:uid" => "plan_types#show"
        get ":slug(/:year)/tabla/:uid/:term_id" => "plan_types#show"
        get ":slug(/:year)/dashboards(/:dashboard_id)" => "plan_types#show", as: :plan_dashboards

        # API
        namespace :api, path: "gobierto_plans/api" do
          get "plan_projects/:plan_id/:category_id" => "plan_projects#index", as: "plan_projects"
        end
      end
    end

    namespace :gobierto_plans, path: "/" do
      constraints GobiertoSiteConstraint.new do
        # API
        namespace :api, path: "/" do
          namespace :v1, constraints: ::ApiConstraint.new(version: 1, default: true), path: "/api/v1" do
            resources :plans, only: [:index, :show], defaults: { format: "json" } do
              member do
                get :meta
              end
              resources :projects, only: [:index]
            end
          end
        end
      end
    end

    # Gobierto Indicators module
    namespace :gobierto_indicators, path: "indicadores" do
      constraints GobiertoSiteConstraint.new do
        root "indicators#index"
        get "ita(/:year)" => "indicators#ita", as: :indicators_ita
        get "ip(/:year)" => "indicators#ip", as: :indicators_ip
        get "gci(/:year)" => "indicators#gci", as: :indicators_gci
      end
    end

    # Gobierto CMS module
    namespace :gobierto_cms, path: "" do
      constraints GobiertoSiteConstraint.new do
        get "/s/:slug_section/:id" => "pages#show",    as: :section_item
        get "/s/:slug_section"     => "sections#show", as: :section
        get "/paginas/:id"         => "pages#index",   as: :pages
        get "/pagina/:id"          => "pages#show",    as: :page
        get "/noticias/:id"        => "news#index",    as: :news_index
        get "/noticia/:id"         => "news#show",     as: :news
      end
    end

    # Gobierto Participation module
    namespace :gobierto_participation, path: "participacion" do
      constraints GobiertoSiteConstraint.new do
        get "/" => "welcome#index", as: :root

        resources :processes, only: [:index, :show], path: "p" do
          resources :contribution_containers, only: [:index, :show], controller: "processes/contribution_containers", path: "aportaciones" do
            resources :contributions, only: [:new, :create, :show], controller: "processes/contributions", path: :contributions do
              resource :vote, only: [:create, :destroy]
              resource :flag, only: [:create, :destroy]
              resource :comment, only: [:create, :index]
            end
          end

          resources :polls, only: [:index], controller: "processes/polls", path: "encuestas" do
            resources :answers, only: [:new, :create], controller: "processes/poll_answers"
          end
          resources :attachments, only: [:index], controller: "processes/attachments", path: "documentos"
          resources :past_process_events, only: [:index], controller: "processes/past_process_events", as: :past_process_events, path: "agendas/eventos-pasados"
          resources :events, only: [:index, :show], controller: "processes/events", path: "agendas"
          resources :news, only: [:index], controller: "processes/news", path: "noticias"
          resources :activities, only: [:index], controller: "processes/activities", path: "actividad"
        end

        resources :issues, only: [:index, :show], path: "temas" do
          resources :attachments, only: [:index], controller: "issues/attachments", path: "documentos"
          resources :events, only: [:index, :show], controller: "issues/events", path: "agendas"
          resources :activities, only: [:index], controller: "issues/activities", path: "actividad"
        end

        resources :scopes, only: [:index, :show], path: "ambitos" do
          resources :attachments, only: [:index], controller: "scopes/attachments", path: "documentos"
          resources :events, only: [:index, :show], controller: "scopes/events", path: "agendas"
          resources :activities, only: [:index], controller: "scopes/activities", path: "actividad"
        end

        resources :attachments, only: [:index], controller: "attachments", path: "documentos"
        resources :past_participation_events, only: [:index], controller: "past_participation_events", as: :past_participation_events, path: "agendas/eventos-pasados"
        resources :events, only: [:index, :show], controller: "events", path: "agendas"
        resources :news, only: [:index], controller: "news", path: "noticias"
        resources :activities, only: [:index], controller: "activities", path: "actividad"
      end
    end

    # Gobierto Exports module
    namespace :gobierto_exports, path: "descarga-datos" do
      constraints GobiertoSiteConstraint.new do
        root "exports#index"
      end
    end

    # Gobierto Attachments module
    namespace :gobierto_attachments, path: 'docs' do
      constraints GobiertoSiteConstraint.new do
        resources :attachments, only: [:show], path: ''
      end
    end

    namespace :gobierto_attachments, path: "" do
      constraints GobiertoSiteConstraint.new do
        get "/documento/:id" => 'attachment_documents#show', as: :document
      end
    end

    # Gobierto Citizens Charters module
    namespace :gobierto_citizens_charters, path: "cartas-de-servicios" do
      constraints GobiertoSiteConstraint.new do
        get "/" => "welcome#index", as: :root
        resources :services, only: [:index], param: :slug, path: "servicios" do
          get "cartas/:front_period_interval/:period" => "charters#index", as: :charters_period
          resources :charters, only: [:index], param: :slug, path: "cartas"
        end
        resources :charters, only: [:index, :show], param: :slug, path: "cartas" do
          member do
            get "detalles" => "charters#details", as: :details
            get ":front_period_interval/:period" => "charters#show", as: :charter_period
          end
        end
        get ":front_period_interval/:period" => "charters#index", as: :charters_period
      end
    end

    # Gobierto Investments module
    namespace :gobierto_investments, path: "/" do
      constraints GobiertoSiteConstraint.new do

        # Front
        get "inversiones" => "investments#index", as: :root
        get "inversiones/proyectos/:id" => "investments#index"
        get "inversiones/tour-virtual" => "investments#tour", as: :tour

        # API
        namespace :api, path: "/gobierto_investments/api" do
          namespace :v1, constraints: ::ApiConstraint.new(version: 1, default: true) do
            resources :projects, except: [:edit] do
              collection do
                get :meta
              end
            end
          end
        end
      end
    end

    # Gobierto Data module
    namespace :gobierto_data, path: "/" do
      constraints GobiertoSiteConstraint.new do
        get "/datos/" => "welcome#index", as: :root
        get "/datos/v/visualizaciones" => "welcome#index"
        get "/datos/:id" => "welcome#index", as: :datasets
        get "/datos/:id/resumen" => "welcome#index"
        get "/datos/:id/editor" => "welcome#index"
        get "/datos/:id/consultas" => "welcome#index"
        get "/datos/:id/q/(:queryId)" => "welcome#index"
        get "/datos/:id/visualizaciones" => "welcome#index"
        get "/datos/:id/v/(:queryId)" => "welcome#index"
        get "/datos/:id/descarga" => "welcome#index"
        get "/datos/:id/mapa" => "welcome#index"
        get "/datos/terms/(:vocabId)" => "welcome#index"

        # API
        namespace :api, path: "/" do
          namespace :v1, constraints: ::ApiConstraint.new(version: 1, default: true), path: "/api/v1/data" do
            get "data" => "query#index", as: :root, defaults: { format: "json" }
            resources :datasets, except: [:show], param: :slug, defaults: { format: "json" } do
              resource :favorite, only: [:create, :destroy]
              resources :favorites, only: [:index]
              collection do
                get :meta
              end
              member do
                get "meta" => "datasets#dataset_meta"
                get "stats" => "datasets#stats"
              end
            end
            resources :datasets, only: [:show], param: :slug, defaults: { format: "csv" } do
              member do
                get :download, format: true
              end
            end
            resources :queries, except: [:edit], defaults: { format: "json" } do
              resource :favorite, only: [:create, :destroy]
              resources :favorites, only: [:index]
              member do
                get :meta
                get :download, format: true
              end
            end
            resources :visualizations, except: [:edit], defaults: { format: "json" } do
              resource :favorite, only: [:create, :destroy]
              resources :favorites, only: [:index]
            end
          end
        end
      end
    end

    namespace :gobierto_visualizations, path: 'visualizaciones' do
      constraints GobiertoSiteConstraint.new do
        # Front
        get "contratos" => "visualizations#contracts", as: :contracts_summary
        get "contratos/adjudicaciones" => "visualizations#contracts", as: :contracts
        get "contratos/adjudicaciones/:id" => "visualizations#contracts"
        get "contratos/adjudicatario/:id" => "visualizations#contracts"

        get "subvenciones" => "visualizations#subsidies", as: :subsidies_summary
        get "subvenciones/subvenciones" => "visualizations#subsidies", as: :subsidies
        get "subvenciones/subvenciones/:id" => "visualizations#subsidies"

        get "costes/" => "visualizations#costs", as: :costs_summary
        get "costes/:year" => "visualizations#costs", as: :costs
        get "costes/:year/:id/" => "visualizations#costs"
        get "costes/:year/:id/:item" => "visualizations#costs"
      end
    end

    # Common API
    namespace :gobierto_common, path: "/" do
      constraints GobiertoSiteConstraint.new do
        namespace :api, path: "/" do
          namespace :v1, constraints: ::ApiConstraint.new(version: 1, default: true), path: "/api/v1" do
            get ":module_name/configuration" => "configuration#show", as: :configuration
            get "search" => "search#query", as: :search
          end
        end
      end
    end

    # Gobierto Dashboards module
    namespace :gobierto_dashboards, path: "dashboards" do
      constraints GobiertoSiteConstraint.new do
        get "/" => "welcome#index", as: :root
      end
    end

    # API
    namespace :gobierto_dashboards, path: "/" do
      constraints GobiertoSiteConstraint.new do
        namespace :api do
          namespace :v1, constraints: ::ApiConstraint.new(version: 1, default: true) do
            get "/dashboards" => "dashboards#index", as: :root
            get "dashboard_data" => "dashboards#dashboard_data"
            resources :dashboards, defaults: { format: "json" } do
              member do
                get :data, defaults: { format: "json" }
              end
            end
          end
        end
      end
    end

    # Add new modules before this line

    # Sidekiq Web UI
    mount Sidekiq::Web => "/sidekiq", as: :sidekiq_console
  end
end
