class ButtonRulesController < ApiController
  FIELDS = %i[if_group_id if_state action target_group_id scene_id].freeze

  def create
    button = LocalButton.find(params[:local_button_id])
    rule = button.rules.create!(ButtonRule.starter(button, params.require(:button_rule).require(:gesture)))
    changed(button)
    render json: rule, status: :created
  end

  def update
    rule = ButtonRule.find(params[:id])
    rule.update!(params.require(:button_rule).permit(*FIELDS))
    changed(rule.local_button)
    render json: rule
  end

  def move
    direction = params.require(:direction)
    raise ActionController::ParameterMissing, :direction unless direction.in?(ButtonRule::DIRECTIONS)

    rule = ButtonRule.find(params[:id])
    rule.move!(direction)
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
