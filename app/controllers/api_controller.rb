class ApiController < ApplicationController
  include JsonErrors

  before_action :require_bridge

  private

  def require_bridge
    render json: { error: I18n.t("api.no_bridge") }, status: :service_unavailable unless Hue.configured?
  end
end
