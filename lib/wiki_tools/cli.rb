require 'singleton'
require 'optparse'

require 'wiki_tools'

module WikiTools
  class CLI
    include Singleton

    DEFAULTS = {
      dry_run: false,
      key_file: "./client.p12",
      secret: "notasecret",
      issuer: "fakeissuer",
      email: "fakemail",
      verbose: false
    }

    def parse(args=ARGV)
      @code = nil
      @options ||= DEFAULTS.merge(parse_options(args))
    end
    attr_reader :options

    def run!
      command = ARGV[0]
      unless respond_to?("run_#{command}")
        puts "Invalid command\n\n", @parser.help
        exit 1
      end
      remaining = ARGV.drop(1)
      arg_length = method("run_#{command}").arity
      inverse_length = (arg_length.abs - 1)
      unless arg_length == remaining.length || (inverse_length <= remaining.length)
        puts "The command '#{command}' takes #{arg_length > 0 ? arg_length : inverse_length.to_s + "+"} arguments, #{remaining.length} provided"
        exit 1
      end
      send("run_#{command}", *remaining)
    end

    def run_rename(folder, primary_match, *other_matches)
      client.rename_tree_recursive(folder, primary_match, other_matches)
    end

    private

    def client
      @client ||= begin
        puts "Invalid key file" and exit 1 unless File.exist?(options[:key_file])
        key = Google::APIClient::KeyUtils.load_from_pkcs12(options[:key_file], options[:secret])
        WikiTools::Client.new(key, options[:issuer], options[:email], options[:verbose], options[:dry_run])
      end
    end

    def parse_options(argv)
      opts = {}

      @parser = OptionParser.new do |o|
        o.on '-d', '--dry-run', "Shows the output of what is about to happen" do
          opts[:dry_run] = true
        end
        o.on '-v', '--verbose', "Verbose mode, shows more output" do
          opts[:verbose] = false
        end
        o.on '-k', '--key-file [STRING]', "Sets the key-file to use when authenticating against Google Drive" do |arg|
          opts[:key_file] = arg
        end
        o.on '-s', '--secret [STRING]', "Sets the key-file secret to use when authenticating against Google Drive" do |arg|
          opts[:secret] = arg
        end
        o.on '-i', '--issuer [STRING]', "Sets the token issuer to use when authenticating against Google Drive" do |arg|
          opts[:issuer] = arg
        end
        o.on '-e', '--email [STRING]', "Sets the email address to use when authenticating against Google Drive" do |arg|
          opts[:email] = arg
        end
      end

      @parser.banner = <<-EOF
wiki-tools [options] (command) [command params]
example: ./bin/wiki-tools -i [MY_ISSUER] -e [MY_EMAIL] -s [MY_KEYFILE] -v rename [FOLDER_ID] Austin Aus

      EOF
      @parser.on_tail "-h", "--help", "Show help" do
        puts @parser
        exit 1
      end
      @parser.parse!(argv)

      opts
    end
  end
end
