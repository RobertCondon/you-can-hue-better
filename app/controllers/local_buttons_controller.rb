class LocalButtonsController < ApiController
  def update
    button = LocalButton.find(params[:id])
    button.update!(params.require(:local_button).permit(:name))
    LocalButtons::Broadcast.call(button)
    render json: button.as_json(only: %i[id client key name])
  end

  # The button comes back, unnamed and with no rules, the next time it's pressed.
  def destroy
    button = LocalButton.find(params[:id])
    button.destroy!
    LocalButtons::Broadcast.call(button, LocalButtons::Broadcast::REMOVED)
    head :no_content
  end
end
