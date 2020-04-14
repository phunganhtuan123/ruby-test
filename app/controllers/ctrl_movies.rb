module Backend
  class App
    class PaymentController < BaseController
      ####
      ##Danh sách phim
      get '' do
        resource = []
        (1..10).to_a.each do |m|
          resource << {
            id: m,
            title: "video - #{m}",
            description: "Based on the bestselling comic book, Vin Diesel stars as Ray Garrison, a soldier recently killed in action and brought back to life as the superhero Bloodshot by the RST corporation. With an army of nanotechnology in his veins, he's an unstoppable force -- stronger than ever and able to heal instantly. But in controlling his body, the company has sway over his mind and memories, too. Now, Ray doesn't know what's real and what's not -- but he's on a mission to find out.",
            start_date: Time.now,
            end_date: Time.now
          }
        end

        resp(status: 200, message: 'success', resource: resource)
      end
      ###
      #lấy thông tin phim
      get '/:id' do
        id = params[:id]
        resource = {
          id: id,
          title: "video - #{id}",
          description: "Based on the bestselling comic book, Vin Diesel stars as Ray Garrison, a soldier recently killed in action and brought back to life as the superhero Bloodshot by the RST corporation. With an army of nanotechnology in his veins, he's an unstoppable force -- stronger than ever and able to heal instantly. But in controlling his body, the company has sway over his mind and memories, too. Now, Ray doesn't know what's real and what's not -- but he's on a mission to find out.",
          start_date: Time.now,
          end_date: Time.now
        }

        resp(status: 200, message: 'success', resource: resource)
      end
    end
  end
end
