module Backend
  class App
    class BookTickController < BaseController

      get '/theathers' do
        resource = []
        (1..10).to_a.each do |m|
          resource << {
            id: m,
            title: "rạp - #{m}",
            description: 'giơi thiệu rạp cgv',
          }
        end
        resp(status: 200, message: 'success', resource: resource)
      end

      get '/theathers/:id' do
        movies = []
        resource = []
        (1..5).to_a.each do |m|
          movies << {
            id: m,
            title: "video - #{m}",
            description: "Based on the bestselling comic book, Vin Diesel stars as Ray Garrison, a soldier recently killed in action and brought back to life as the superhero Bloodshot by the RST corporation. With an army of nanotechnology in his veins, he's an unstoppable force -- stronger than ever and able to heal instantly. But in controlling his body, the company has sway over his mind and memories, too. Now, Ray doesn't know what's real and what's not -- but he's on a mission to find out.",
            start_date: Time.now,
            end_date: Time.now
          }
        end

        (1..10).to_a.each do |m|
          resource << {
            id: m,
            title: "rạp - #{m}",
            description: 'giơi thiệu rạp cgv',
            movies: movies
          }
        end
        resp(status: 200, message: 'success', resource: resource)
      end

      get '/theathers/:id/rooms' do
        rooms = []
        resource = []
        (1..5).to_a.each do |m|
          rooms << {
            id: m,
            title: "room - #{m}",
            description: '',
            start_date: Time.now,
            end_date: Time.now
          }
        end

        (1..10).to_a.each do |m|
          resource << {
            id: m,
            title: "rạp - #{m}",
            rooms: rooms
          }
        end
        resp(status: 200, message: 'success', resource: resource)
      end

      get '/room/:id/seats' do
        seats = []
        (1..30).to_a.each do |m|
          seats << {
            id: m,
            title: "seats - #{m}",
            description: '',
            price: 70_000
          }
        end

        resource = {
          id: 1,
          title: "rạp - 1",
          seats: seats
        }

        resp(status: 200, message: 'success', resource: resource)
      end

      post '/book_tick' do
        customer = params[:customer]

        seat_id = params[:seat_id]
        room_id = params[:room_id]

        resp(status: 403, message: 'Chưa nhập thông tin khách', resource: nil) if customer.nil?

        resp(status: 403, message: 'Chưa chọn phòng', resource: nil) if room_id.nil?

        resp(status: 403, message: 'Chưa chọn ghế', resource: nil) if seat_id.nil?

        begin
          ###
          p 'Lưu thông tin booking'
        rescue Exception => e
          resp(status: 403, message: 'Đã có lỗi xảy ra', resource: nil)
        end

        resource = {
          customer: customer,
          book_id: 1,
          seat_id: seat_id,
          room_id: room_id,
          price: 70_000,
          stastus: 'unconfirm'
        }

        resp(status: 200, message: 'success', resource: resource)
      end

      get '/book_tick/:id' do
        begin
          ###
          p 'Lưu thông tin booking'
        rescue Exception => e
          resp(status: 403, message: 'Đã có lỗi xảy ra', resource: nil)
        end

        resource = {
          customer: 'khách 2',
          book_id: 1,
          seat_id: 1,
          room_id: 1,
          price: 70_000,
          status_name: 'Chờ xử lý',
          stastus: 'unconfirm'
        }

        resp(status: 200, message: 'success', resource: resource)
      end

      post '/payment' do
        book_id = params[:book_id]

        resp(status: 403, message: 'Chưa nhập thông tin book tick', resource: nil) if book_id.nil?

        begin
          ### Call api tạo bên onpay
          ### thay đổi trạng thái book
          ### lưu thông tin trastion bên onpay
        rescue Exception => e
          resp(status: 403, message: 'Đã có lỗi xảy ra', resource: nil)
        end

        resource = {
          transaction_id: 1,
          customer: 'khách 2',
          book_id: 1,
          seat_id: 1,
          room_id: 1,
          price: 70_000,
          status_name: 'Chờ thanh toán',
          stastus: 'pending'
        }

        resp(status: 200, message: 'success', resource: resource)
      end

      post '/callback/onpay' do
        transaction_id = params[:transaction_id]

        resp(status: 403, message: 'Đã có lỗi xảy ra', resource: nil) if transaction_id.nil?

        begin
          ### kiêm tra thông tin trastion onpay trả về
          ### thay đổi trạng thái book thánh toán hay không thanh công dự trên callback onpay
          ### lưu thông tin trastion bên onpay
        rescue Exception => e
          resp(status: 403, message: 'Đã có lỗi xảy ra', resource: nil)
        end

        resource = {
          transaction_id: transaction_id,
          customer: 'khách 2',
          book_id: 1,
          seat_id: 1,
          room_id: 1,
          price: 70_000,
          status_name: 'Đã thanh toán',
          stastus: 'payment'
        }

        resp(status: 200, message: 'success', resource: resource)
      end
    end
  end
end
