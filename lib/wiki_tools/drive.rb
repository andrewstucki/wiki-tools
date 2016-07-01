module WikiTools
  class Drive
    class RetryError < StandardError; end

    def initialize(authorization)
      @service = Google::Apis::DriveV3::DriveService.new.tap do |drive|
        drive.authorization = authorization
      end
    end

    def get_folder(id)
      folder = @service.get_file(id)
      return nil unless folder.mime_type == "application/vnd.google-apps.folder"
      Folder.new(@service, folder)
    end

    def get_file(id)
      file = @service.get_file(id)
      return nil unless file.mime_type != "application/vnd.google-apps.file"
      File.new(@service, file)
    end

    class Entity
      extend Forwardable

      def_delegators :@internal, :name, :id

      def initialize(service, internal)
        @internal = internal
        @service = service
      end

      def rename(to)
        new_file_obj = Google::Apis::DriveV3::File.new(name: to)
        with_retries do
          @internal = @service.update_file(@internal.id, new_file_obj)
        end
      end

      class << self
        def create(service, entity)
          if entity.mime_type == "application/vnd.google-apps.folder"
            Folder.new(service, entity)
          else
            File.new(service, entity)
          end
        end
      end

      protected

      def with_retries(n = 10, &block)
        raise RetryError.new("Failed after multiple attempts") if n == 0
        block.call if block_given?
      rescue Google::Apis::ClientError => e
        puts e
        sleep 0.5 # wait in case of needing to back off
        with_retries(n - 1, &block)
      end
    end

    class File < WikiTools::Drive::Entity; end
    class Folder < WikiTools::Drive::Entity
      def files
        with_retries do
          @service.list_files(q: "mimeType != 'application/vnd.google-apps.folder' and '#{@internal.id}' in parents").files.map { |file| Entity.create(@service, file) }
        end
      end

      def children
        with_retries do
          @service.list_files(q: "mimeType = 'application/vnd.google-apps.folder' and '#{@internal.id}' in parents").files.map { |file| Entity.create(@service, file) }
        end
      end

      def walk(&block) #depth first walk of the tree
        yield(self) if block_given?
        children.each {|child| child.walk(&block)}
      end
    end
  end
end
