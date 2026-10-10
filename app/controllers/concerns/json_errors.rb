module JsonErrors
  extend ActiveSupport::Concern

  included do
    rescue_from Hue::Error, with: :bridge_failed
    rescue_from ActiveRecord::RecordNotFound, with: :not_found
    rescue_from ActiveRecord::RecordInvalid, with: :invalid_record
    rescue_from ActionController::ParameterMissing, HouseCommands::NothingToSend, with: :unprocessable
    rescue_from HouseCommands::LightsBusy, with: :lights_busy
  end

  private

  def bridge_failed(error) = render_error(error.message, :bad_gateway)

  def not_found(error) = render_error(error.message, :not_found)

  def unprocessable(error) = render_error(error.message, :unprocessable_entity)

  def invalid_record(error)
    render json: { error: error.record.errors.full_messages.to_sentence, errors: error.record.errors.to_hash }, status: :unprocessable_entity
  end

  def lights_busy(error)
    render json: { error: Toasts.lights_busy(error.busy.target_name), light_ids: error.busy.light_ids }, status: :conflict
  end

  def render_error(message, status) = render(json: { error: message }, status:)
end
