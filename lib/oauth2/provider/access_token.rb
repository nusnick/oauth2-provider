module OAuth2
  class Provider
    
    class AccessToken
      attr_reader :authorization
      
      def initialize(resource_owner = nil, scopes = [], access_token = nil)
        @resource_owner = resource_owner
        @scopes         = scopes
        @access_token   = access_token
        
        if hash = OAuth2.hashify(access_token)
          @authorization  = Model::Authorization.find_by_access_token_hash(hash)
        end
        
        validate!
      end
      
      def client
        valid? ? @authorization.client : nil
      end
      
      def owner
        valid? ? @authorization.owner : nil
      end
      
      def response_headers
        return {} if valid?
        error_message =  "OAuth realm='#{ OAuth2.realm }'"
        error_message << ", error='#{ @error }'" unless @error == ''
        {'WWW-Authenticate' => error_message}
      end
      
      def response_status
        case @error
          when INVALID_TOKEN, EXPIRED_TOKEN then 401
          when INSUFFICIENT_SCOPE then 403
          when '' then 401
          else 200
        end
      end
      
      def valid?
        @error.nil?
      end
      
    private
      
      def validate!
        return @error = ''                 unless @access_token
        return @error = INVALID_TOKEN      unless @authorization
        return @error = EXPIRED_TOKEN      if @authorization.expired?
        return @error = INSUFFICIENT_SCOPE unless @authorization.in_scope?(@scopes)
        
        if @resource_owner and @authorization.owner != @resource_owner
          @error = INSUFFICIENT_SCOPE
        end
      end
    end
    
  end
end
