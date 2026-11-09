class ButtonRulesController < ApiController
  FIELDS = %i[if_subject if_state action target scene_id brightness].freeze

  def create
    button = LocalButton.find(params[:local_button_id])
    rule = button.rules.create!(ButtonRules::Starter.call(button, params.require(:button_rule).require(:gesture)))
    changed(button)
    render json: rule, status: :created
  end

  def update
    rule = ButtonRule.find(params[:id])
    rule.update!(ButtonRules::Fields.call(params.require(:button_rule).permit(*FIELDS)))
    changed(rule.local_button)
    render json: rule
  end

  def move
    direction = params.require(:direction)
    raise ActionController::ParameterMissing, :direction unless direction.in?(ButtonRule::DIRECTIONS)

    rule = ButtonRule.find(params[:id])
    ButtonRules::Move.call(rule, direction)
    changed(rule.local_button)
    head :no_content
  end

  def destroy
    rule = ButtonRule.find(params[:id])
    rule.destroy!
    changed(rule.local_button)
    head :no_content
  end

  private

  def changed(button) = LocalButtons::Broadcast.call(button.reload)
end
