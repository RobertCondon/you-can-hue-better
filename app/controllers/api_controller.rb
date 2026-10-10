class ApiController < ApplicationController
  include JsonErrors

  private

  def require_bridge
    render json: { error: I18n.t("api.no_bridge") }, status: :service_unavailable unless Hue.configured?
  end
end
