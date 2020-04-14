module Warden
	module Facebook
		class Proxy
			attr_accessor :client_id, :secret, :scopes, :callback_url, :state

			def initialize(app_id, app_secret, scopes, callback_url, state)
				@app_id, @app_secret, @scopes, @callback_url, @state = app_id, app_secret, scopes, callback_url, state
			end

			def client
				@client ||= OAuth2::Client.new(
					@app_id, @app_secret,
					{:site => 'https://graph.facebook.com', :token_url => "/oauth/access_token"}
				)
			end

			def access_token_for(code)
				client.get_token({
					:parse => :query,
					:code => code,
					:client_id => @app_id,
					:client_secret => @app_secret,
					:redirect_uri => @callback_url
				})
			end

			def authorize_url
				client.authorize_url(
					:client_id => @app_id,
					:redirect_uri => @callback_url,
					:scope => @scopes,
					:state => @state,
					:response_type => 'code'
				)
				# if successfull, this will redirect to
				#   REDIRECT_URI?code=OAUTH_CODE_GENERATED_BY_FACEBOOK&state=YOUR_STATE_VALUE
				# if it fails, it'll redirect to
				#   REDIRECT_URI?error_reason=user_denied&error=access_denied&error_description=The+user+denied+your+request.&state=YOUR_STATE_VALUE
			end

		end
	end
end
