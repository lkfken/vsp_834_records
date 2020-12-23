module VSP
  class Filename
    attr_reader :production

    def initialize(production: false)
      @production = production
    end

    def to_s
      [(production ? 'a' : 't'), VSP::MEDIA_ID, '.edi'].join
    end
  end
end