module Warden
	module Facebook
		class User
			attr_reader :token

			# ?fields=id,picture,first_name,last_name,name,birthday,email
			def initialize(data, token)
				@data, @token = data, token
			end

			def id
				@data['id']
			end

			def email
				@data['email']
			end

			def gender
				(@data['gender'] == 'male' ? 'male' : 'female')
			end
			
			def first_name
				@data['first_name']
			end

			def last_name
				@data['last_name']
			end

			def birthday
				return nil unless @data['birthday']

				# facebook returns 'month/day/year' but we need 'year-month-day'
				@data['birthday'].to_s.gsub(%r{^(\d{1,2})[-/](\d{1,2})[-/](\d{4})$}, '\3-\1-\2')
			end

			def friends
				nil
				# return @token.get('/me/friends?fields=name,gender').parsed
			end

			def crontab_friends
				return @token.get('/me/friends?fields=name,gender').parsed
			end

			def token
				return @token.token
			end
		end
	end
end
