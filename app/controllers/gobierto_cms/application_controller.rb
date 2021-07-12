module GobiertoCms
  class ApplicationController < ::ApplicationController
    include User::SessionHelper
    include ::PreviewTokenHelper

    layout "gobierto_cms/layouts/application"

  end
end
