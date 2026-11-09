module Html
  class LocalButtonsController < ApplicationController
    def index
      @buttons = LocalButton.arranged.includes(rules: %i[if_subject target scene])
      @choices = ButtonRules::Choices.call
    end
  end
end
