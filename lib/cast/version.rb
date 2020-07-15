module C
  VERSION = [0, 3, 1]

  class << VERSION
    include Comparable

    def to_s
      join('.')
    end
  end
end
