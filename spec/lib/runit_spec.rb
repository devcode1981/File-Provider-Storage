require 'spec_helper'

describe Runit do
  describe '.enabled?' do
    context 'when no environment variable is set' do
      before { allow(ENV).to receive(:[]).and_return(nil) }

      it 'is enabled' do
        expect(Runit).not_to be_enabled
      end
    end

    context 'when GDK_RUNIT is set to 1' do
      before { allow(ENV).to receive(:[]).and_return("1") }

      it 'is not enabled' do
        expect(Runit).to be_enabled
      end
    end
  end
end
