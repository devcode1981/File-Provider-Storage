# frozen_string_literal: true

require 'spec_helper'

describe GDK::Diagnostic::RubyGems do
  describe '#diagnose' do
    it 'is a no-op' do
      expect(subject.diagnose).to be_nil
    end
  end

  describe '#success?' do
    context 'when ffi can not be loaded' do
      it 'returns false' do
        allow_any_instance_of(described_class).to receive(:require).with('ffi').and_raise(LoadError, 'failed to load')

        expect(subject.success?).to be_falsy
      end
    end

    context 'when ffi is loaded correctly' do
      it 'returns true' do
        allow_any_instance_of(described_class).to receive(:require).with('ffi').and_return(true)

        expect(subject.success?).to be_truthy
      end
    end
  end

  describe '#detail' do
    context 'when ffi cannot be loaded' do
      it 'returns a message' do
        allow_any_instance_of(described_class).to receive(:require).with('ffi').and_raise(LoadError, 'failed to load')

        expect(subject.detail).to match(/gem pristine ffi/)
      end
    end

    context 'when ffi is loaded correctly' do
      it 'returns no message' do
        allow_any_instance_of(described_class).to receive(:require).with('ffi').and_return(true)

        expect(subject.detail).to be_nil
      end
    end
  end
end
