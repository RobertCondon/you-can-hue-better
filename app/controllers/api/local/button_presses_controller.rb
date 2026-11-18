module Api
  module Local
    class ButtonPressesController < MachineController
      def create
        kind = params.fetch(:kind, LocalButton::BUTTON)
        gesture = params.fetch(:gesture, ButtonRule::SINGLE)
        raise ActionController::ParameterMissing, :gesture unless LocalButton.gesture?(kind, gesture)

        press = LocalButtons::Press.call(client: machine_client, key: params.require(:button_id), kind:, gesture:)
        render json: { button_id: press.button.key, kind:, gesture:, rule_id: press.rule&.id }, status: :accepted
      end
    end
  end
end
