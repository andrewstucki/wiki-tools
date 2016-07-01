# wiki-tools
Google Drive tools for wiki migration

# Requirements
- ruby
- bundler
 
# Installation
    git clone https://github.com/andrewstucki/wiki-tools.git && cd wiki-tools
    bundle install

# Usage
    wiki-tools [options] (command) [command params]
    example: ./bin/wiki-tools -i [MY_ISSUER] -e [MY_EMAIL] -s [MY_KEYFILE] -v rename [FOLDER_ID] Austin Aus
  
        -d, --dry-run                    Shows the output of what is about to happen
        -v, --verbose                    Verbose mode, shows more output
        -k, --key-file [STRING]          Sets the key-file to use when authenticating against Google Drive
        -s, --secret [STRING]            Sets the key-file secret to use when authenticating against Google Drive
        -i, --issuer [STRING]            Sets the token issuer to use when authenticating against Google Drive
        -e, --email [STRING]             Sets the email address to use when authenticating against Google Drive
        -h, --help                       Show help
