module Html
  class LocalButtonsController < ApplicationController
    def index
      @buttons = LocalButton.arranged.includes(rules: %i[if_group target_group scene])
      @choices = ButtonRule::Choices.load
    end
  end
end
