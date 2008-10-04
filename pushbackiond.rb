require 'rfuzz/pushbackio'

$io_death_count = 0

### A specialization of PushBackIO without that bullshit random socket death crap
class PushBackIoNd < RFuzz::PushBackIO
    def initialize(secondary)
        super(secondary)
    end

    def random_death
    end
end
