module Warden
  module Facebook
    class Strategy < Warden::Strategies::Base
      def params
        @params ||= Rack::Utils.parse_query(request.query_string)
      end

      def authenticate!
        if params['facebook_id'].present?
          success! user_by_facebook_id
        elsif params['token']
          success! user_by_facebook_token
        else
          throw(:halt, [302, { 'Location' => authorize_url }, []])
        end
      end

      private

      def user_by_facebook_id
        user = Backend::App::Users.by_parameters(facebook_id: params['facebook_id'], status: %w[active unconfirmed], limit: 1)
        if user.blank?
          user = Backend::App::Users.create_empty
          user.just_created = true
          user.auth_system = 'facebook'
          user.status = 'active'
          user.auth_facebook_id = params['facebook_id']
          user.auth_facebook_token = params['token']
          user.save(es_sync: false)
          #### Save to cached file....
          Backend::App::SocialTokens.write_cache_new_facebook_user(user)
        end
        user
      end

      def user_by_facebook_token
        access_token = init_access_token(params['token'])

        raise 'Failed to get a valid Facebook AccessToken' unless access_token.is_a?(OAuth2::AccessToken)

        tries = 3

        begin
          data = access_token.get('/me?fields=first_name,last_name,birthday,email,gender').parsed
        rescue Exception
          # reduce tries counter
          tries -= 1
          # check for left retires
          if tries > 0
            # wait 3 seconds
            sleep(3)
            # retry but
            retry
          else
            # raise error
            raise CustomError.new(
              status: 403,
              message: 'Kết nối mạng có vấn đề, vui lòng thử lại sau.'
            )
          end
        end

        make_user(data, access_token)
      end

      ##
      # returns a new created user or the existing one which could be found by facebook user id
      def make_user(data, token)
        # get facebook user by warden
        fb_user = Warden::Facebook::User.new(data, token)

        # try loading a trendu user by facebook id
        local_user = Backend::App::Users.by_parameters(facebook_id: fb_user.id, status: %w[active unconfirmed], limit: 1)

        # if this facebook user is already known
        if local_user.is_a?(Backend::App::User)
          # Save to cached file if social_token not exist
          social_token = Backend::App::SocialTokens.by_parameters(social_id: local_user.auth_facebook_id)
          Backend::App::SocialTokens.write_cache_new_facebook_user(local_user) if social_token.nil?

          # update fb token
          local_user.auth_facebook_token = fb_user.token

          # update fb friends
          local_user.facebook_friends = fb_user.friends

          # save user
          local_user.save

          return local_user
          # end
        end

        begin
          # create user and return
          new_user = Backend::App::Users.create_from_facebook(fb_user)

          #### Save to cached file....
          Backend::App::SocialTokens.write_cache_new_facebook_user(new_user)
        end
      end

      def oauth_client
        oauth_proxy.client
      end

      def authorize_url
        oauth_proxy.authorize_url
      end

      def access_token_for(code)
        oauth_proxy.access_token_for(code)
      end

      # @option opts [String] :refresh_token (nil) the refresh_token value
      # @option opts [Integer, String] :expires_in (nil) the number of seconds in which the AccessToken will expire
      # @option opts [Integer, String] :expires_at (nil) the epoch time in seconds in which AccessToken will expire
      # @option opts [Symbol] :mode (:header) the transmission mode of the Access Token parameter value
      #    one of :header, :body or :query
      # @option opts [String] :header_format ('Bearer %s') the string format to use for the Authorization header
      # @option opts [String] :param_name ('access_token') the parameter name to use for transmission of the
      #    Access Token value in :body or :query transmission mode
      def init_access_token(token, opts = {})
        OAuth2::AccessToken.new(oauth_client, token.to_s, opts)
      end

      def oauth_proxy
        state = env['rack.session'][:oauth_state] = ''.object_id
        @oauth_proxy ||= Warden::Facebook::Proxy.new(
          env['warden'].config[:facebook_app_id],
          env['warden'].config[:facebook_app_secret],
          env['warden'].config[:facebook_scopes],
          callback_url, state
        )
      end

      def callback_url
        absolute_url(request, env['warden'].config[:facebook_callback_url])
      end

      def absolute_url(request, suffix = nil)
        port_part = case request.scheme
                    when 'http'
                      request.port == 80 ? '' : ":#{request.port}"
                    when 'https'
                      request.port == 443 ? '' : ":#{request.port}"
                    end
        "#{request.scheme}://#{request.host}#{port_part}#{suffix}"
      end
    end
  end
end

Warden::Strategies.add(:facebook, Warden::Facebook::Strategy)
