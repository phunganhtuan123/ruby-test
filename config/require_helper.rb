module RequireHelper
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def workers(dir = nil, recursive: true)
      loader('app/workers', dir, recursive: recursive)
    end

    def controllers(dir = nil, recursive: true)
      loader('app/controllers', dir, recursive: recursive)
    end

    def services(dir = nil, recursive: true)
      loader('app/services', dir, recursive: recursive)
    end

    def modules(dir = nil, recursive: true)
      loader('app', dir, recursive: recursive)
    end

    def libraries(dir = nil, recursive: true)
      loader('libraries', dir, recursive: recursive)
    end

    def config(dir = nil, recursive: true)
      loader('config', dir, recursive: recursive)
    end

    def loader(main_dir, dir = nil, recursive: true)
      dir = dir + '/' if dir.present?

      files =
        if recursive
          Dir["#{ROOT_PATH}/#{main_dir}/#{dir}**/*.rb"]
        else
          Dir["#{ROOT_PATH}/#{main_dir}/#{dir}*.rb"]
        end

      files.each { |file| require file }
    end
  end

  class RequireDir
    extend ClassMethods
  end

  class RequireFile
    class << self
      def file(file_path)
        require "#{ROOT_PATH}/#{file_path}.rb"
      end
    end
  end
end
