#! /usr/bin/env ruby
require 'spec_helper'
require 'puppet/application/type'

describe Puppet::Application::Type do
  it "should be a subclass of Puppet::Application::FaceBase" do
    expect(Puppet::Application::Type.superclass).to equal(Puppet::Application::FaceBase)
  end
end
