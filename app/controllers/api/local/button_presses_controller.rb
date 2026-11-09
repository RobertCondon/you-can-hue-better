module Api
  module Local
    class ButtonPressesController < MachineController
      def create
        gesture = params.fetch(:gesture, ButtonRule::SINGLE)
        raise ActionController::ParameterMissing, :gesture unless gesture.in?(ButtonRule::GESTURES)

        press = LocalButtons::Press.call(client: machine_client, key: params.require(:button_id), gesture:)
        render json: { button_id: press.button.key, gesture:, rule_id: press.rule&.id }, status: :accepted
      end
    end
  end
end
