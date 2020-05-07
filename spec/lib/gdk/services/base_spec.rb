# frozen_string_literal: true

require 'spec_helper'

describe GDK::Services::Base do
  describe '#name' do
    it 'needs to be implemented' do
      expect { subject.name }.to raise_error(NotImplementedError)
    end
  end

  describe '#command' do
    it 'needs to be implemented' do
      expect { subject.command }.to raise_error(NotImplementedError)
    end
  end

  describe '#enabled?' do
    it 'is disabled by default' do
      expect(subject.enabled?).to be(false)
    end
  end
end
