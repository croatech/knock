require_dependency "knock/application_controller"

module Knock
  class AuthTokenController < ApplicationController
    before_action :authenticate

    def create(params, entity_name = nil)
      @params = params.require(:auth).permit(:email, :password)
      @entity_name = entity_name || 'User'

      auth_token.token
    end

    private

    attr_reader :params, :entity_name

    def authenticate
      unless entity.present? && entity.authenticate(params[:password])
        raise Knock.not_found_exception_class
      end
    end

    def auth_token
      if entity.respond_to? :to_token_payload
        AuthToken.new payload: entity.to_token_payload
      else
        AuthToken.new payload: { sub: entity.id }
      end
    end

    def entity
      @entity ||=
        if entity_class.respond_to? :from_token_request
          entity_class.from_token_request request
        else
          entity_class.find_by email: params[:email]
        end
    end

    def entity_class
      entity_name.constantize
    end
  end
end
