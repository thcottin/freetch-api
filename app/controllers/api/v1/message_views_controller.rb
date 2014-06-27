class API::V1::MessageViewsController < ApplicationController

  def index
    # identify message to display on view from received parameter
    @messages = MessageView.all
    result = {}
    @messages.map { |message| result[message.ref] = message.message }
    render json: result
  end

end
