module WikiTools
  class Client
    attr_reader :key, :issuer, :email, :practice, :verbose
    def initialize(key, issuer, email, verbose, practice = false)
      @key = key
      @issuer = issuer
      @email = email
      @verbose = verbose
      @practice = practice
    end

    def rename_tree_recursive(folder, primary_match, other_matches = [])
      all_matches = other_matches + [ primary_match ]
      drive_service.get_folder(folder).walk do |folder|
        puts "Checking #{folder.name} (#{folder.id})"

        #CHANGE ME?
        desired_files = folder.files + folder.children

        matches = desired_files.select do |file|
          !all_matches.any? {|match| file.name.include? match}
        end
        matches.each do |match|
          new_name = "#{primary_match} #{match.name}"
          puts "Renaming '#{match.name}' --> '#{new_name}'" if verbose || practice
          match.rename(new_name) unless practice
        end
      end
    rescue WikiTools::Drive::RetryError => e
      puts "Failed to walk the entire tree"
    end

    private

    def drive_service
      @drive_service ||= WikiTools::Drive.new(authorization)
    end

    def authorization
      @authorization ||= Signet::OAuth2::Client.new(
        token_credential_uri: 'https://accounts.google.com/o/oauth2/token',
        audience:             'https://accounts.google.com/o/oauth2/token',
        scope:                'https://spreadsheets.google.com/feeds/ https://docs.google.com/feeds/ https://www.googleapis.com/auth/drive https://docs.googleusercontent.com/',
        issuer:               issuer,
        access_type:          'offline',
        signing_key:          key,
        person:               email
      )
    end
  end
end
