module C
  VERSION = [0, 3, 0]

  class << VERSION
    include Comparable

    def to_s
      join('.')
    end
  end
end
