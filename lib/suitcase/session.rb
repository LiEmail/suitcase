module Suitcase
  # Public: A small wrapper around the concept of a user session. Cam be passed
  #         around through many of the EAN API methods to neaerly automatically
  #         manage user sessions.
  class Session
    attr_accessor :ean_id, :ip, :user_agent

    # Public: Create a new Session.
    #
    # info - Hash of user information:
    #         :ean_id     - String. Session ID provided to the user on the first
    #                       request on their behalf.
    #         :ip         - The IP address of the user (default: nil).
    #         :user_agent - String. The user agent of the user.
    def initialize(info = {})
      @ean_id, @ip, @user_agent = info[:ean_id], info[:ip], info[:user_agent]
    end
  end
end

