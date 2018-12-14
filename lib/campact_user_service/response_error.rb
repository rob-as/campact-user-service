module CampactUserService
  class ResponseError < StandardError
    attr_reader :status_code, :body

    def initialize(status_code, body)
      @status_code = status_code
      @body = body
    end
  end
end
