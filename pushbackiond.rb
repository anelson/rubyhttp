require 'rfuzz/pushbackio'

### A specialization of PushBackIO without that bullshit random socket death crap
class PushBackIoNd < RFuzz::PushBackIO
    def initialize(secondary)
        super(secondary)
    end

    def random_death
    end
end
