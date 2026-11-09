class MachineController < ActionController::API
  include JsonErrors

  before_action :authenticate_machine!

  private

  attr_reader :machine_client

  def authenticate_machine!
    token = request.authorization.to_s[/\ABearer (.+)\z/, 1]
    @machine_client = MachineToken.verify!(token.to_s)
  rescue MachineToken::Invalid
    render json: { error: I18n.t("api.unauthorized") }, status: :unauthorized
  end
end
